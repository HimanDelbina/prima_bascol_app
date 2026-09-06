import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/permissions.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/widgets/stat_card.dart';
import '../../auth/presentation/auth_providers.dart';
import 'dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final trendsAsync = ref.watch(dashboardTrendsProvider);
    final user = ref.watch(authControllerProvider).user;
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardSummaryProvider);
          ref.invalidate(dashboardTrendsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Quick Actions
              _buildHeader(context, user, theme),
              const SizedBox(height: AppDimensions.lg),

              // KPI Section
              summaryAsync.when(
                data: (summary) => _buildKpiGrid(context, summary),
                loading: () => ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 120),
                  child: const AppLoadingIndicator(message: "در حال دریافت شاخص‌های عملکرد امروز..."),
                ),
                error: (e, _) => AppErrorState(
                  message: "خطا در دریافت شاخص‌های داشبورد: $e",
                  onRetry: () => ref.refresh(dashboardSummaryProvider),
                ),
              ),
              const SizedBox(height: AppDimensions.xl),

              // Charts Section
              trendsAsync.when(
                data: (trends) => _buildChartsSection(context, trends, theme),
                loading: () => const SizedBox(
                  height: 280,
                  child: AppLoadingIndicator(message: "در حال بارگذاری نمودارهای تحلیلی..."),
                ),
                error: (e, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, user, ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 650;

        Widget buildTitleSection() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "داشبورد عملیات باسکول",
              style: (isCompact
                      ? theme.textTheme.titleLarge
                      : theme.textTheme.headlineMedium)
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "گزارش وضعیت و شاخص‌های آماری لحظه‌ای",
              style: theme.textTheme.bodyMedium,
            ),
          ],
        );

        Widget buildActionButtons() => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (user != null && user.hasPermission(AppPermissions.ticketCreate))
              ElevatedButton.icon(
                key: const ValueKey('btn_dashboard_ticket_create'),
                onPressed: () => context.go(AppRoutes.ticketCreate),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text("ثبت قبض جدید"),
              ),
            OutlinedButton.icon(
              key: const ValueKey('btn_dashboard_trucks_in_yard'),
              onPressed: () => context.go(AppRoutes.trucksInYard),
              icon: const Icon(Icons.local_shipping_outlined, size: 18),
              label: const Text("خودروهای داخل"),
            ),
          ],
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildTitleSection(),
              const SizedBox(height: 12),
              buildActionButtons(),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: buildTitleSection()),
            const SizedBox(width: 16),
            buildActionButtons(),
          ],
        );
      },
    );
  }

  Widget _buildKpiGrid(BuildContext context, summary) {
    final cards = [
      StatCard(
        title: "تعداد باسکول امروز",
        value: "${summary.todayTicketCount} قبض",
        subtitle: "${summary.todayCompletedCount} تکمیل شده",
        icon: Icons.receipt_long_rounded,
        iconColor: AppColors.primary,
        onTap: () => context.go(AppRoutes.tickets),
      ),
      StatCard(
        title: "تناژ کل امروز",
        value: WeightFormatter.formatTon(summary.todayNetWeight),
        subtitle: "${WeightFormatter.formatKg(summary.todayNetWeight)} خالص",
        icon: Icons.scale_rounded,
        iconColor: const Color(0xFF0F766E),
      ),
      StatCard(
        title: "ورودی / خروجی امروز",
        value: "${WeightFormatter.formatTon(summary.todayInboundWeight)} ورودی",
        subtitle: "${WeightFormatter.formatTon(summary.todayOutboundWeight)} خروجی",
        icon: Icons.swap_horiz_rounded,
        iconColor: const Color(0xFF0284C7),
      ),
      StatCard(
        title: "در انتظار وزن دوم",
        value: "${summary.waitingSecondWeight} ناوگان",
        subtitle: summary.todayDiscrepancies > 0 ? "${summary.todayDiscrepancies} مغایرت وزنی" : "بدون مغایرت",
        icon: Icons.hourglass_top_rounded,
        iconColor: summary.waitingSecondWeight > 5 ? Colors.redAccent : AppColors.statusWaitingSecond,
        onTap: () => context.go(AppRoutes.trucksInYard),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int count;
        final double aspectRatio;

        if (width < 540) {
          count = 1;
          aspectRatio = 2.8;
        } else if (width < 960) {
          count = 2;
          aspectRatio = 2.2;
        } else {
          count = 4;
          aspectRatio = 2.0;
        }

        return GridView.count(
          crossAxisCount: count,
          crossAxisSpacing: AppDimensions.md,
          mainAxisSpacing: AppDimensions.md,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: aspectRatio,
          children: cards,
        );
      },
    );
  }

  Widget _buildChartsSection(BuildContext context, trends, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "روند تناژ و تردد ۳۰ روز اخیر",
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppDimensions.md),
        AppCard(
          padding: const EdgeInsets.all(AppDimensions.lg),
          height: 320,
          child: trends.tonnage30.isEmpty
              ? const Center(child: Text("داده‌ای برای نمایش روند ۳۰ روز اخیر موجود نیست."))
              : LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 10,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: theme.dividerColor,
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 5,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx >= 0 && idx < trends.dates30.length) {
                              final parts = trends.dates30[idx].split('/');
                              final label = parts.length == 3 ? "${parts[1]}/${parts[2]}" : trends.dates30[idx];
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(label, style: const TextStyle(fontSize: 10)),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(
                          trends.tonnage30.length,
                          (i) => FlSpot(i.toDouble(), trends.tonnage30[i]),
                        ),
                        isCurved: true,
                        color: theme.colorScheme.primary,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: theme.colorScheme.primary.withOpacity(0.12),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
