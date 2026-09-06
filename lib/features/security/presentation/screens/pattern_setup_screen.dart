import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../controllers/security_providers.dart';
import '../widgets/pattern_lock_view.dart';

enum PatternSetupStep {
  firstAttempt,
  confirmation,
}

class PatternSetupScreen extends ConsumerStatefulWidget {
  const PatternSetupScreen({super.key});

  @override
  ConsumerState<PatternSetupScreen> createState() => _PatternSetupScreenState();
}

class _PatternSetupScreenState extends ConsumerState<PatternSetupScreen> {
  final GlobalKey<PatternLockViewState> _patternKey = GlobalKey<PatternLockViewState>();
  PatternSetupStep _currentStep = PatternSetupStep.firstAttempt;
  List<int>? _firstPattern;
  bool _isError = false;
  String? _statusMessage = 'الگوی مورد نظر خود را رسم کنید (حداقل ۴ نقطه)';
  String? _warningMessage;

  void _onPatternComplete(List<int> pattern) async {
    final cryptoService = ref.read(patternCryptoServiceProvider);

    if (_currentStep == PatternSetupStep.firstAttempt) {
      final validation = cryptoService.validatePattern(pattern);
      if (!validation.isValid) {
        setState(() {
          _isError = true;
          _statusMessage = validation.errorMessage;
          _warningMessage = null;
        });
        return;
      }

      setState(() {
        _firstPattern = List<int>.from(pattern);
        _currentStep = PatternSetupStep.confirmation;
        _isError = false;
        _statusMessage = 'الگو را دوباره برای تأیید وارد کنید';
        _warningMessage = validation.warningMessage;
      });
      _patternKey.currentState?.clearPattern();
    } else {
      // Confirmation step
      if (_firstPattern == null) {
        _resetToStep1();
        return;
      }

      final isMatch = _firstPattern!.length == pattern.length &&
          List.generate(_firstPattern!.length, (i) => _firstPattern![i] == pattern[i])
              .every((matched) => matched);

      if (!isMatch) {
        setState(() {
          _isError = true;
          _statusMessage = 'الگوها یکسان نیستند. دوباره تلاش کنید.';
        });
        return;
      }

      // Pattern matched! Save
      final currentUser = ref.read(authControllerProvider).user;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطا: کاربر واردشده شناسایی نشد.')),
        );
        return;
      }

      final success = await ref
          .read(securitySettingsControllerProvider.notifier)
          .saveNewPattern(currentUser.id, pattern);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('الگوی ورود با موفقیت ذخیره شد.'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          setState(() {
            _isError = true;
            _statusMessage = 'خطا در ذخیره‌سازی الگو. لطفاً مجدداً امتحان کنید.';
          });
        }
      }
    }
  }

  void _resetToStep1() {
    setState(() {
      _currentStep = PatternSetupStep.firstAttempt;
      _firstPattern = null;
      _isError = false;
      _statusMessage = 'الگوی مورد نظر خود را رسم کنید (حداقل ۴ نقطه)';
      _warningMessage = null;
    });
    _patternKey.currentState?.clearPattern();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تعریف الگوی ورود (Pattern)'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: AppCard(
              padding: const EdgeInsets.all(AppDimensions.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pattern_rounded,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.md),
                  Text(
                    _currentStep == PatternSetupStep.firstAttempt
                        ? 'مرحله ۱: ترسیم الگو'
                        : 'مرحله ۲: تأیید الگو',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  Text(
                    _statusMessage ?? '',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _isError ? AppColors.error : theme.textTheme.bodyMedium?.color,
                      fontSize: 13,
                      fontWeight: _isError ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (_warningMessage != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _warningMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppDimensions.lg),

                  // 3x3 Pattern Lock View
                  PatternLockView(
                    key: _patternKey,
                    dimension: 280,
                    isError: _isError,
                    onPatternComplete: _onPatternComplete,
                  ),
                  const SizedBox(height: AppDimensions.lg),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: _resetToStep1,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('شروع مجدد'),
                      ),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('انصراف'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
