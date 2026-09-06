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
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/widgets/stat_card.dart';
import '../domain/monitoring_models.dart';
import 'monitoring_providers.dart';

class MonitoringScreen extends ConsumerStatefulWidget {
  const MonitoringScreen({super.key});

  @override
  ConsumerState<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends ConsumerState<MonitoringScreen> {
  void _resolveAlertDialog(MonitoringAlertItem alert) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("حل هشدار: ${alert.ruleName}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("لطفاً توضیحات یا اقدامات انجام‌شده جهت رفع این هشدار را وارد نمایید: *"),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "مثال: وزن مجدداً بررسی شد و تلورانس به علت رطوبت بار تأیید گردید.",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("انصراف")),
          ElevatedButton(
            onPressed: () async {
              final note = noteCtrl.text.trim();
              if (note.length < 3) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("لطفاً حداقل ۳ کاراکتر یادداشت اقدام را وارد فرمایید."), backgroundColor: AppColors.warning),
                );
                return;
              }
              final repo = ref.read(monitoringRepositoryProvider);
              await repo.resolveAlert(alert.id, note: note);
              if (mounted) {
                Navigator.pop(ctx);
                ref.refresh(monitoringAlertsProvider);
                ref.refresh(monitoringSummaryProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("هشدار با موفقیت حل و مختومه گردید."), backgroundColor: AppColors.success),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text("ثبت و حل هشدار"),
          ),
        ],
      ),
    );
  }

  void _ignoreAlertDialog(MonitoringAlertItem alert) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("نادیده‌گرفتن هشدار: ${alert.ruleName}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("علت نادیده‌گرفتن این هشدار چیست؟ *"),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(hintText: "دلیل نادیده‌گرفتن را ذکر فرمایید..."),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("انصراف")),
          ElevatedButton(
            onPressed: () async {
              final note = noteCtrl.text.trim();
              if (note.length < 3) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("لطفاً حداقل ۳ کاراکتر دلیل نادیده‌گرفتن را وارد فرمایید."), backgroundColor: AppColors.warning),
                );
                return;
              }
              final repo = ref.read(monitoringRepositoryProvider);
              await repo.ignoreAlert(alert.id, note: note);
              if (mounted) {
                Navigator.pop(ctx);
                ref.refresh(monitoringAlertsProvider);
                ref.refresh(monitoringSummaryProvider);
              }
            },
            child: const Text("تأیید نادیده‌گرفتن"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(monitoringSummaryProvider);
    final alertsAsync = ref.watch(monitoringAlertsProvider);
    final selectedStatus = ref.watch(monitoringFilterStatusProvider);
    final selectedSeverity = ref.watch(monitoringFilterSeverityProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          ResponsiveLayout.isMobile(context)
              ? "پایش هوشمند"
              : "مرکز پایش هوشمند و آنومالی‌ها",
        ),
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
        actions: [
          TextButton.icon(
            onPressed: () => context.go(AppRoutes.monitoringRules),
            icon: const Icon(Icons.rule_folder_outlined),
            label: const Text("قوانین پایش"),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "بروزرسانی",
            onPressed: () {
              ref.refresh(monitoringSummaryProvider);
              ref.refresh(monitoringAlertsProvider);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary KPIs
            summaryAsync.when(
              loading: () => const AppLoadingIndicator(message: "در حال دریافت خلاصه وضعیت پایش..."),
              error: (err, _) => AppErrorState(message: err.toString(), onRetry: () => ref.refresh(monitoringSummaryProvider)),
              data: (summary) => ResponsiveLayout(
                mobile: Column(
                  children: [
                    StatCard(title: "هشدارهای باز", value: "${summary.openCount}", icon: Icons.warning_amber_rounded, color: AppColors.warning),
                    const SizedBox(height: 10),
                    StatCard(title: "هشدارهای بحرانی", value: "${summary.criticalCount}", icon: Icons.error_outline_rounded, color: AppColors.error),
                    const SizedBox(height: 10),
                    StatCard(title: "تحت بررسی", value: "${summary.reviewedCount}", icon: Icons.pending_actions_rounded, color: AppColors.info),
                    const SizedBox(height: 10),
                    StatCard(title: "حل و مختومه", value: "${summary.resolvedCount}", icon: Icons.check_circle_outline_rounded, color: AppColors.success),
                  ],
                ),
                desktop: Row(
                  children: [
                    Expanded(child: StatCard(title: "هشدارهای باز", value: "${summary.openCount}", icon: Icons.warning_amber_rounded, color: AppColors.warning)),
                    const SizedBox(width: 12),
                    Expanded(child: StatCard(title: "هشدارهای بحرانی", value: "${summary.criticalCount}", icon: Icons.error_outline_rounded, color: AppColors.error)),
                    const SizedBox(width: 12),
                    Expanded(child: StatCard(title: "تحت بررسی", value: "${summary.reviewedCount}", icon: Icons.pending_actions_rounded, color: AppColors.info)),
                    const SizedBox(width: 12),
                    Expanded(child: StatCard(title: "حل و مختومه", value: "${summary.resolvedCount}", icon: Icons.check_circle_outline_rounded, color: AppColors.success)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Filters
            AppCard(
              padding: const EdgeInsets.all(AppDimensions.paddingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("فیلترهای هشدار:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text("وضعیت: ", style: TextStyle(fontSize: 13, color: Colors.grey)),
                      _filterChip("همه", null, selectedStatus, (val) => ref.read(monitoringFilterStatusProvider.notifier).state = val),
                      _filterChip("باز", "OPEN", selectedStatus, (val) => ref.read(monitoringFilterStatusProvider.notifier).state = val),
                      _filterChip("تحت بررسی", "REVIEWED", selectedStatus, (val) => ref.read(monitoringFilterStatusProvider.notifier).state = val),
                      _filterChip("حل‌شده", "RESOLVED", selectedStatus, (val) => ref.read(monitoringFilterStatusProvider.notifier).state = val),
                      _filterChip("نادیده‌گرفته", "IGNORED", selectedStatus, (val) => ref.read(monitoringFilterStatusProvider.notifier).state = val),
                      const SizedBox(width: 16),
                      const Text("شدت: ", style: TextStyle(fontSize: 13, color: Colors.grey)),
                      _filterChip("همه", null, selectedSeverity, (val) => ref.read(monitoringFilterSeverityProvider.notifier).state = val),
                      _filterChip("بحرانی", "CRITICAL", selectedSeverity, (val) => ref.read(monitoringFilterSeverityProvider.notifier).state = val),
                      _filterChip("بالا", "HIGH", selectedSeverity, (val) => ref.read(monitoringFilterSeverityProvider.notifier).state = val),
                      _filterChip("متوسط", "MEDIUM", selectedSeverity, (val) => ref.read(monitoringFilterSeverityProvider.notifier).state = val),
                      _filterChip("کم", "LOW", selectedSeverity, (val) => ref.read(monitoringFilterSeverityProvider.notifier).state = val),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Alert List
            alertsAsync.when(
              loading: () => const AppLoadingIndicator(message: "در حال بارگذاری هشدارها..."),
              error: (err, _) => AppErrorState(message: err.toString(), onRetry: () => ref.refresh(monitoringAlertsProvider)),
              data: (alerts) {
                if (alerts.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.verified_user_outlined,
                    title: "هیچ هشداری یافت نشد",
                    description: "تمام فرآیندهای باسکول مطابق با حد استاندارد و الگوهای طبیعی ثبت شده‌اند.",
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: alerts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) => _buildAlertCard(alerts[i]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String? value, String? current, ValueChanged<String?> onSelected) {
    final isSelected = current == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
    );
  }

  Widget _buildAlertCard(MonitoringAlertItem alert) {
    Color sevColor;
    String sevLabel;
    switch (alert.severity.toUpperCase()) {
      case 'CRITICAL':
        sevColor = AppColors.riskCritical;
        sevLabel = "بحرانی";
        break;
      case 'HIGH':
        sevColor = AppColors.riskHigh;
        sevLabel = "بالا";
        break;
      case 'MEDIUM':
        sevColor = AppColors.riskMedium;
        sevLabel = "متوسط";
        break;
      case 'INFO':
        sevColor = Colors.blue;
        sevLabel = "اطلاعات";
        break;
      case 'LOW':
      default:
        sevColor = AppColors.riskLow;
        sevLabel = "کم";
        break;
    }

    final alertStatus = alert.status.toUpperCase();
    final isOpen = alertStatus == 'OPEN';
    final isReviewed = alertStatus == 'REVIEWED';

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.paddingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: sevColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                      border: Border.all(color: sevColor.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_rounded, size: 14, color: sevColor),
                        const SizedBox(width: 4),
                        Text(sevLabel, style: TextStyle(color: sevColor, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(alert.ruleName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              if (alert.ticketSerial != null)
                InkWell(
                  onTap: () {
                    if (alert.ticketId != null) {
                      context.go(AppRoutes.ticketDetailPath(alert.ticketId!));
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    ),
                    child: Text("قبض #${alert.ticketSerial}", style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(alert.description, style: const TextStyle(fontSize: 13, height: 1.5)),
          if (alert.currentValue != null || alert.baselineValue != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.06),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: Row(
                children: [
                  if (alert.currentValue != null)
                    Text("مقدار ثبت‌شده: ${alert.currentValue} | ", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  if (alert.baselineValue != null)
                    Text("مقدار مبنا: ${alert.baselineValue} | ", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  if (alert.deviationPercent != null)
                    Text("درصد انحراف: ${alert.deviationPercent?.toStringAsFixed(1)}%", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: sevColor)),
                ],
              ),
            ),
          ],
          if (alert.resolvedNotes != null && alert.resolvedNotes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text("یادداشت حل: ${alert.resolvedNotes}", style: const TextStyle(fontSize: 12, color: AppColors.success, fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(alert.createdAtJalali ?? "", style: const TextStyle(fontSize: 11, color: Colors.grey)),
              if (isOpen || isReviewed)
                Row(
                  children: [
                    if (isOpen)
                      OutlinedButton(
                        onPressed: () async {
                          final repo = ref.read(monitoringRepositoryProvider);
                          await repo.reviewAlert(alert.id);
                          ref.refresh(monitoringAlertsProvider);
                          ref.refresh(monitoringSummaryProvider);
                        },
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                        child: const Text("بررسی شد"),
                      ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _resolveAlertDialog(alert),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                      child: const Text("حل هشدار"),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => _ignoreAlertDialog(alert),
                      child: const Text("نادیده‌گرفتن", style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
