import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/iranian_plate_widget.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/widgets/stat_card.dart';
import '../domain/monitoring_models.dart';
import 'monitoring_providers.dart';
import 'widgets/alert_detail_sheet.dart';

class MonitoringScreen extends ConsumerStatefulWidget {
  const MonitoringScreen({super.key});

  @override
  ConsumerState<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends ConsumerState<MonitoringScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openDetailSheet(MonitoringAlertItem alert) {
    AlertDetailSheet.show(
      context,
      alert: alert,
      onStatusChanged: () {
        ref.invalidate(monitoringAlertsProvider);
        ref.invalidate(monitoringSummaryProvider);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(monitoringSummaryProvider);
    final alertsAsync = ref.watch(monitoringAlertsProvider);
    final selectedStatus = ref.watch(monitoringFilterStatusProvider);
    final selectedSeverity = ref.watch(monitoringFilterSeverityProvider);
    final selectedType = ref.watch(monitoringFilterTypeProvider);
    final isMobile = ResponsiveLayout.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isMobile ? "پایش هوشمند" : "مرکز پایش هوشمند، تشخیص مغایرت و رفتار غیرعادی",
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
            icon: const Icon(Icons.tune_rounded),
            label: const Text("تنظیمات قوانین"),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "بروزرسانی",
            onPressed: () {
              ref.invalidate(monitoringSummaryProvider);
              ref.invalidate(monitoringAlertsProvider);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // KPI Summary Cards
            summaryAsync.when(
              loading: () => const AppLoadingIndicator(message: "در حال دریافت خلاصه وضعیت پایش..."),
              error: (err, _) => AppErrorState(
                message: err.toString(),
                onRetry: () => ref.invalidate(monitoringSummaryProvider),
              ),
              data: (summary) => _buildKpis(context, summary),
            ),
            const SizedBox(height: 16),

            // Filter Bar
            AppCard(
              padding: const EdgeInsets.all(AppDimensions.paddingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.filter_list_rounded, size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text(
                        "فیلترهای هوشمند و جستجو:",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const Spacer(),
                      if (selectedStatus != null || selectedSeverity != null || selectedType != null || _searchController.text.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            ref.read(monitoringFilterSearchProvider.notifier).state = null;
                            ref.read(monitoringFilterStatusProvider.notifier).state = null;
                            ref.read(monitoringFilterSeverityProvider.notifier).state = null;
                            ref.read(monitoringFilterTypeProvider.notifier).state = null;
                          },
                          child: const Text("پاکسازی فیلترها", style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Search input
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "جستجو در عنوان، پلاک، شماره قبض یا دلیل هشدار...",
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(monitoringFilterSearchProvider.notifier).state = null;
                              },
                            )
                          : null,
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (val) {
                      ref.read(monitoringFilterSearchProvider.notifier).state = val.trim().isNotEmpty ? val.trim() : null;
                    },
                  ),
                  const SizedBox(height: 10),
                  // Status chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text("وضعیت: ", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      _filterChip("همه", null, selectedStatus, (val) => ref.read(monitoringFilterStatusProvider.notifier).state = val),
                      _filterChip("باز", "OPEN", selectedStatus, (val) => ref.read(monitoringFilterStatusProvider.notifier).state = val),
                      _filterChip("تحت بررسی", "REVIEWED", selectedStatus, (val) => ref.read(monitoringFilterStatusProvider.notifier).state = val),
                      _filterChip("حل‌شده", "RESOLVED", selectedStatus, (val) => ref.read(monitoringFilterStatusProvider.notifier).state = val),
                      _filterChip("نادیده‌گرفته", "IGNORED", selectedStatus, (val) => ref.read(monitoringFilterStatusProvider.notifier).state = val),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Severity chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text("اهمیت: ", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      _filterChip("همه", null, selectedSeverity, (val) => ref.read(monitoringFilterSeverityProvider.notifier).state = val),
                      _filterChip("بحرانی", "CRITICAL", selectedSeverity, (val) => ref.read(monitoringFilterSeverityProvider.notifier).state = val, color: AppColors.riskCritical),
                      _filterChip("بالا", "HIGH", selectedSeverity, (val) => ref.read(monitoringFilterSeverityProvider.notifier).state = val, color: AppColors.riskHigh),
                      _filterChip("متوسط", "MEDIUM", selectedSeverity, (val) => ref.read(monitoringFilterSeverityProvider.notifier).state = val, color: AppColors.riskMedium),
                      _filterChip("کم / اطلاعات", "LOW", selectedSeverity, (val) => ref.read(monitoringFilterSeverityProvider.notifier).state = val, color: AppColors.riskLow),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Alert List or Table
            alertsAsync.when(
              loading: () => const AppLoadingIndicator(message: "در حال بارگذاری هشدارها..."),
              error: (err, _) => AppErrorState(
                message: err.toString(),
                onRetry: () => ref.invalidate(monitoringAlertsProvider),
              ),
              data: (alerts) {
                if (alerts.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.verified_user_outlined,
                    title: "هیچ هشدار مغایرتی یافت نشد",
                    description: "تمام عملیات و اوزان ثبت‌شده باسکول در محدوده استاندارد و الگوی تاریخی قرار دارند.",
                  );
                }

                if (isMobile) {
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: alerts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) => _buildMobileAlertCard(alerts[i]),
                  );
                }

                return _buildDesktopAlertTable(context, alerts);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpis(BuildContext context, MonitoringSummaryModel summary) {
    return ResponsiveLayout(
      mobile: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: "هشدارهای باز",
                  value: "${summary.openCount}",
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  title: "هشدارهای بحرانی",
                  value: "${summary.criticalCount}",
                  icon: Icons.dangerous_rounded,
                  color: AppColors.riskCritical,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: "اهمیت بالا",
                  value: "${summary.highCount}",
                  icon: Icons.error_outline_rounded,
                  color: AppColors.riskHigh,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  title: "حل و مختومه",
                  value: "${summary.resolvedCount}",
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
      desktop: Row(
        children: [
          Expanded(
            child: StatCard(
              title: "هشدارهای امروز",
              value: "${summary.totalToday}",
              icon: Icons.today_rounded,
              color: const Color(0xFF0284C7),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StatCard(
              title: "کل هشدارهای باز",
              value: "${summary.totalOpen}",
              icon: Icons.warning_amber_rounded,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StatCard(
              title: "هشدارهای بحرانی",
              value: "${summary.criticalCount}",
              icon: Icons.dangerous_rounded,
              color: AppColors.riskCritical,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StatCard(
              title: "هشدارهای با ریسک بالا",
              value: "${summary.highCount}",
              icon: Icons.error_outline_rounded,
              color: AppColors.riskHigh,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StatCard(
              title: "حل و مختومه",
              value: "${summary.resolvedCount}",
              icon: Icons.check_circle_outline_rounded,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(
    String label,
    String? value,
    String? current,
    ValueChanged<String?> onSelected, {
    Color? color,
  }) {
    final isSelected = current == value;
    return ChoiceChip(
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected && color != null ? color : null,
      ),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
    );
  }

  Widget _buildMobileAlertCard(MonitoringAlertItem alert) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: InkWell(
        onTap: () => _openDetailSheet(alert),
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Severity + Title + Status
            Row(
              children: [
                Icon(alert.severityIcon, color: alert.severityColor, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    alert.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: alert.statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: alert.statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    alert.statusTitle,
                    style: TextStyle(color: alert.statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Plate + Serial
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (alert.ticketPlate != null && alert.ticketPlate!.isNotEmpty)
                  IranianPlateWidget(plateDisplay: alert.ticketPlate!, scale: 0.75)
                else
                  Text("قبض: ${alert.ticketSerial ?? alert.ticketId ?? '-'}", style: const TextStyle(fontSize: 12)),
                Text(
                  alert.productName ?? alert.partyName ?? '',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Reason summary
            Text(
              alert.reason.isNotEmpty ? alert.reason : alert.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.4),
            ),
            const SizedBox(height: 8),

            // Deviation Badge + Date + View Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (alert.deviationPercent != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: alert.severityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "انحراف: ${alert.deviationPercent!.toStringAsFixed(1)}٪",
                      style: TextStyle(color: alert.severityColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                Row(
                  children: [
                    Text(alert.createdAtJalali ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopAlertTable(BuildContext context, List<MonitoringAlertItem> alerts) {
    final theme = Theme.of(context);
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)),
              columns: const [
                DataColumn(label: Text("سطح اهمیت")),
                DataColumn(label: Text("نوع هشدار")),
                DataColumn(label: Text("قبض و پلاک")),
                DataColumn(label: Text("کالا / طرف حساب")),
                DataColumn(label: Text("مقدار فعلی")),
                DataColumn(label: Text("مقدار مبنا")),
                DataColumn(label: Text("درصد انحراف")),
                DataColumn(label: Text("وضعیت")),
                DataColumn(label: Text("تاریخ کشف")),
                DataColumn(label: Text("عملیات")),
              ],
              rows: alerts.map((a) {
                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(a.severityIcon, color: a.severityColor, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            a.severityTitle,
                            style: TextStyle(color: a.severityColor, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: Text(
                          a.alertTypeTitle,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "قبض: ${a.ticketSerial ?? a.ticketId ?? '-'}",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 11),
                          ),
                          if (a.ticketPlate != null && a.ticketPlate!.isNotEmpty)
                            IranianPlateWidget(plateDisplay: a.ticketPlate!, scale: 0.7),
                        ],
                      ),
                    ),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(a.productName ?? '-', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          Text(a.partyName ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    DataCell(Text(a.currentValue != null ? WeightFormatter.formatNumber(a.currentValue) : '-')),
                    DataCell(Text(a.baselineValue != null ? WeightFormatter.formatNumber(a.baselineValue) : '-')),
                    DataCell(
                      a.deviationPercent != null
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: a.severityColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "${a.deviationPercent!.toStringAsFixed(1)}٪",
                                style: TextStyle(color: a.severityColor, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            )
                          : const Text("-"),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: a.statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: a.statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          a.statusTitle,
                          style: TextStyle(color: a.statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    DataCell(Text(a.createdAtJalali ?? '-', style: const TextStyle(fontSize: 11))),
                    DataCell(
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          textStyle: const TextStyle(fontSize: 11),
                        ),
                        onPressed: () => _openDetailSheet(a),
                        child: const Text("مشاهده و اقدام"),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
