import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../domain/reauth_session.dart';
import '../../domain/security_event.dart';
import '../../domain/sensitive_action.dart';
import '../controllers/security_providers.dart';
import 'pattern_lock_view.dart';

enum _ReauthMethodTab {
  biometric,
  pattern,
  password,
}

class ReauthDialog extends ConsumerStatefulWidget {
  final String title;
  final String description;
  final String username;
  final int userId;
  final SensitiveAction? action;
  final ReauthSecurityLevel? minimumSecurityLevel;

  const ReauthDialog({
    super.key,
    this.title = 'تأیید هویت',
    this.description = 'برای ادامه عملیات، هویت خود را تأیید کنید.',
    required this.username,
    required this.userId,
    this.action,
    this.minimumSecurityLevel,
  });

  static Future<ReauthResult?> show(
    BuildContext context, {
    required String username,
    required int userId,
    SensitiveAction? action,
    String? title,
    String? description,
    ReauthSecurityLevel? minimumSecurityLevel,
    bool allowBiometric = true,
  }) {
    return showDialog<ReauthResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ReauthDialog(
        username: username,
        userId: userId,
        action: action,
        title: title ?? 'تأیید هویت',
        description: description ??
            (action != null
                ? action.descriptionFa
                : 'برای ادامه عملیات، هویت خود را تأیید کنید.'),
        minimumSecurityLevel:
            minimumSecurityLevel ?? action?.minimumSecurityLevel,
      ),
    );
  }

  @override
  ConsumerState<ReauthDialog> createState() => _ReauthDialogState();
}

class _ReauthDialogState extends ConsumerState<ReauthDialog> {
  final _passwordController = TextEditingController();
  final GlobalKey<PatternLockViewState> _patternKey =
      GlobalKey<PatternLockViewState>();

  _ReauthMethodTab _selectedTab = _ReauthMethodTab.password;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _determineInitialTab();
    });
  }

  void _determineInitialTab() {
    if (widget.minimumSecurityLevel == ReauthSecurityLevel.backendPassword) {
      setState(() => _selectedTab = _ReauthMethodTab.password);
      return;
    }

    final lockState = ref.read(appLockControllerProvider);
    final prefs = lockState.preferences;

    if (prefs?.biometricEnabled == true) {
      setState(() => _selectedTab = _ReauthMethodTab.biometric);
      _verifyBiometric();
    } else if (prefs?.patternEnabled == true) {
      setState(() => _selectedTab = _ReauthMethodTab.pattern);
    } else {
      setState(() => _selectedTab = _ReauthMethodTab.password);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _verifyPassword() async {
    final pass = _passwordController.text.trim();
    if (pass.isEmpty) {
      setState(() => _errorMessage = 'وارد کردن کلمه عبور الزامی است.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authRepo = ref.read(authRepositoryProvider);
    final eventLogger = ref.read(securityEventLoggerProvider);

    final success = await authRepo.verifyPassword(pass);

    if (!mounted) return;

    if (success) {
      await eventLogger.log(
        SecurityEventType.passwordReauthSuccess,
        userId: widget.userId,
        action: widget.action?.name,
      );
      if (mounted) {
        Navigator.of(context).pop(const ReauthResult(
          success: true,
          method: ReauthMethod.password,
          securityLevel: ReauthSecurityLevel.backendPassword,
        ));
      }
    } else {
      await eventLogger.log(
        SecurityEventType.passwordReauthFailed,
        userId: widget.userId,
        action: widget.action?.name,
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'کلمه عبور واردشده صحیح نمی‌باشد.';
        });
      }
    }
  }

  Future<void> _verifyBiometric() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final bioService = ref.read(biometricServiceProvider);
    final eventLogger = ref.read(securityEventLoggerProvider);

    final reason = widget.action != null
        ? 'تأیید هویت برای ${widget.action!.titleFa}'
        : 'برای تأیید هویت، اثر انگشت یا چهره خود را تأیید کنید.';

    final result = await bioService.authenticate(localizedReason: reason);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result.isSuccess) {
      if (mounted) {
        Navigator.of(context).pop(const ReauthResult(
          success: true,
          method: ReauthMethod.biometric,
          securityLevel: ReauthSecurityLevel.biometric,
        ));
      }
    } else {
      await eventLogger.log(
        SecurityEventType.biometricFailed,
        userId: widget.userId,
        action: widget.action?.name,
      );

      if (result.isLockout) {
        setState(() {
          _errorMessage =
              'احراز هویت بیومتریک موقتاً در دسترس نیست. لطفاً از الگو یا رمز عبور استفاده کنید.';
          _selectedTab = _ReauthMethodTab.password;
        });
      } else if (!result.isUserCancelled) {
        setState(() {
          _errorMessage =
              result.errorMessageFa ?? 'احراز هویت بیومتریک ناموفق بود.';
        });
      }
    }
  }

  Future<void> _verifyPattern(List<int> pattern) async {
    final storage = ref.read(securityStorageServiceProvider);
    final crypto = ref.read(patternCryptoServiceProvider);
    final eventLogger = ref.read(securityEventLoggerProvider);

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final patternData = await storage.getPatternData(widget.userId);
    if (patternData.hash == null || patternData.salt == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'الگوی قفل تعریف نشده است.';
      });
      return;
    }

    final isValid = crypto.verifyPattern(
      pattern: pattern,
      storedHash: patternData.hash!,
      storedSalt: patternData.salt!,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (isValid) {
      if (mounted) {
        Navigator.of(context).pop(const ReauthResult(
          success: true,
          method: ReauthMethod.pattern,
          securityLevel: ReauthSecurityLevel.pattern,
        ));
      }
    } else {
      await eventLogger.log(
        SecurityEventType.patternFailed,
        userId: widget.userId,
        action: widget.action?.name,
      );
      _patternKey.currentState?.clearPattern();
      setState(() {
        _errorMessage = 'الگوی ترسیمی اشتباه است.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lockState = ref.watch(appLockControllerProvider);
    final prefs = lockState.preferences;

    final hasBiometric = prefs?.biometricEnabled == true;
    final hasPattern = prefs?.patternEnabled == true;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      actionsPadding: const EdgeInsets.all(16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppDimensions.md),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.md),
              ],

              // Content based on selected method
              if (_selectedTab == _ReauthMethodTab.biometric) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: _isLoading ? null : _verifyBiometric,
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: 0.1),
                            border: Border.all(color: AppColors.primary, width: 2),
                          ),
                          child: const Icon(
                            Icons.fingerprint_rounded,
                            size: 56,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _verifyBiometric,
                        icon: const Icon(Icons.touch_app_rounded, size: 18),
                        label: const Text('اسکن مجدد بیومتریک'),
                      ),
                    ],
                  ),
                ),
              ] else if (_selectedTab == _ReauthMethodTab.pattern) ...[
                Center(
                  child: PatternLockView(
                    key: _patternKey,
                    dimension: 240,
                    isEnabled: !_isLoading,
                    isError: _errorMessage != null,
                    onPatternComplete: _verifyPattern,
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'الگوی ورود را رسم نمایید',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ] else ...[
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: 'کلمه عبور (${widget.username})',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  onFieldSubmitted: (_) => _verifyPassword(),
                ),
              ],

              const SizedBox(height: 16),

              // Method Switchers (Only show active ones when not restricted to backend password)
              if (widget.minimumSecurityLevel != ReauthSecurityLevel.backendPassword)
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (hasBiometric && _selectedTab != _ReauthMethodTab.biometric)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedTab = _ReauthMethodTab.biometric;
                            _errorMessage = null;
                          });
                          _verifyBiometric();
                        },
                        icon: const Icon(Icons.fingerprint_rounded, size: 16),
                        label: const Text('استفاده از اثر انگشت', style: TextStyle(fontSize: 12)),
                      ),
                    if (hasPattern && _selectedTab != _ReauthMethodTab.pattern)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedTab = _ReauthMethodTab.pattern;
                            _errorMessage = null;
                          });
                        },
                        icon: const Icon(Icons.pattern_rounded, size: 16),
                        label: const Text('استفاده از الگو', style: TextStyle(fontSize: 12)),
                      ),
                    if (_selectedTab != _ReauthMethodTab.password)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedTab = _ReauthMethodTab.password;
                            _errorMessage = null;
                          });
                        },
                        icon: const Icon(Icons.password_rounded, size: 16),
                        label: const Text('ورود با رمز عبور', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(ReauthResult.failure),
          child: const Text('انصراف'),
        ),
        if (_selectedTab == _ReauthMethodTab.password)
          ElevatedButton(
            onPressed: _isLoading ? null : _verifyPassword,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('تأیید هویت'),
          ),
      ],
    );
  }
}
