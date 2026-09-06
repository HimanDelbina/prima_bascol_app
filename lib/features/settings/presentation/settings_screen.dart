import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../domain/settings_models.dart';
import 'settings_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(systemSettingsProvider);
    final currentThemeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("تنظیمات و پیکربندی سامانه"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'بازگشت به داشبورد',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.dashboard);
            }
          },
        ),
      ),
      body: settingsAsync.when(
        loading: () => const AppLoadingIndicator(message: "در حال دریافت تنظیمات..."),
        error: (e, _) => Center(child: Text("خطا: $e")),
        data: (settings) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Theme Selection Card
              AppCard(
                padding: const EdgeInsets.all(AppDimensions.paddingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.palette_outlined, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text("پوسته و ظاهر برنامه (تم)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.light,
                      groupValue: currentThemeMode,
                      title: const Text("حالت روشن (روز)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text("رنگ‌های روشن، تمیز و خوانا برای محیط‌های پرنور"),
                      secondary: const Icon(Icons.light_mode_rounded, color: Colors.amber),
                      onChanged: (mode) {
                        if (mode != null) {
                          ref.read(themeModeProvider.notifier).setThemeMode(mode);
                        }
                      },
                    ),
                    const Divider(height: 1),
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.dark,
                      groupValue: currentThemeMode,
                      title: const Text("حالت تاریک (شب)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text("کاهش خستگی چشم در محیط‌های کم‌نور و شب‌کار"),
                      secondary: const Icon(Icons.dark_mode_rounded, color: Colors.indigoAccent),
                      onChanged: (mode) {
                        if (mode != null) {
                          ref.read(themeModeProvider.notifier).setThemeMode(mode);
                        }
                      },
                    ),
                    const Divider(height: 1),
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.system,
                      groupValue: currentThemeMode,
                      title: const Text("هماهنگ با سیستم‌عامل", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text("تغییر خودکار مطابق با تنظیمات شب/روز گوشی یا سیستم"),
                      secondary: const Icon(Icons.brightness_auto_rounded, color: Colors.teal),
                      onChanged: (mode) {
                        if (mode != null) {
                          ref.read(themeModeProvider.notifier).setThemeMode(mode);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Security & App Lock Card
              AppCard(
                padding: const EdgeInsets.all(AppDimensions.paddingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.security_rounded, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text("امنیت و ورود (Secure App Lock)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.fingerprint_rounded, color: AppColors.primary),
                      ),
                      title: const Text("تنظیمات ورود سریع و قفل خودکار", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text("مدیریت اثر انگشت، تشخیص چهره، الگوی ترسیمی (Pattern) و زمان قفل خودکار"),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onTap: () {
                        context.push(AppRoutes.securitySettings);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // System Info Card
              AppCard(
                padding: const EdgeInsets.all(AppDimensions.paddingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.info_outline_rounded, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text("مشخصات سامانه", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("نام سامانه"),
                      subtitle: Text(settings.companyName),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("نشانی سرویس‌دهنده مرکزی (API Base URL)"),
                      subtitle: Text(AppConfig.apiBaseUrl),
                    ),
                    const Divider(height: 1),
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text("نسخه کلاینت رسمی"),
                      subtitle: Text("نسخه 1.0.0 (بومی‌سازی اختصاصی فارسی و تقویم جلالی)"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Weighbridge Operational Policy Card
              AppCard(
                padding: const EdgeInsets.all(AppDimensions.paddingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.tune_rounded, color: AppColors.secondary),
                        SizedBox(width: 8),
                        Text("قوانین و رویه‌های عملیاتی باسکول", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("الزام رعایت تقدم وزن اول پیش از وزن دوم"),
                      subtitle: const Text("جلوگیری از ثبت تصادفی وزن دوم برای اسنادی که هنوز وارد نشده‌اند"),
                      value: settings.enforceSequentialWeights,
                      onChanged: (val) {},
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("مجوز ورود دستی وزن توسط اپراتور"),
                      subtitle: const Text("در صورت قطعی ارتباط سخت‌افزاری با نشان‌دهنده"),
                      value: settings.allowManualWeightEntry,
                      onChanged: (val) {},
                    ),
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("درصد تلورانس پیش‌فرض سیستم"),
                      subtitle: Text("${settings.defaultTolerancePercent}% انحراف مجاز وزن با بارنامه"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Center(
                child: Text(
                  "سامانه مدیریت هوشمند باسکول پریما (Prima Bascol) © 1405",
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
