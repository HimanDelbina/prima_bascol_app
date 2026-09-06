import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../domain/security_config.dart';
import '../../domain/sensitive_action.dart';
import '../../domain/unlock_method.dart';
import '../controllers/security_providers.dart';

class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() =>
      _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState
    extends ConsumerState<SecuritySettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authControllerProvider).user;
      if (user != null) {
        ref.read(securitySettingsControllerProvider.notifier).loadSettings(user.id);
      }
    });
  }

  Future<void> _handleBiometricToggle(bool value) async {
    final user = ref.read(authControllerProvider).user;
    if (user == null) return;

    final guard = ref.read(sensitiveActionGuardProvider);
    final authorized = await guard.authorize(
      context,
      action: value
          ? SensitiveAction.changeSecuritySettings
          : SensitiveAction.disableBiometric,
      customDescription: value
          ? 'جهت فعال‌سازی ورود بیومتریک، لطفاً هویت خود را تأیید کنید.'
          : 'جهت غیرفعال‌سازی ورود بیومتریک، لطفاً هویت خود را تأیید کنید.',
    );

    if (!authorized || !mounted) return;

    if (value) {
      final success = await ref
          .read(securitySettingsControllerProvider.notifier)
          .enableBiometric(user.id);
      if (mounted) {
        final state = ref.read(securitySettingsControllerProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? (state.successMessage ?? 'بیومتریک فعال شد.')
                  : (state.errorMessage ?? 'فعال‌سازی بیومتریک ناموفق بود.'),
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    } else {
      final success = await ref
          .read(securitySettingsControllerProvider.notifier)
          .disableBiometric(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'ورود با بیومتریک غیرفعال گردید.'
                : 'خطا در غیرفعال‌سازی بیومتریک.'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handlePatternToggle(bool value) async {
    final user = ref.read(authControllerProvider).user;
    if (user == null) return;

    if (value) {
      // Create pattern requires reauth or directly opens pattern setup
      final guard = ref.read(sensitiveActionGuardProvider);
      final authorized = await guard.authorize(
        context,
        action: SensitiveAction.changePattern,
      );
      if (authorized && mounted) {
        context.push(AppRoutes.patternSetup);
      }
    } else {
      final guard = ref.read(sensitiveActionGuardProvider);
      final authorized = await guard.authorize(
        context,
        action: SensitiveAction.disablePattern,
      );

      if (!authorized || !mounted) return;

      final success = await ref
          .read(securitySettingsControllerProvider.notifier)
          .deletePattern(user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'الگو با موفقیت حذف شد.' : 'خطا در حذف الگو.'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleChangePattern() async {
    final user = ref.read(authControllerProvider).user;
    if (user == null) return;

    final guard = ref.read(sensitiveActionGuardProvider);
    final authorized = await guard.authorize(
      context,
      action: SensitiveAction.changePattern,
    );

    if (authorized && mounted) {
      context.push(AppRoutes.patternSetup);
    }
  }

  Future<void> _handleTestBiometric() async {
    await ref.read(securitySettingsControllerProvider.notifier).testBiometric();
    if (mounted) {
      final state = ref.read(securitySettingsControllerProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            state.successMessage ?? state.errorMessage ?? 'پایان تست.',
          ),
          backgroundColor:
              state.successMessage != null ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  Future<void> _showSecurityLogsDialog() async {
    final logger = ref.read(securityEventLoggerProvider);
    final events = await logger.getEvents(limit: 30);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.history_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('گزارش وقایع امنیتی (Debug Mode)', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: events.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text('هیچ رویدادی ثبت نشده است.')),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final ev = events[i];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        ev.eventType.code.contains('FAILED')
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_outline,
                        color: ev.eventType.code.contains('FAILED')
                            ? Colors.red
                            : Colors.green,
                        size: 20,
                      ),
                      title: Text(
                        ev.eventType.labelFa,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      subtitle: Text(
                        '${ev.timestamp.hour.toString().padLeft(2, '0')}:${ev.timestamp.minute.toString().padLeft(2, '0')}:${ev.timestamp.second.toString().padLeft(2, '0')} | پلتفرم: ${ev.platform}${ev.action != null ? " | ${ev.action}" : ""}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await logger.clearEvents();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('پاکسازی لاگ‌ها', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('بستن'),
          ),
        ],
      ),
    );
  }

  String _formatDateTimeFa(DateTime? dt) {
    if (dt == null) return 'ثبت نشده';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m (${dt.year}/${dt.month}/${dt.day})';
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(securitySettingsControllerProvider);
    final prefs = settingsState.preferences;
    final caps = settingsState.capabilities;
    final theme = Theme.of(context);

    final bool isDeviceBiometricSupported = caps?.isDeviceSupported ?? false;
    final bool isBiometricEnrolled = caps?.isEnrolled ?? false;
    final String biometricLabel = caps?.labelFa ?? 'ورود با اثر انگشت / تشخیص چهره';
    final String? biometricDisabledHint = caps?.unavailabilityReasonFa;

    return Scaffold(
      appBar: AppBar(
        title: const Text('امنیت و قفل برنامه'),
      ),
      body: settingsState.isLoading && prefs == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // بخش ۱: ورود سریع
                  AppCard(
                    padding: const EdgeInsets.all(AppDimensions.paddingMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.touch_app_rounded, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text(
                              'ورود سریع (Quick Unlock)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Biometric Toggle
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(biometricLabel),
                          subtitle: Text(
                            biometricDisabledHint ??
                                (prefs?.biometricEnabled == true
                                    ? 'فعال (ورود سریع با حسگر بیومتریک دستگاه)'
                                    : 'غیرفعال'),
                            style: TextStyle(
                              color: !isDeviceBiometricSupported || !isBiometricEnrolled
                                  ? Colors.orange
                                  : null,
                              fontSize: 12,
                            ),
                          ),
                          value: prefs?.biometricEnabled == true,
                          onChanged: (!isDeviceBiometricSupported || !isBiometricEnrolled)
                              ? null
                              : (val) => _handleBiometricToggle(val),
                          secondary: const Icon(Icons.fingerprint_rounded),
                        ),
                        const Divider(height: 1),

                        // Pattern Toggle
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('ورود با الگوی ترسیمی (Pattern)'),
                          subtitle: Text(
                            prefs?.patternEnabled == true
                                ? 'الگوی ورود تنظیم و فعال است'
                                : 'غیرفعال',
                            style: const TextStyle(fontSize: 12),
                          ),
                          value: prefs?.patternEnabled == true,
                          onChanged: (val) => _handlePatternToggle(val),
                          secondary: const Icon(Icons.pattern_rounded),
                        ),

                        // Preferred Method (if both enabled)
                        if ((prefs?.biometricEnabled ?? false) &&
                            (prefs?.patternEnabled ?? false)) ...[
                          const Divider(height: 16),
                          const Text(
                            'روش ورود ترجیحی در شروع برنامه:',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              ChoiceChip(
                                label: const Text('اثر انگشت / چهره'),
                                selected: prefs?.preferredUnlockMethod ==
                                    UnlockMethod.biometric,
                                onSelected: (sel) {
                                  if (sel) {
                                    ref
                                        .read(
                                            securitySettingsControllerProvider.notifier)
                                        .updatePreferredMethod(
                                            UnlockMethod.biometric);
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text('الگوی ترسیمی'),
                                selected: prefs?.preferredUnlockMethod ==
                                    UnlockMethod.pattern,
                                onSelected: (sel) {
                                  if (sel) {
                                    ref
                                        .read(
                                            securitySettingsControllerProvider.notifier)
                                        .updatePreferredMethod(
                                            UnlockMethod.pattern);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // بخش ۲: قفل برنامه و حریم خصوصی
                  AppCard(
                    padding: const EdgeInsets.all(AppDimensions.paddingMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.shield_rounded, color: AppColors.secondary),
                            SizedBox(width: 8),
                            Text(
                              'قفل برنامه و حفاظت اطلاعات',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Auto Lock Timeout
                        const Text(
                          'زمان قفل خودکار پس از خروج از برنامه:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          initialValue:
                              prefs?.autoLockDuration ?? SecurityConfig.autoLock1Minute,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppDimensions.radiusMd),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          items: SecurityConfig.autoLockOptions.map((sec) {
                            return DropdownMenuItem<int>(
                              value: sec,
                              child: Text(SecurityConfig.autoLockDurationLabelFa(sec)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              ref
                                  .read(securitySettingsControllerProvider.notifier)
                                  .updateAutoLockDuration(val);
                            }
                          },
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 8),

                        // Privacy Overlay Info Tile
                        const ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.visibility_off_outlined, color: Colors.blueGrey),
                          title: Text('پوشش حریم خصوصی (Privacy Overlay)'),
                          subtitle: Text(
                            'محتوای باسکول، پلاک‌ها و طرف حساب‌ها در پیش‌نمایش برنامه‌ها (App Switcher) کاملاً پوشانده می‌شود.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),

                        const Divider(height: 1),

                        // Screenshot Protection Setting
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('جلوگیری از Screenshot در صفحات حساس'),
                          subtitle: const Text(
                            'فعال‌سازی FLAG_SECURE جهت ممانعت از تصویربرداری و ضبط صفحه از داده‌های عملیاتی',
                            style: TextStyle(fontSize: 12),
                          ),
                          value: prefs?.screenshotProtectionEnabled ?? true,
                          onChanged: (val) {
                            ref
                                .read(securitySettingsControllerProvider.notifier)
                                .updateScreenshotProtection(val);
                          },
                          secondary: const Icon(Icons.no_photography_outlined),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // بخش ۳: عملیات حساس و Re-authentication
                  AppCard(
                    padding: const EdgeInsets.all(AppDimensions.paddingMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.verified_user_rounded, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text(
                              'عملیات حساس (Re-authentication)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'قبل از انجام عملیات‌های نظیر اصلاح وزن قبض، ابطال سند یا تغییر تنظیمات، تأیید مجدد هویت الزامی است.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),

                        const Text(
                          'اعتبار نشست تأیید هویت مجدد:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          initialValue:
                              prefs?.sensitiveActionReauthTimeoutMinutes ??
                                  SecurityConfig.defaultReauthTimeoutMinutes,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppDimensions.radiusMd),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          items: SecurityConfig.reauthTimeoutOptions.map((min) {
                            return DropdownMenuItem<int>(
                              value: min,
                              child: Text(SecurityConfig.reauthTimeoutLabelFa(min)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              ref
                                  .read(securitySettingsControllerProvider.notifier)
                                  .updateReauthTimeout(val);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // بخش ۴: اطلاعات امنیتی و عملیات تکمیلی
                  AppCard(
                    padding: const EdgeInsets.all(AppDimensions.paddingMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: Colors.indigo),
                            SizedBox(width: 8),
                            Text(
                              'اطلاعات امنیتی',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('آخرین بازگشایی قفل (Unlock):'),
                          trailing: Text(
                            _formatDateTimeFa(prefs?.lastUnlockedAt),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('روش ورود فعال:'),
                          trailing: Text(
                            prefs?.securityMode.labelFa ?? 'غیرفعال',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Divider(height: 16),

                        // Action Buttons
                        if (prefs?.hasPattern ?? false) ...[
                          OutlinedButton.icon(
                            onPressed: _handleChangePattern,
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('تغییر الگوی ورود'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () => _handlePatternToggle(false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            label: const Text('حذف الگوی ورود'),
                          ),
                          const SizedBox(height: 8),
                        ],

                        if (isDeviceBiometricSupported) ...[
                          OutlinedButton.icon(
                            onPressed: _handleTestBiometric,
                            icon: const Icon(Icons.fingerprint_rounded),
                            label: const Text('تست حسگر بیومتریک'),
                          ),
                          const SizedBox(height: 8),
                        ],

                        if (kDebugMode) ...[
                          OutlinedButton.icon(
                            onPressed: _showSecurityLogsDialog,
                            icon: const Icon(Icons.list_alt_rounded),
                            label: const Text('مشاهده لاگ‌های امنیتی (Debug)'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Center(
                    child: Text(
                      'کلیه الگوها با PBKDF2 و Salt امن رمزنگاری شده و داده‌های بیومتریک یا پسوردها هرگز ذخیره نمی‌شوند.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
