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
import '../../../core/widgets/responsive_layout.dart';
import '../domain/party_analytics_models.dart';
import 'management_providers.dart';

class PartyRankingScreen extends ConsumerStatefulWidget {
  const PartyRankingScreen({super.key});

  @override
  ConsumerState<PartyRankingScreen> createState() => _PartyRankingScreenState();
}

class _PartyRankingScreenState extends ConsumerState<PartyRankingScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(partyRankingFilterProvider);
    final rankingAsync = ref.watch(partyRankingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "رتبه‌بندی و ارزیابی طرف‌های حساب",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            tooltip: "مقایسه چند طرف‌حساب",
            onPressed: () => context.push(AppRoutes.partyCompare),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "به‌روزرسانی داده‌ها",
            onPressed: () => ref.refresh(partyRankingProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(partyRankingProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppDimensions.paddingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFilterSection(context, filter, isDark),
              const SizedBox(height: AppDimensions.paddingMd),
              rankingAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: AppLoadingIndicator(message: "در حال محاسبه و رتبه‌بندی طرف‌های حساب..."),
                  ),
                ),
                error: (err, _) => AppErrorState(
                  message: err.toString(),
                  onRetry: () => ref.refresh(partyRankingProvider),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return AppEmptyState(
                      icon: Icons.leaderboard_outlined,
                      title: "هیچ طرف‌حسابی یافت نشد",
                      description: "با تغییر فیلترها یا کاهش شرط حداقل قبوض مجدداً بررسی کنید.",
                      actionText: "تنظیم مجدد فیلترها",
                      onAction: () {
                        _searchController.clear();
                        ref.read(partyRankingFilterProvider.notifier).state =
                            const PartyRankingFilter(minimumTickets: 0);
                      },
                    );
                  }

                  return ResponsiveLayout(
                    mobile: _buildMobileList(context, items, isDark),
                    tablet: _buildDesktopTable(context, items, isDark),
                    desktop: _buildDesktopTable(context, items, isDark),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context, PartyRankingFilter filter, bool isDark) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.paddingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Search & Compare action
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "جستجوی نام یا کد طرف‌حساب...",
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(partyRankingFilterProvider.notifier).update(
                                    (s) => s.copyWith(searchQuery: ''),
                                  );
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (val) {
                    ref.read(partyRankingFilterProvider.notifier).update(
                          (s) => s.copyWith(searchQuery: val),
                        );
                  },
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: () => context.push(AppRoutes.partyCompare),
                icon: const Icon(Icons.compare_arrows, size: 18),
                label: const Text("مقایسه", style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Quick Periods & Party Type Filter
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildPeriodChip("امروز", "today", filter.quickPeriod),
              _buildPeriodChip("هفته جاری", "this_week", filter.quickPeriod),
              _buildPeriodChip("ماه جاری", "this_month", filter.quickPeriod),
              _buildPeriodChip("سال جاری", "this_year", filter.quickPeriod),
              const SizedBox(width: 8),
              // Party Type Filter Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: filter.partyType,
                    isDense: true,
                    hint: const Text("همه انواع", style: TextStyle(fontSize: 12)),
                    items: const [
                      DropdownMenuItem(value: null, child: Text("همه انواع", style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: "supplier", child: Text("تأمین‌کنندگان", style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: "customer", child: Text("مشتریان", style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: "contractor", child: Text("پیمانکاران", style: TextStyle(fontSize: 12))),
                    ],
                    onChanged: (val) {
                      ref.read(partyRankingFilterProvider.notifier).update(
                            (s) => s.copyWith(partyType: val, clearPartyType: val == null),
                          );
                    },
                  ),
                ),
              ),
              // Ordering Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: filter.ordering,
                    isDense: true,
                    items: const [
                      DropdownMenuItem(value: "overall_score", child: Text("امتیاز کل", style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: "weight_accuracy", child: Text("دقت وزنی", style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: "loss_performance", child: Text("عملکرد افت", style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: "total_net_weight", child: Text("تناژ خالص", style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: "alert_rate", child: Text("کمترین هشدار", style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: "average_discrepancy", child: Text("کمترین اختلاف", style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: "average_turnaround", child: Text("سریع‌ترین توقف", style: TextStyle(fontSize: 12))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(partyRankingFilterProvider.notifier).update(
                              (s) => s.copyWith(ordering: val),
                            );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Minimum Tickets Fairness Notice
          Row(
            children: [
              const Icon(Icons.gavel_outlined, size: 14, color: AppColors.secondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "شرط رتبه‌بندی: حداقل ${filter.minimumTickets} قبض",
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () {
                  final nextMin = filter.minimumTickets == 20 ? 0 : 20;
                  ref.read(partyRankingFilterProvider.notifier).update(
                        (s) => s.copyWith(minimumTickets: nextMin),
                      );
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  filter.minimumTickets > 0 ? "نمایش همه" : "حداقل ۲۰ بار",
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value, String selectedValue) {
    final isSelected = (value == selectedValue);
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          ref.read(partyRankingFilterProvider.notifier).update(
                (s) => s.copyWith(quickPeriod: value),
              );
        }
      },
      selectedColor: AppColors.primary.withOpacity(0.15),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildMobileList(BuildContext context, List<PartyRankingItem> items, bool isDark) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) => _buildMobileCard(context, items[i], isDark),
    );
  }

  Widget _buildMobileCard(BuildContext context, PartyRankingItem item, bool isDark) {
    final scoreColor = item.scoreColor;
    final confColor = item.confidenceColor;

    Color rankBadgeColor = isDark ? Colors.white12 : Colors.grey.shade200;
    Color rankTextColor = isDark ? Colors.white : Colors.black87;
    if (item.rank == 1) {
      rankBadgeColor = const Color(0xFFFEF08A);
      rankTextColor = const Color(0xFF854D0E);
    } else if (item.rank == 2) {
      rankBadgeColor = const Color(0xFFE2E8F0);
      rankTextColor = const Color(0xFF334155);
    } else if (item.rank == 3) {
      rankBadgeColor = const Color(0xFFFFEDD5);
      rankTextColor = const Color(0xFF9A3412);
    }

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.paddingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Rank + Name + Type
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: rankBadgeColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "#${item.rank}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: rankTextColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.partyName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${item.partyTypeFa} ${item.partyCode != null ? '(${item.partyCode})' : ''}",
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              // Overall Score Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: scoreColor.withOpacity(0.4)),
                ),
                child: Column(
                  children: [
                    Text(
                      item.overallScore != null ? "${item.overallScore!.toStringAsFixed(1)}" : "ناکافی",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: scoreColor,
                      ),
                    ),
                    Text(
                      item.scoreLevelFa,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: scoreColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // Key metrics grid
          Row(
            children: [
              _buildMiniKpi("تعداد بار", "${item.completedTickets}", Icons.local_shipping_outlined, isDark),
              _buildMiniKpi("تناژ کل", CurrencyFormatter.formatTon(item.totalTonnage * 1000), Icons.scale_outlined, isDark),
              _buildMiniKpi("مغایرت متوسط", "${item.avgDiscrepancyKg} Kg", Icons.difference_outlined, isDark),
              _buildMiniKpi("نرخ هشدار", "${item.alertRate}%", Icons.warning_amber_outlined, isDark),
            ],
          ),
          const SizedBox(height: 12),

          // Footer: Confidence chip + Percentile + Action button
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: confColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_outlined, size: 13, color: confColor),
                        const SizedBox(width: 4),
                        Text(
                          "اطمینان: ${item.confidenceFa}",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: confColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "صدک: ${item.percentile}%",
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: () {
                  context.push(AppRoutes.partyDetailPath(item.partyId));
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.analytics_outlined, size: 14),
                label: const Text("مشاهده تحلیل", style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniKpi(String label, String value, IconData icon, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 15, color: isDark ? Colors.white54 : Colors.grey.shade600),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(BuildContext context, List<PartyRankingItem> items, bool isDark) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              isDark ? const Color(0xFF1E3A8A).withOpacity(0.25) : const Color(0xFF1E3A8A).withOpacity(0.08),
            ),
            dataRowMinHeight: 52,
            dataRowMaxHeight: 60,
            columnSpacing: 20,
            columns: const [
              DataColumn(label: Text("رتبه", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("طرف حساب", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("نوع", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("امتیاز کل", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("سطح کیفی", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("اطمینان", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("تعداد بار", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("تناژ خالص", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("مغایرت (Kg)", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("افت (%)", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("نرخ هشدار", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("زمان توقف", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("عملیات", style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: items.map((item) {
              final scoreColor = item.scoreColor;
              return DataRow(
                cells: [
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.rank <= 3 ? const Color(0xFFFEF08A) : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "#${item.rank}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: item.rank <= 3 ? const Color(0xFF854D0E) : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(item.partyName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        if (item.partyCode != null)
                          Text("کد: ${item.partyCode}", style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey)),
                      ],
                    ),
                  ),
                  DataCell(Text(item.partyTypeFa, style: const TextStyle(fontSize: 12))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: scoreColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.overallScore != null ? "${item.overallScore!.toStringAsFixed(1)} / 100" : "داده ناکافی",
                        style: TextStyle(fontWeight: FontWeight.bold, color: scoreColor, fontSize: 13),
                      ),
                    ),
                  ),
                  DataCell(Text(item.scoreLevelFa, style: TextStyle(fontWeight: FontWeight.w600, color: scoreColor, fontSize: 12))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.confidenceColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.confidenceFa,
                        style: TextStyle(fontSize: 11, color: item.confidenceColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  DataCell(Text("${item.completedTickets}")),
                  DataCell(Text(CurrencyFormatter.formatTon(item.totalTonnage * 1000))),
                  DataCell(Text("${item.avgDiscrepancyKg} Kg")),
                  DataCell(Text("${item.avgLossPercent}%")),
                  DataCell(Text("${item.alertRate}%")),
                  DataCell(Text("${item.avgTurnaroundMin} دقیقه")),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: AppColors.primary),
                      tooltip: "مشاهده کارنامه تحلیلی",
                      onPressed: () {
                        context.push(AppRoutes.partyDetailPath(item.partyId));
                      },
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
