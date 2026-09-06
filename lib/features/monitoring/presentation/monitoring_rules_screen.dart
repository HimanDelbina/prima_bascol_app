import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import 'monitoring_providers.dart';

class MonitoringRulesScreen extends ConsumerWidget {
  const MonitoringRulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(monitoringRulesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("قوانین و آستانه‌های پایش هوشمند"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'بازگشت',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.monitoring);
            }
          },
        ),
      ),
      body: rulesAsync.when(
        loading: () => const AppLoadingIndicator(message: "در حال دریافت قوانین پایش..."),
        error: (err, _) => AppErrorState(message: err.toString(), onRetry: () => ref.refresh(monitoringRulesProvider)),
        data: (rules) {
          if (rules.isEmpty) {
            return const AppEmptyState(icon: Icons.rule_folder_outlined, title: "قانونی تعریف نشده است", description: "قوانین پایش و حدود آستانه از طرف بک‌اند مدیریت می‌شوند.");
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppDimensions.paddingMd),
            itemCount: rules.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final r = rules[i];
              return AppCard(
                padding: const EdgeInsets.all(AppDimensions.paddingMd),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: const Icon(Icons.tune_rounded, color: AppColors.primary),
                  ),
                  title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("کد: ${r.code} | آستانه حساسیت: ${r.threshold} | شدت: ${r.severity}"),
                  trailing: Chip(
                    label: Text(r.isActive ? "فعال" : "غیرفعال", style: TextStyle(color: r.isActive ? AppColors.success : AppColors.error, fontSize: 11)),
                    backgroundColor: (r.isActive ? AppColors.success : AppColors.error).withOpacity(0.1),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
