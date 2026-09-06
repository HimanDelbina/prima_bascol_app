import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/routing/route_names.dart';
import '../../../auth/domain/auth_models.dart';
import '../controllers/security_providers.dart';

class FirstSetupSheet extends ConsumerWidget {
  final UserMe user;

  const FirstSetupSheet({super.key, required this.user});

  static Future<void> show(BuildContext context, UserMe user) {
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FirstSetupSheet(user: user),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final secSettingsState = ref.watch(securitySettingsControllerProvider);
    final capabilities = secSettingsState.capabilities;
    final isBiometricAvailable = capabilities?.isEnrolled ?? false;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ورود سریع و امن به سامانه',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'آیا مایلید اثر انگشت یا الگو را برای ورودهای بعدی فعال کنید؟',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.lg),

            // Option 1: Biometric
            if (isBiometricAvailable) ...[
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final success = await ref
                      .read(securitySettingsControllerProvider.notifier)
                      .enableBiometric(user.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'ورود بیومتریک با موفقیت فعال شد.'
                              : 'فعال‌سازی بیومتریک لغو شد یا با خطا مواجه شد.',
                        ),
                      ),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                ),
                icon: const Icon(Icons.fingerprint_rounded, size: 24),
                label: Text(
                  capabilities?.labelFa ?? 'فعال‌سازی اثر انگشت / چهره',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: AppDimensions.sm),
            ],

            // Option 2: Pattern Setup
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.patternSetup);
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
              ),
              icon: const Icon(Icons.pattern_rounded, size: 24),
              label: const Text(
                'تعریف الگوی امن (Pattern)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: AppDimensions.sm),

            // Option 3: Skip / Not Now
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'فعلاً نه (بعداً از تنظیمات قابل فعال‌سازی است)',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
