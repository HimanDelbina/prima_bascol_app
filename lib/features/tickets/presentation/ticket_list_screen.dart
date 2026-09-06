import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/permissions.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/debouncer.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_date_picker_field.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/iranian_plate_widget.dart';
import '../../../core/widgets/mobile_record_card.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/presentation/auth_providers.dart';
import 'ticket_providers.dart';

class TicketListScreen extends ConsumerStatefulWidget {
  const TicketListScreen({super.key});

  @override
  ConsumerState<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends ConsumerState<TicketListScreen> {
  final _searchController = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 400);

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _openFilterDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLg)),
      ),
      builder: (ctx) => const _TicketFilterBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filterState = ref.watch(ticketFilterProvider);
    final ticketsAsync = ref.watch(ticketListFutureProvider);
    final user = ref.watch(authControllerProvider).user;
    final theme = Theme.of(context);
    final isMobile = ResponsiveLayout.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("قبوض باسکول"),
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
            tooltip: "بروزرسانی",
            onPressed: () => ref.refresh(ticketListFutureProvider),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("قبوض باسکول", style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("فهرست و جستجوی جامع اسناد توزین", style: theme.textTheme.bodyMedium),
                  ],
                ),
                if (user != null && user.hasPermission(AppPermissions.ticketCreate))
                  ElevatedButton.icon(
                    onPressed: () => context.go(AppRoutes.ticketCreate),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text("ثبت قبض جدید"),
                  ),
              ],
            ),
            const SizedBox(height: AppDimensions.md),

            // Search & Filter Bar
            AppCard(
              padding: const EdgeInsets.all(AppDimensions.sm),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: "جستجو با شماره قبض، پلاک، راننده، طرف حساب یا کالا...",
                        prefixIcon: Icon(Icons.search, size: 20),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      onChanged: (val) {
                        _debouncer.run(() {
                          ref.read(ticketFilterProvider.notifier).update(
                                (s) => s.copyWith(search: val, page: 1),
                              );
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _openFilterDrawer,
                    icon: const Icon(Icons.filter_list_rounded, size: 18),
                    label: Text(
                      filterState.activeFilterCount > 0
                          ? "فیلترها (${filterState.activeFilterCount})"
                          : "فیلترها",
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: "تازه‌سازی",
                    onPressed: () => ref.refresh(ticketListFutureProvider),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.md),

            // Data Content
            Expanded(
              child: ticketsAsync.when(
                data: (data) {
                  if (data.results.isEmpty) {
                    return AppEmptyState(
                      message: "هیچ قبضی مطابق با جستجو یا فیلترهای اعمال‌شده یافت نشد.",
                      actionText: "پاکسازی فیلترها",
                      onAction: () {
                        _searchController.clear();
                        ref.read(ticketFilterProvider.notifier).state = const TicketFilterState();
                      },
                    );
                  }

                  if (isMobile) {
                    return _buildMobileList(data.results);
                  } else {
                    return _buildDesktopTable(data.results, data.count, filterState.page);
                  }
                },
                loading: () => const AppLoadingIndicator(message: "در حال دریافت اطلاعات قبوض باسکول..."),
                error: (e, _) => AppErrorState(
                  message: "خطا در برقراری ارتباط: $e",
                  onRetry: () => ref.refresh(ticketListFutureProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTable(List items, int totalCount, int currentPage) {
    final theme = Theme.of(context);
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text("شماره قبض")),
                    DataColumn(label: Text("وضعیت")),
                    DataColumn(label: Text("پلاک خودرو")),
                    DataColumn(label: Text("طرف حساب")),
                    DataColumn(label: Text("کالا")),
                    DataColumn(label: Text("راننده")),
                    DataColumn(label: Text("وزن ناخالص")),
                    DataColumn(label: Text("وزن تارا")),
                    DataColumn(label: Text("وزن خالص")),
                    DataColumn(label: Text("تاریخ")),
                    DataColumn(label: Text("عملیات")),
                  ],
                  rows: items.map((ticket) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                ticket.serialNumber,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                              if (ticket.openAlertsCount > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade800,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    "⚠️ ${ticket.openAlertsCount}",
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        DataCell(StatusBadge(code: ticket.status.code, label: ticket.status.label)),
                        DataCell(IranianPlateWidget(plateDisplay: ticket.licensePlateDisplay, scale: 0.85)),
                        DataCell(Text(ticket.partyName ?? "-")),
                        DataCell(Text(ticket.productName ?? "-")),
                        DataCell(Text(ticket.driverName ?? "-")),
                        DataCell(Text(WeightFormatter.formatKg(ticket.grossWeight))),
                        DataCell(Text(WeightFormatter.formatKg(ticket.tareWeight))),
                        DataCell(
                          Text(
                            WeightFormatter.formatKg(ticket.netWeight),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataCell(Text(ticket.firstWeightDateJalali ?? ticket.createdAtJalali ?? "-")),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                            onPressed: () => context.go(AppRoutes.ticketDetailPath(ticket.id)),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          // Pagination Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("مجموع: $totalCount رکورد", style: theme.textTheme.bodySmall),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: currentPage > 1
                          ? () => ref.read(ticketFilterProvider.notifier).update((s) => s.copyWith(page: currentPage - 1))
                          : null,
                    ),
                    Text("صفحه $currentPage"),
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: items.length >= 25
                          ? () => ref.read(ticketFilterProvider.notifier).update((s) => s.copyWith(page: currentPage + 1))
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList(List items) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final t = items[i];
        return MobileRecordCard(
          title: t.openAlertsCount > 0
              ? "قبض ${t.serialNumber} (⚠️ ${t.openAlertsCount})"
              : "قبض شماره ${t.serialNumber}",
          badge: StatusBadge(code: t.status.code, label: t.status.label),
          onTap: () => context.go(AppRoutes.ticketDetailPath(t.id)),
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
                Text(t.partyName ?? "-", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("محصول:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(t.productName ?? "-", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("وزن خالص:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(
                  WeightFormatter.formatKg(t.netWeight),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _TicketFilterBottomSheet extends ConsumerStatefulWidget {
  const _TicketFilterBottomSheet();

  @override
  ConsumerState<_TicketFilterBottomSheet> createState() => _TicketFilterBottomSheetState();
}

class _TicketFilterBottomSheetState extends ConsumerState<_TicketFilterBottomSheet> {
  String? _status;
  String? _startDate;
  String? _endDate;

  @override
  void initState() {
    super.initState();
    final f = ref.read(ticketFilterProvider);
    _status = f.status;
    _startDate = f.startDateJalali;
    _endDate = f.endDateJalali;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: AppDimensions.lg,
        left: AppDimensions.lg,
        right: AppDimensions.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppDimensions.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("فیلترهای پیشرفته قبوض", style: Theme.of(context).textTheme.headlineSmall),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          DropdownButtonFormField<String>(
            value: _status,
            decoration: const InputDecoration(labelText: "وضعیت سند"),
            items: const [
              DropdownMenuItem(value: null, child: Text("همه وضعیت‌ها")),
              DropdownMenuItem(value: "draft", child: Text("پیش‌نویس")),
              DropdownMenuItem(value: "waiting_first", child: Text("در انتظار وزن اول")),
              DropdownMenuItem(value: "waiting_second", child: Text("در انتظار وزن دوم")),
              DropdownMenuItem(value: "completed", child: Text("تکمیل‌شده")),
              DropdownMenuItem(value: "cancelled", child: Text("ابطال‌شده")),
            ],
            onChanged: (val) => setState(() => _status = val),
          ),
          const SizedBox(height: AppDimensions.md),
          Row(
            children: [
              Expanded(
                child: AppDatePickerField(
                  label: "از تاریخ",
                  jalaliValue: _startDate,
                  onDateSelected: (d) => setState(() => _startDate = d),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppDatePickerField(
                  label: "تا تاریخ",
                  jalaliValue: _endDate,
                  onDateSelected: (d) => setState(() => _endDate = d),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.xl),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(ticketFilterProvider.notifier).state = const TicketFilterState();
                    Navigator.pop(context);
                  },
                  child: const Text("پاکسازی"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(ticketFilterProvider.notifier).update(
                          (s) => s.copyWith(
                            status: _status,
                            startDateJalali: _startDate,
                            endDateJalali: _endDate,
                            page: 1,
                            clearStatus: _status == null,
                            clearDates: _startDate == null && _endDate == null,
                          ),
                        );
                    Navigator.pop(context);
                  },
                  child: const Text("اعمال فیلترها"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
