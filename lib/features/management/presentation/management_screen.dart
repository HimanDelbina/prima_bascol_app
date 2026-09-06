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
import '../domain/management_models.dart';
import 'management_providers.dart';

class ManagementScreen extends ConsumerWidget {
  const ManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(managementFilterProvider);
    final summaryAsync = ref.watch(managementSummaryProvider);
    final productsAsync = ref.watch(managementProductsProvider);
    final partiesAsync = ref.watch(managementPartiesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCustom = filter.quickPeriod == 'custom';

    final periodOptions = [
      {'id': 'today', 'label': 'امروز'},
      {'id': 'this_week', 'label': 'هفته جاری'},
      {'id': 'this_month', 'label': 'ماه جاری'},
      {'id': 'last_month', 'label': 'ماه گذشته'},
      {'id': 'this_year', 'label': 'سال جاری'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("داشبورد هوش تجاری و مدیریتی (BI)"),
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
            onPressed: () {
              ref.refresh(managementSummaryProvider);
              ref.refresh(managementProductsProvider);
              ref.refresh(managementPartiesProvider);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Period Selector
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.calendar_month_outlined, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      const Padding(
                        padding: EdgeInsets.only(top: 6.0),
                        child: Text("بازه گزارش: ", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...periodOptions.map((opt) {
                              final isSelected = !isCustom && opt['id'] == filter.quickPeriod;
                              return ChoiceChip(
                                label: Text(opt['label']!),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    ref.read(selectedPeriodProvider.notifier).state = opt['id']!;
                                    ref.read(managementFilterProvider.notifier).state =
                                        ManagementFilterState(quickPeriod: opt['id']!);
                                  }
                                },
                              );
                            }),
                            ChoiceChip(
                              avatar: const Icon(Icons.date_range, size: 16),
                              label: Text(
                                isCustom && filter.startDateJalali != null
                                    ? "${filter.startDateJalali} تا ${filter.endDateJalali ?? 'امروز'}"
                                    : "بازه تاریخ دلخواه...",
                                style: const TextStyle(fontSize: 12),
                              ),
                              selected: isCustom,
                              onSelected: (_) => _showCustomDateDialog(context, ref),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  summaryAsync.whenOrNull(
                    data: (summary) {
                      if (summary.startDateJalali != null && summary.endDateJalali != null) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0, right: 36.0),
                          child: Text(
                            "بازه محاسباتی سامانه: از ${summary.startDateJalali} تا ${summary.endDateJalali}",
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
                          ),
                        );
                      }
                      return null;
                    },
                  ) ?? const SizedBox.shrink(),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Summary Section
            summaryAsync.when(
              loading: () => const AppLoadingIndicator(message: "در حال استخراج شاخص‌های مدیریتی..."),
              error: (err, _) => AppErrorState(
                message: err.toString(),
                onRetry: () => ref.refresh(managementSummaryProvider),
              ),
              data: (summary) => Column(
                children: [
                  // Executive Narrative
                  if (summary.executiveNarrative != null && summary.executiveNarrative!.isNotEmpty) ...[
                    AppCard(
                      padding: const EdgeInsets.all(AppDimensions.paddingMd),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                            ),
                            child: Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "تحلیل هوشمند مدیریتی (Executive Narrative)",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.colorScheme.primary),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  summary.executiveNarrative!,
                                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // KPI Comparison Cards
                  ResponsiveLayout(
                    mobile: Column(
                      children: [
                        _buildKpiCard(
                          title: "تناژ ناخالص/خالص دوره",
                          value: CurrencyFormatter.formatTon(summary.totalTonnage * 1000),
                          pctChange: summary.tonnageChangePct,
                          icon: Icons.scale_rounded,
                        ),
                        const SizedBox(height: 12),
                        _buildKpiCard(
                          title: "تعداد کل تردد و سرویس‌ها",
                          value: "${summary.totalServices} سرویس",
                          pctChange: summary.servicesChangePct,
                          icon: Icons.local_shipping_rounded,
                        ),
                        const SizedBox(height: 12),
                        _buildSimpleKpi(
                          title: "میانگین زمان توقف ناوگان",
                          value: "${summary.averageTurnaroundMinutes.toStringAsFixed(0)} دقیقه",
                          icon: Icons.timer_outlined,
                          color: Colors.blueGrey,
                        ),
                        const SizedBox(height: 12),
                        _buildSimpleKpi(
                          title: "مغایرت با بارنامه / افت",
                          value: CurrencyFormatter.formatTon((summary.totalDiscrepancyTonnage + summary.totalLossTonnage) * 1000),
                          icon: Icons.warning_amber_rounded,
                          color: AppColors.warning,
                        ),
                      ],
                    ),
                    desktop: Row(
                      children: [
                        Expanded(
                          child: _buildKpiCard(
                            title: "تناژ خالص دوره",
                            value: CurrencyFormatter.formatTon(summary.totalTonnage * 1000),
                            pctChange: summary.tonnageChangePct,
                            icon: Icons.scale_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildKpiCard(
                            title: "تعداد کل تردد و سرویس‌ها",
                            value: "${summary.totalServices} سرویس",
                            pctChange: summary.servicesChangePct,
                            icon: Icons.local_shipping_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSimpleKpi(
                            title: "میانگین زمان توقف ناوگان",
                            value: "${summary.averageTurnaroundMinutes.toStringAsFixed(0)} دقیقه",
                            icon: Icons.timer_outlined,
                            color: Colors.blueGrey,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSimpleKpi(
                            title: "مغایرت با بارنامه / افت",
                            value: CurrencyFormatter.formatTon((summary.totalDiscrepancyTonnage + summary.totalLossTonnage) * 1000),
                            icon: Icons.warning_amber_rounded,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Phase 4: Party Analytics & Scoring Banner
            AppCard(
              padding: const EdgeInsets.all(16),
              child: ResponsiveLayout(
                mobile: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.leaderboard_outlined, color: AppColors.primary, size: 28),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "تحلیل و رتبه‌بندی طرف‌های حساب",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "ارزیابی قاعده‌محور دقت وزنی، افت کالا، ثبات، هشدارهای پایش و بهره‌وری عملیاتی",
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => context.push(AppRoutes.partyRanking),
                      icon: const Icon(Icons.assessment_outlined, size: 18),
                      label: const Text("مشاهده رتبه‌بندی", style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
                desktop: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.leaderboard_outlined, color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "تحلیل، رتبه‌بندی و امتیازدهی طرف‌های حساب (فاز ۴)",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "ارزیابی قاعده‌محور دقت وزنی، افت کالا، ثبات، هشدارهای پایش و بهره‌وری عملیاتی",
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: () => context.push(AppRoutes.partyRanking),
                      icon: const Icon(Icons.assessment_outlined, size: 18),
                      label: const Text("مشاهده رتبه‌بندی", style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Breakdowns: Products & Parties
            ResponsiveLayout(
              mobile: Column(
                children: [
                  _buildProductsBreakdownCard(context, productsAsync, ref),
                  const SizedBox(height: 16),
                  _buildPartiesBreakdownCard(context, partiesAsync, ref),
                ],
              ),
              desktop: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildProductsBreakdownCard(context, productsAsync, ref)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildPartiesBreakdownCard(context, partiesAsync, ref)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required double pctChange,
    required IconData icon,
  }) {
    final isPositive = pctChange >= 0;
    final color = isPositive ? AppColors.success : AppColors.error;

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.paddingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
              Icon(icon, color: AppColors.primaryLight, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(isPositive ? Icons.trending_up : Icons.trending_down, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                "${pctChange.abs().toStringAsFixed(1)}% نسبت به دوره قبل",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleKpi({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.paddingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text("شاخص بهره‌وری و کنترل ریسک", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildProductsBreakdownCard(BuildContext context, AsyncValue<List<ManagementBreakdownItem>> asyncData, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF60A5FA) : AppColors.primary;

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.paddingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: primaryColor),
              const SizedBox(width: 8),
              const Text("سهم کالاهای برتر", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          asyncData.when(
            loading: () => const AppLoadingIndicator(message: "در حال بارگذاری کالاها..."),
            error: (e, _) => AppErrorState(message: e.toString(), onRetry: () => ref.refresh(managementProductsProvider)),
            data: (items) {
              if (items.isEmpty) return const AppEmptyState(icon: Icons.inventory_2_outlined, title: "داده‌ای یافت نشد", description: "");
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final p = items[i];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            "${CurrencyFormatter.formatTon(p.tonnage * 1000)} (${p.sharePercentage.toStringAsFixed(1)}%)",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (p.sharePercentage / 100).clamp(0.0, 1.0),
                          minHeight: 8,
                          color: primaryColor,
                          backgroundColor: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.15),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPartiesBreakdownCard(BuildContext context, AsyncValue<List<ManagementBreakdownItem>> asyncData, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryColor = isDark ? const Color(0xFF2DD4BF) : AppColors.secondary;

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.paddingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.business_outlined, color: secondaryColor),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "طرف‌های حساب پرتردد",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => context.push(AppRoutes.partyRanking),
                icon: const Icon(Icons.analytics_outlined, size: 16),
                label: const Text("رتبه‌بندی و ارزیابی", style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          asyncData.when(
            loading: () => const AppLoadingIndicator(message: "در حال بارگذاری طرف‌های حساب..."),
            error: (e, _) => AppErrorState(message: e.toString(), onRetry: () => ref.refresh(managementPartiesProvider)),
            data: (items) {
              if (items.isEmpty) return const AppEmptyState(icon: Icons.business_outlined, title: "داده‌ای یافت نشد", description: "");
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final p = items[i];
                  return InkWell(
                    onTap: () {
                      if (p.id != null) {
                        context.push(AppRoutes.partyDetailPath(p.id!));
                      } else {
                        context.push(AppRoutes.partyRanking);
                      }
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.chevron_left, size: 16, color: Colors.grey),
                                ],
                              ),
                              Text(
                                "${p.count} بار (${CurrencyFormatter.formatTon(p.tonnage * 1000)})",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: secondaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (p.sharePercentage / 100).clamp(0.0, 1.0),
                              minHeight: 8,
                              color: secondaryColor,
                              backgroundColor: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _showCustomDateDialog(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.read(managementFilterProvider);
    final startCtrl = TextEditingController(text: currentFilter.startDateJalali ?? '');
    final endCtrl = TextEditingController(text: currentFilter.endDateJalali ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.date_range, color: AppColors.primary),
            SizedBox(width: 8),
            Text("انتخاب بازه تاریخ شمسی", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: startCtrl,
              decoration: const InputDecoration(
                labelText: "تاریخ شروع شمسی",
                hintText: "مثال: 1405/06/01",
                prefixIcon: Icon(Icons.calendar_today, size: 18),
              ),
              keyboardType: TextInputType.datetime,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: endCtrl,
              decoration: const InputDecoration(
                labelText: "تاریخ پایان شمسی",
                hintText: "مثال: 1405/06/31",
                prefixIcon: Icon(Icons.event, size: 18),
              ),
              keyboardType: TextInputType.datetime,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("انصراف"),
          ),
          ElevatedButton(
            onPressed: () {
              final start = startCtrl.text.trim();
              final end = endCtrl.text.trim();
              if (start.isNotEmpty) {
                ref.read(managementFilterProvider.notifier).state = ManagementFilterState(
                  quickPeriod: 'custom',
                  startDateJalali: start,
                  endDateJalali: end.isNotEmpty ? end : null,
                );
              }
              Navigator.pop(ctx);
            },
            child: const Text("اعمال فیلتر"),
          ),
        ],
      ),
    );
  }
}
