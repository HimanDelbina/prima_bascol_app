import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/services/file_export_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_date_picker_field.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/iranian_plate_widget.dart';
import '../../../core/widgets/mobile_record_card.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../tickets/domain/ticket_models.dart';
import '../domain/report_models.dart';
import 'reports_providers.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _activeTabIndex = 0; // 0: گزارش تحلیلی و تفکیکی, 1: ریز قبوض و اسناد
  String _groupBy = 'product';
  String? _startDate;
  String? _endDate;
  String? _status;
  bool _isExporting = false;

  void _applyFilter() {
    ref.read(reportFilterProvider.notifier).state = ReportFilterState(
      groupBy: _groupBy,
      startDateJalali: _startDate,
      endDateJalali: _endDate,
      status: _status,
    );
  }

  void _resetFilter() {
    setState(() {
      _groupBy = 'product';
      _startDate = null;
      _endDate = null;
      _status = null;
    });
    ref.read(reportFilterProvider.notifier).state = const ReportFilterState();
  }

  Future<void> _exportReport({required bool isPdf}) async {
    if (_isExporting) return;

    setState(() => _isExporting = true);

    final formatName = isPdf ? "PDF" : "اکسل";
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text("در حال دریافت و آماده‌سازی فایل $formatName..."),
          ],
        ),
        backgroundColor: AppColors.info,
        duration: const Duration(seconds: 4),
      ),
    );

    try {
      final filter = ref.read(reportFilterProvider);
      final params = filter.toParams();
      final endpoint = isPdf ? ApiEndpoints.reportExportPdf : ApiEndpoints.reportExportXlsx;
      final defaultFileName = isPdf ? 'گزارش_قبوض_باسکول.pdf' : 'گزارش_قبوض_باسکول.xlsx';

      final service = ref.read(fileExportServiceProvider);
      final resultMsg = await service.exportAndOpenFile(
        endpoint: endpoint,
        defaultFileName: defaultFileName,
        queryParameters: params,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultMsg),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e, st) {
      debugPrint("[ReportsScreen] Export error: $e\n$st");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("خطا در صدور گزارش: ${e.toString()}"),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(reportSummaryProvider);
    final groupedAsync = ref.watch(reportGroupedProvider);
    final ticketsAsync = ref.watch(reportTicketsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          ResponsiveLayout.isMobile(context)
              ? "گزارشات تجمیعی"
              : "گزارشات تحلیلی و تجمیعی",
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
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "بروزرسانی داده‌ها",
            onPressed: () {
              ref.invalidate(reportSummaryProvider);
              ref.invalidate(reportGroupedProvider);
              ref.invalidate(reportTicketsProvider);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Filter Card
            AppCard(
              padding: const EdgeInsets.all(AppDimensions.paddingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.filter_alt_outlined, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text("فیلترهای گزارش", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Date From
                      SizedBox(
                        width: ResponsiveLayout.isMobile(context) ? double.infinity : 180,
                        child: AppDatePickerField(
                          label: "از تاریخ",
                          initialValueJalali: _startDate,
                          onDateSelected: (val) => setState(() => _startDate = val),
                        ),
                      ),
                      // Date To
                      SizedBox(
                        width: ResponsiveLayout.isMobile(context) ? double.infinity : 180,
                        child: AppDatePickerField(
                          label: "تا تاریخ",
                          initialValueJalali: _endDate,
                          onDateSelected: (val) => setState(() => _endDate = val),
                        ),
                      ),
                      // Status Dropdown
                      SizedBox(
                        width: ResponsiveLayout.isMobile(context) ? double.infinity : 180,
                        child: DropdownButtonFormField<String?>(
                          isExpanded: true,
                          value: _status,
                          decoration: const InputDecoration(labelText: "وضعیت سند"),
                          items: const [
                            DropdownMenuItem(value: null, child: Text("همه وضعیت‌ها")),
                            DropdownMenuItem(value: 'completed', child: Text("تکمیل‌شده")),
                            DropdownMenuItem(value: 'waiting_second', child: Text("در انتظار وزن دوم")),
                            DropdownMenuItem(value: 'draft', child: Text("پیش‌نویس")),
                            DropdownMenuItem(value: 'cancelled', child: Text("ابطال‌شده")),
                          ],
                          onChanged: (val) {
                            setState(() => _status = val);
                          },
                        ),
                      ),
                      // Group By Dropdown (only visible or active for grouped mode)
                      if (_activeTabIndex == 0)
                        SizedBox(
                          width: ResponsiveLayout.isMobile(context) ? double.infinity : 180,
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _groupBy,
                            decoration: const InputDecoration(labelText: "دسته‌بندی بر اساس"),
                            items: const [
                              DropdownMenuItem(value: 'product', child: Text("کالاها")),
                              DropdownMenuItem(value: 'party', child: Text("طرف‌های حساب")),
                              DropdownMenuItem(value: 'driver', child: Text("رانندگان")),
                              DropdownMenuItem(value: 'vehicle', child: Text("ناوگان")),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _groupBy = val);
                            },
                          ),
                        ),
                      // Action Buttons
                      if (ResponsiveLayout.isMobile(context))
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _applyFilter,
                                icon: const Icon(Icons.search, size: 18),
                                label: const Text("اعمال فیلتر"),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _resetFilter,
                                icon: const Icon(Icons.clear_all, size: 18),
                                label: const Text("حذف فیلترها"),
                              ),
                            ),
                          ],
                        )
                      else ...[
                        ElevatedButton.icon(
                          onPressed: _applyFilter,
                          icon: const Icon(Icons.search, size: 18),
                          label: const Text("اعمال فیلتر"),
                        ),
                        OutlinedButton.icon(
                          onPressed: _resetFilter,
                          icon: const Icon(Icons.clear_all, size: 18),
                          label: const Text("حذف فیلترها"),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Summary KPIs
            summaryAsync.when(
              loading: () => const AppLoadingIndicator(message: "در حال محاسبه آمار قبوض..."),
              error: (err, _) => AppErrorState(message: err.toString(), onRetry: () => ref.refresh(reportSummaryProvider)),
              data: (summary) => _buildSummaryKpis(summary),
            ),
            const SizedBox(height: 16),

            // View Mode Selector Segmented Tabs
            Center(
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 0,
                    label: Text("گزارش تحلیلی و تجمیعی"),
                    icon: Icon(Icons.pie_chart_outline_rounded),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text("ریز قبوض و اسناد"),
                    icon: Icon(Icons.receipt_long_rounded),
                  ),
                ],
                selected: {_activeTabIndex},
                onSelectionChanged: (newSelection) {
                  setState(() => _activeTabIndex = newSelection.first);
                },
              ),
            ),
            const SizedBox(height: 16),

            // Main Content Area based on Selected Tab
            if (_activeTabIndex == 0)
              // Tab 0: Grouped Breakdown Table
              AppCard(
                padding: const EdgeInsets.all(AppDimensions.paddingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ResponsiveLayout.isMobile(context))
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "گزارش تفکیکی بر اساس ${_getGroupTitle()}",
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isExporting ? null : () => _exportReport(isPdf: false),
                                  icon: const Icon(Icons.table_view_rounded, size: 16),
                                  label: const Text("خروجی اکسل"),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isExporting ? null : () => _exportReport(isPdf: true),
                                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                                  label: const Text("چاپ PDF"),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "گزارش تفکیکی بر اساس ${_getGroupTitle()}",
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: _isExporting ? null : () => _exportReport(isPdf: false),
                                icon: const Icon(Icons.table_view_rounded, size: 16),
                                label: const Text("خروجی اکسل"),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: _isExporting ? null : () => _exportReport(isPdf: true),
                                icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                                label: const Text("چاپ PDF"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    groupedAsync.when(
                      loading: () => const AppLoadingIndicator(message: "در حال تجمیع داده‌ها..."),
                      error: (err, _) => AppErrorState(
                        message: err.toString(),
                        onRetry: () => ref.refresh(reportGroupedProvider),
                      ),
                      data: (items) {
                        if (items.isEmpty) {
                          return const AppEmptyState(
                            icon: Icons.bar_chart_outlined,
                            title: "داده‌ای برای نمایش وجود ندارد",
                            description: "با تغییر بازه تاریخی یا فیلترها مجدداً تلاش کنید.",
                          );
                        }
                        return _buildGroupedList(items);
                      },
                    ),
                  ],
                ),
              )
            else
              // Tab 1: Detailed Tickets List
              AppCard(
                padding: const EdgeInsets.all(AppDimensions.paddingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ResponsiveLayout.isMobile(context))
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "ریز اسناد و قبوض ثبت‌شده",
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isExporting ? null : () => _exportReport(isPdf: false),
                                  icon: const Icon(Icons.table_view_rounded, size: 16),
                                  label: const Text("خروجی اکسل"),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isExporting ? null : () => _exportReport(isPdf: true),
                                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                                  label: const Text("چاپ PDF"),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "ریز اسناد و قبوض ثبت‌شده",
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: _isExporting ? null : () => _exportReport(isPdf: false),
                                icon: const Icon(Icons.table_view_rounded, size: 16),
                                label: const Text("خروجی اکسل"),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: _isExporting ? null : () => _exportReport(isPdf: true),
                                icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                                label: const Text("چاپ PDF"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    ticketsAsync.when(
                      loading: () => const AppLoadingIndicator(message: "در حال دریافت لیست اسناد..."),
                      error: (err, _) => AppErrorState(
                        message: err.toString(),
                        onRetry: () => ref.refresh(reportTicketsProvider),
                      ),
                      data: (tickets) {
                        if (tickets.isEmpty) {
                          return const AppEmptyState(
                            icon: Icons.receipt_long_outlined,
                            title: "هیچ قبضی در این بازه یافت نشد",
                            description: "فیلترهای تاریخ یا وضعیت را تغییر دهید یا دکمه بروزرسانی را بزنید.",
                          );
                        }
                        if (ResponsiveLayout.isMobile(context)) {
                          return _buildTicketsMobileList(tickets);
                        } else {
                          return _buildTicketsDesktopTable(tickets);
                        }
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getGroupTitle() {
    switch (_groupBy) {
      case 'party':
        return "طرف حساب";
      case 'driver':
        return "راننده";
      case 'vehicle':
        return "ناوگان";
      case 'product':
      default:
        return "کالا";
    }
  }

  Widget _buildSummaryKpis(ReportSummaryModel summary) {
    return ResponsiveLayout(
      mobile: Column(
        children: [
          StatCard(
            title: "تعداد کل سرویس‌ها",
            value: "${summary.totalTickets} قبض",
            icon: Icons.receipt_long_rounded,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          StatCard(
            title: "وزن ناخالص کل",
            value: CurrencyFormatter.formatWeight(summary.totalGrossWeight),
            icon: Icons.scale_rounded,
            color: AppColors.info,
          ),
          const SizedBox(height: 12),
          StatCard(
            title: "وزن خالص کل",
            value: CurrencyFormatter.formatWeight(summary.totalNetWeight),
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.success,
          ),
          const SizedBox(height: 12),
          StatCard(
            title: "مجموع افت وزنی",
            value: CurrencyFormatter.formatWeight(summary.totalLossWeight),
            icon: Icons.trending_down_rounded,
            color: AppColors.warning,
          ),
          const SizedBox(height: 12),
          StatCard(
            title: "وزن نهایی قابل تسویه",
            value: CurrencyFormatter.formatWeight(summary.totalFinalWeight),
            icon: Icons.verified_outlined,
            color: AppColors.secondary,
          ),
        ],
      ),
      desktop: Row(
        children: [
          Expanded(
            child: StatCard(
              title: "تعداد کل سرویس‌ها",
              value: "${summary.totalTickets} قبض",
              icon: Icons.receipt_long_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              title: "وزن ناخالص کل",
              value: CurrencyFormatter.formatWeight(summary.totalGrossWeight),
              icon: Icons.scale_rounded,
              color: AppColors.info,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              title: "وزن خالص کل",
              value: CurrencyFormatter.formatWeight(summary.totalNetWeight),
              icon: Icons.check_circle_outline_rounded,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              title: "مجموع افت وزنی",
              value: CurrencyFormatter.formatWeight(summary.totalLossWeight),
              icon: Icons.trending_down_rounded,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              title: "وزن نهایی قابل تسویه",
              value: CurrencyFormatter.formatWeight(summary.totalFinalWeight),
              icon: Icons.verified_outlined,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketsMobileList(List<WeighTicketListModel> tickets) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tickets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final t = tickets[i];
        return MobileRecordCard(
          title: "قبض سریال ${t.serialNumber}",
          badge: StatusBadge(code: t.status.code, label: t.status.label),
          onTap: () => context.push(AppRoutes.ticketDetailPath(t.id)),
          rows: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("پلاک خودرو:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                IranianPlateWidget(plateDisplay: t.licensePlateDisplay, scale: 0.8),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("طرف حساب:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                Expanded(
                  child: Text(
                    t.partyName ?? "-",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("محصول:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                Expanded(
                  child: Text(
                    t.productName ?? "-",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("وزن خالص:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(
                  CurrencyFormatter.formatWeight(t.netWeight),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                ),
              ],
            ),
            if (t.firstWeightDateJalali != null) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("تاریخ ثبت:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(t.firstWeightDateJalali!, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildTicketsDesktopTable(List<WeighTicketListModel> tickets) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text("شماره قبض")),
          DataColumn(label: Text("پلاک خودرو")),
          DataColumn(label: Text("طرف حساب")),
          DataColumn(label: Text("محصول")),
          DataColumn(label: Text("وزن ناخالص")),
          DataColumn(label: Text("وزن خالص")),
          DataColumn(label: Text("تاریخ")),
          DataColumn(label: Text("وضعیت")),
          DataColumn(label: Text("عملیات")),
        ],
        rows: tickets.map((t) {
          return DataRow(
            cells: [
              DataCell(Text(t.serialNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(IranianPlateWidget(plateDisplay: t.licensePlateDisplay, scale: 0.7)),
              DataCell(Text(t.partyName ?? "-")),
              DataCell(Text(t.productName ?? "-")),
              DataCell(Text(CurrencyFormatter.formatWeight(t.grossWeight))),
              DataCell(Text(CurrencyFormatter.formatWeight(t.netWeight), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))),
              DataCell(Text(t.firstWeightDateJalali ?? "-")),
              DataCell(StatusBadge(code: t.status.code, label: t.status.label)),
              DataCell(
                IconButton(
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  tooltip: "مشاهده جزئیات قبض",
                  onPressed: () => context.push(AppRoutes.ticketDetailPath(t.id)),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGroupedList(List<GroupedReportItem> items) {
    final double maxNet = items.map((e) => e.totalNetWeight > 0 ? e.totalNetWeight : e.totalGrossWeight).fold(0.0, (a, b) => a > b ? a : b);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final item = items[i];
        final displayWeight = item.totalNetWeight > 0 ? item.totalNetWeight : item.totalGrossWeight;
        final isWaitingSecond = item.totalNetWeight == 0 && item.totalGrossWeight > 0;
        final ratio = maxNet > 0 ? (displayWeight / maxNet) : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: (isWaitingSecond ? AppColors.warning : AppColors.primary).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            "${i + 1}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isWaitingSecond ? AppColors.warning : AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.groupTitle,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (isWaitingSecond)
                                const Text(
                                  "قبض در انتظار وزن دوم (خالص پس از توزین دوم ثبت می‌شود)",
                                  style: TextStyle(fontSize: 11, color: AppColors.warning),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.formatWeight(displayWeight),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isWaitingSecond ? AppColors.warning : AppColors.primary,
                        ),
                      ),
                      if (isWaitingSecond)
                        const Text("وزن اول", style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: Colors.grey.withValues(alpha: 0.15),
                  color: isWaitingSecond ? AppColors.warning : AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Text("تعداد سرویس: ${item.count} بار", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(
                    "میانگین هر سرویس: ${CurrencyFormatter.formatWeight(item.averageNetWeight)}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (item.totalLossWeight > 0)
                    Text("افت وزنی: ${CurrencyFormatter.formatWeight(item.totalLossWeight)}", style: const TextStyle(fontSize: 12, color: AppColors.warning)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
