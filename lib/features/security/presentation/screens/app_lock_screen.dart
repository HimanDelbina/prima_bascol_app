import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../domain/unlock_method.dart';
import '../controllers/app_lock_controller.dart';
import '../controllers/security_providers.dart';
import '../widgets/pattern_lock_view.dart';

class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  final GlobalKey<PatternLockViewState> _patternKey =
      GlobalKey<PatternLockViewState>();
  bool _hasTriggeredAutoBiometric = false;
  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoPromptBiometric();
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void _checkAutoPromptBiometric() {
    final lockState = ref.read(appLockControllerProvider);
    if (_hasTriggeredAutoBiometric) return;

    if (lockState.activeUnlockMethod == UnlockMethod.biometric &&
        (lockState.preferences?.biometricEnabled ?? false)) {
      _hasTriggeredAutoBiometric = true;
      ref.read(appLockControllerProvider.notifier).unlockWithBiometric();
    }
  }

  String _formatPersianTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  Future<void> _handlePasswordFallback({bool isForgotPattern = false}) async {
    final user = ref.read(authControllerProvider).user;
    final passwordController = TextEditingController();
    bool obscure = true;
    String? localError;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              ),
              title: Row(
                children: [
                  const Icon(Icons.password_rounded, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    isForgotPattern
                        ? 'فراموشی الگو - ورود با رمز عبور'
                        : 'ورود اضطراری با رمز عبور',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isForgotPattern
                        ? 'با تأیید رمز عبور، الگوی قبلی حذف شده و قفل برنامه باز خواهد شد.'
                        : 'لطفاً برای بازگشایی قفل برنامه، کلمه عبور خود را وارد کنید.',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  if (localError != null) ...[
                    Text(
                      localError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                  ],
                  TextField(
                    controller: passwordController,
                    obscureText: obscure,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: 'کلمه عبور (${user?.username ?? ""})',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () => setState(() => obscure = !obscure),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(false),
                  child: const Text('انصراف'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final pass = passwordController.text.trim();
                    if (pass.isEmpty) {
                      setState(() => localError = 'کلمه عبور را وارد کنید.');
                      return;
                    }
                    final verified = await ref
                        .read(securitySettingsControllerProvider.notifier)
                        .verifyPassword(user?.username ?? '', pass);

                    if (verified) {
                      if (dialogCtx.mounted) {
                        Navigator.of(dialogCtx).pop(true);
                      }
                    } else {
                      if (dialogCtx.mounted) {
                        setState(() => localError = 'کلمه عبور نادرست است.');
                      }
                    }
                  },
                  child: const Text('ورود'),
                ),
              ],
            );
          },
        );
      },
    );

    passwordController.dispose();

    if (confirmed == true && user != null) {
      if (isForgotPattern) {
        await ref
            .read(securitySettingsControllerProvider.notifier)
            .deletePattern(user.id);
      }
      await ref.read(securityStorageServiceProvider).clearLockoutState(user.id);
      await ref.read(appLockControllerProvider.notifier).initializeForUser(user);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(appLockControllerProvider);
    final theme = Theme.of(context);
    final user = lockState.user ?? ref.watch(authControllerProvider).user;
    final prefs = lockState.preferences;

    final canSwitchMethod = (prefs?.biometricEnabled ?? false) &&
        (prefs?.patternEnabled ?? false);
    final isLockedOut = lockState.lockoutState.isLocked;
    final remainingSec = lockState.lockoutState.remainingSeconds;
    final isPasswordRequired = lockState.lockoutState.isPasswordRequired;
    final isSessionExpired = lockState.status == AppLockStatus.sessionExpired;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AppCard(
                padding: const EdgeInsets.all(AppDimensions.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand / Logo & Live Clock
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.scale_rounded,
                                  size: 24,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  AppConfig.appName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Live Clock Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatPersianTime(_currentTime),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    // User Profile Banner (Name + Persian Role)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                            child: const Icon(
                              Icons.person_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.fullName.isNotEmpty == true
                                      ? user!.fullName
                                      : (user?.username ?? 'اپراتور باسکول'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user?.role.label ?? 'اپراتور',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Preferred Unlock Method Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              prefs?.preferredUnlockMethod == UnlockMethod.biometric
                                  ? 'اثر انگشت'
                                  : 'الگو',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.md),

                    // Session Expired Notice (Rule 22)
                    if (isSessionExpired) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: AppDimensions.md),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Column(
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 22),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'نشست شما منقضی شده است. لطفاً دوباره وارد شوید.',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await ref.read(authControllerProvider.notifier).logout();
                                  await ref
                                      .read(appLockControllerProvider.notifier)
                                      .handleLogout();
                                  if (context.mounted) {
                                    context.go(AppRoutes.login);
                                  }
                                },
                                icon: const Icon(Icons.login_rounded, size: 18),
                                label: const Text('ورود مجدد با نام کاربری و کلمه عبور'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Error or Lockout Message
                    if ((lockState.errorMessage != null || isLockedOut) && !isSessionExpired) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: AppDimensions.md),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isPasswordRequired
                                    ? 'تعداد دفعات اشتباه بیش از حد مجاز (۱۵ بار). الزام ورود با رمز عبور.'
                                    : isLockedOut
                                        ? 'قفل موقت! لطفاً $remainingSec ثانیه دیگر شکیبا باشید.'
                                        : (lockState.errorMessage ?? ''),
                                style: const TextStyle(color: Colors.red, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (!isSessionExpired) ...[
                      // Primary Unlock Method: Biometric or Pattern
                      if (lockState.activeUnlockMethod == UnlockMethod.biometric) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Column(
                            children: [
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => ref
                                      .read(appLockControllerProvider.notifier)
                                      .unlockWithBiometric(),
                                  borderRadius:
                                      BorderRadius.circular(AppDimensions.radiusFull),
                                  child: Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.08),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.primary.withValues(alpha: 0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.fingerprint_rounded,
                                      size: 64,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppDimensions.md),
                              ElevatedButton.icon(
                                onPressed: () => ref
                                    .read(appLockControllerProvider.notifier)
                                    .unlockWithBiometric(),
                                icon: const Icon(Icons.touch_app_rounded, size: 20),
                                label: const Text('ورود با اثر انگشت / تشخیص چهره'),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Pattern View
                        PatternLockView(
                          key: _patternKey,
                          dimension: 260,
                          isEnabled: !isLockedOut,
                          isError: lockState.errorMessage != null && !isLockedOut,
                          onPatternComplete: (pattern) async {
                            final success = await ref
                                .read(appLockControllerProvider.notifier)
                                .unlockWithPattern(pattern);
                            if (!success && mounted) {
                              _patternKey.currentState?.clearPattern();
                            }
                          },
                        ),
                      ],

                      const SizedBox(height: AppDimensions.sm),

                      // Method Switch Button (if both enabled)
                      if (canSwitchMethod) ...[
                        TextButton.icon(
                          onPressed: () {
                            final newMethod = lockState.activeUnlockMethod ==
                                    UnlockMethod.biometric
                                ? UnlockMethod.pattern
                                : UnlockMethod.biometric;
                            ref
                                .read(appLockControllerProvider.notifier)
                                .switchUnlockMethod(newMethod);
                            if (newMethod == UnlockMethod.biometric) {
                              ref
                                  .read(appLockControllerProvider.notifier)
                                  .unlockWithBiometric();
                            }
                          },
                          icon: Icon(
                            lockState.activeUnlockMethod == UnlockMethod.biometric
                                ? Icons.pattern_rounded
                                : Icons.fingerprint_rounded,
                            size: 18,
                          ),
                          label: Text(
                            lockState.activeUnlockMethod == UnlockMethod.biometric
                                ? 'استفاده از الگو'
                                : 'ورود با اثر انگشت',
                          ),
                        ),
                      ],

                      const Divider(height: 24),

                      // Fallback buttons
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          TextButton(
                            onPressed: () =>
                                _handlePasswordFallback(isForgotPattern: false),
                            child: const Text('ورود با رمز عبور'),
                          ),
                          if (prefs?.patternEnabled ?? false) ...[
                            Text(
                              '•',
                              style: TextStyle(color: Colors.grey.shade400),
                            ),
                            TextButton(
                              onPressed: () =>
                                  _handlePasswordFallback(isForgotPattern: true),
                              child: const Text(
                                'الگو را فراموش کرده‌ام',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],

                    // Logout option
                    TextButton.icon(
                      onPressed: () async {
                        await ref.read(authControllerProvider.notifier).logout();
                        await ref
                            .read(appLockControllerProvider.notifier)
                            .handleLogout();
                        if (context.mounted) {
                          context.go(AppRoutes.login);
                        }
                      },
                      icon: const Icon(Icons.logout_rounded, size: 16, color: Colors.red),
                      label: const Text(
                        'خروج از حساب کاربری',
                        style: TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
