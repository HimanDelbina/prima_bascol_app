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

class PartyDetailAnalyticsScreen extends ConsumerWidget {
  final int partyId;

  const PartyDetailAnalyticsScreen({super.key, required this.partyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(partyAnalyticsDetailProvider(partyId));
    final trendAsync = ref.watch(partyTrendProvider(partyId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "کارنامه تحلیلی و امتیاز طرف‌حساب",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "به‌روزرسانی",
            onPressed: () {
              ref.refresh(partyAnalyticsDetailProvider(partyId));
              ref.refresh(partyTrendProvider(partyId));
            },
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(
          child: AppLoadingIndicator(message: "در حال محاسبه و استخراج کارنامه تحلیلی..."),
        ),
        error: (err, _) => AppErrorState(
          message: err.toString(),
          onRetry: () => ref.refresh(partyAnalyticsDetailProvider(partyId)),
        ),
        data: (data) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.refresh(partyAnalyticsDetailProvider(partyId));
              ref.refresh(partyTrendProvider(partyId));
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingMd),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderCard(context, data, isDark),
                  const SizedBox(height: AppDimensions.paddingMd),
                  if (!data.score.isScoreReliable) ...[
                    _buildInsufficientDataWarning(context, data.score),
                    const SizedBox(height: AppDimensions.paddingMd),
                  ],
                  _buildKpiGrid(context, data, isDark),
                  const SizedBox(height: AppDimensions.paddingMd),
                  ResponsiveLayout(
                    mobile: Column(
                      children: [
                        _buildScoreBreakdownCard(context, data.score, isDark),
                        const SizedBox(height: AppDimensions.paddingMd),
                        _buildExplanationCard(context, data.score.explanation, isDark),
                      ],
                    ),
                    tablet: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildScoreBreakdownCard(context, data.score, isDark)),
                        const SizedBox(width: AppDimensions.paddingMd),
                        Expanded(child: _buildExplanationCard(context, data.score.explanation, isDark)),
                      ],
                    ),
                    desktop: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildScoreBreakdownCard(context, data.score, isDark)),
                        const SizedBox(width: AppDimensions.paddingMd),
                        Expanded(child: _buildExplanationCard(context, data.score.explanation, isDark)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingMd),
                  trendAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (trend) => _buildTrendComparisonCard(context, trend, isDark),
                  ),
                  const SizedBox(height: AppDimensions.paddingMd),
                  _buildMonitoringSummaryCard(context, data.monitoringMetrics, isDark),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, PartyDetailAnalytics data, bool isDark) {
    final party = data.party;
    final score = data.score;
    final prof = data.profile;
    final scoreColor = score.scoreColor;

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.paddingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      party['name'] ?? prof.partyName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Chip(
                          label: Text(prof.partyTypeDisplay, style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                        if (party['code'] != null && party['code'].toString().isNotEmpty)
                          Chip(
                            label: Text("کد حساب: ${party['code']}", style: const TextStyle(fontSize: 11)),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                        Chip(
                          avatar: const Icon(Icons.date_range, size: 14),
                          label: Text("فعالیت: ${prof.firstTicketDateFa} تا ${prof.lastTicketDateFa}", style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Overall Score Big Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scoreColor.withOpacity(0.4)),
                ),
                child: Column(
                  children: [
                    Text(
                      score.overallScore != null ? "${score.overallScore!.toStringAsFixed(1)}" : "داده ناکافی",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: scoreColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "امتیاز کل (از ۱۰۰)",
                      style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: scoreColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        score.levelFa,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "اطمینان: ${score.confidence == 'INSUFFICIENT' ? 'ناکافی' : score.confidenceFa}",
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondary),
                ),
              ),
              Text(
                "فعالیت: ${prof.activeDays} روز",
                style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.black54),
              ),
              Text(
                "فرمول: ${score.calculationVersion}",
                style: TextStyle(fontSize: 9, color: isDark ? Colors.white38 : Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsufficientDataWarning(BuildContext context, PartyScoreBreakdown score) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning.withOpacity(0.4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.warning),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "داده کافی برای امتیازدهی معتبر وجود ندارد (حداقل ۱۰ قبض تکمیل‌شده نیاز است). شاخص‌های خام جهت آگاهی مدیران نمایش داده می‌شوند.",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(BuildContext context, PartyDetailAnalytics data, bool isDark) {
    final prof = data.profile;
    final disc = data.discrepancyMetrics;
    final loss = data.lossMetrics;
    final mon = data.monitoringMetrics;
    final turn = data.turnaroundMetrics;
    final corr = data.correctionMetrics;

    final kpis = [
      {'title': 'تعداد بار تکمیل‌شده', 'val': '${prof.completedTickets}', 'sub': '${prof.totalTickets} کل قبوض', 'icon': Icons.local_shipping_outlined, 'color': AppColors.primaryLight},
      {'title': 'مجموع تناژ خالص', 'val': CurrencyFormatter.formatTon(prof.totalNetWeightTon * 1000), 'sub': 'میانگین هر بار: ${prof.averageNetWeightKg} Kg', 'icon': Icons.scale_outlined, 'color': AppColors.secondary},
      {'title': 'میانگین اختلاف با مبدا', 'val': '${disc.avgAbsoluteDiscrepancyKg} Kg', 'sub': 'نرخ مغایرت: ${disc.discrepancyRate}%', 'icon': Icons.difference_outlined, 'color': disc.discrepancyRate > 5 ? AppColors.warning : AppColors.success},
      {'title': 'میانگین افت محموله', 'val': '${loss.avgLossPercent}%', 'sub': '${WeightFormatter.formatKg(loss.totalLossWeight)} افت کل', 'icon': Icons.trending_down, 'color': loss.avgLossPercent > 1.0 ? AppColors.warning : AppColors.info},
      {'title': 'نرخ هشدار پایش', 'val': '${mon.alertsPer100Tickets} در ۱۰۰', 'sub': '${mon.criticalAlerts} مورد بحرانی', 'icon': Icons.notification_important_outlined, 'color': mon.criticalAlerts > 0 ? AppColors.error : AppColors.secondary},
      {'title': 'متوسط زمان توقف', 'val': '${turn.avgTurnaroundMinutes} دقیقه', 'sub': 'نرخ معطلی بالا: ${turn.longWaitingRate}%', 'icon': Icons.timer_outlined, 'color': turn.avgTurnaroundMinutes > 90 ? AppColors.warning : AppColors.primaryLight},
      {'title': 'اصلاحات و تغییر وزن', 'val': '${corr.weightCorrectionCount} مورد', 'sub': 'نرخ اصلاح: ${corr.correctionRate}%', 'icon': Icons.edit_note, 'color': corr.weightCorrectionCount > 0 ? AppColors.warning : AppColors.success},
      {'title': 'ثبات عملکرد وزنی', 'val': data.consistencyMetrics.weightVariationCoef != null ? '${(data.consistencyMetrics.weightVariationCoef! * 100).toStringAsFixed(1)}%' : 'داده ناکافی', 'sub': 'ضریب تغییرات وزن (CV)', 'icon': Icons.graphic_eq, 'color': AppColors.secondaryLight},
    ];

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final crossAxisCount = constraints.maxWidth < 600 ? 2 : (constraints.maxWidth < 1100 ? 4 : 4);
        final childAspectRatio = constraints.maxWidth < 600 ? 1.28 : 1.6;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: kpis.length,
          itemBuilder: (ctx, i) {
            final item = kpis[i];
            final c = item['color'] as Color;
            return AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(item['icon'] as IconData, size: 16, color: c),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item['title'] as String,
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['val'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item['sub'] as String,
                    style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildScoreBreakdownCard(BuildContext context, PartyScoreBreakdown score, bool isDark) {
    final dims = score.dimensionScores;
    final weights = score.dimensionWeights;

    final dimDefinitions = [
      {'key': 'weight_accuracy', 'title': 'دقت اوزان و مغایرت', 'weight': weights['weight_accuracy'] ?? 30.0},
      {'key': 'loss_performance', 'title': 'عملکرد افت (نرمال کالا)', 'weight': weights['loss_performance'] ?? 20.0},
      {'key': 'consistency', 'title': 'ثبات و یکنواختی محموله‌ها', 'weight': weights['consistency'] ?? 15.0},
      {'key': 'monitoring_quality', 'title': 'کیفیت پایش و عدم هشدار', 'weight': weights['monitoring_quality'] ?? 20.0},
      {'key': 'operational_efficiency', 'title': 'بهره‌وری عملیاتی و معطلی', 'weight': weights['operational_efficiency'] ?? 10.0},
      {'key': 'data_reliability', 'title': 'اعتبار و کفایت نمونه آماری', 'weight': weights['data_reliability'] ?? 5.0},
    ];

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.paddingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "تفکیک ابعاد ۶ گانه ارزیابی عملکرد (0-100)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...dimDefinitions.map((d) {
            final key = d['key'] as String;
            final title = d['title'] as String;
            final weight = d['weight'] as double;
            final val = dims[key] ?? 0.0;

            Color barColor = AppColors.success;
            if (val < 40) barColor = AppColors.error;
            else if (val < 60) barColor = AppColors.warning;
            else if (val < 75) barColor = AppColors.secondary;
            else if (val < 90) barColor = AppColors.primaryLight;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "$title (${weight.toInt()}٪)",
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${val.toStringAsFixed(1)} / 100",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: barColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (val / 100.0).clamp(0.0, 1.0),
                      minHeight: 8,
                      color: barColor,
                      backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildExplanationCard(BuildContext context, PartyScoreExplanation explanation, bool isDark) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.paddingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppColors.accent),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "تحلیل و دلایل امتیاز (چرا این امتیاز؟)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Positives
          const Text("نقاط قوت و شاخص‌های مثبت:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.success)),
          const SizedBox(height: 6),
          if (explanation.positivePoints.isEmpty)
            const Text("• موردی ثبت نشده است.", style: TextStyle(fontSize: 12))
          else
            ...explanation.positivePoints.map((p) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
                      const SizedBox(width: 6),
                      Expanded(child: Text(p, style: const TextStyle(fontSize: 12))),
                    ],
                  ),
                )),
          const Divider(height: 24),

          // Attention points
          const Text("موارد نیازمند بررسی و بهبود:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.warning)),
          const SizedBox(height: 6),
          if (explanation.attentionPoints.isEmpty)
            const Text("• موردی نیازمند توجه مشاهده نشد.", style: TextStyle(fontSize: 12))
          else
            ...explanation.attentionPoints.map((a) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warning),
                      const SizedBox(width: 6),
                      Expanded(child: Text(a, style: const TextStyle(fontSize: 12))),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildTrendComparisonCard(BuildContext context, PartyTrendModel trend, bool isDark) {
    final kpis = trend.kpiComparison;
    final period = trend.period;

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.paddingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: AppColors.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "روند عملکرد نسبت به دوره قبل",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                "${period['current_start_fa'] ?? ''} تا ${period['current_end_fa'] ?? ''}",
                style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 44,
              dataRowMaxHeight: 48,
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text("شاخص کلیدی", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("دوره جاری", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("دوره قبل", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("تغییرات", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("روند", style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: kpis.entries.map((e) {
                final key = e.key;
                final m = e.value;
                String labelFa = key;
                if (key == 'score') labelFa = 'امتیاز کل عملکرد';
                else if (key == 'net_tonnage') labelFa = 'تناژ خالص (Ton)';
                else if (key == 'average_discrepancy_kg') labelFa = 'میانگین مغایرت (Kg)';
                else if (key == 'average_loss_percent') labelFa = 'میانگین درصد افت';
                else if (key == 'alert_rate') labelFa = 'نرخ هشدار در ۱۰۰';
                else if (key == 'turnaround_minutes') labelFa = 'متوسط توقف (دقیقه)';

                final currStr = m.current != null ? m.current!.toStringAsFixed(1) : '-';
                final prevStr = m.previous != null ? m.previous!.toStringAsFixed(1) : '-';
                final deltaPctStr = m.deltaPercent != null ? "${m.deltaPercent! > 0 ? '+' : ''}${m.deltaPercent!.toStringAsFixed(1)}%" : '-';

                return DataRow(
                  cells: [
                    DataCell(Text(labelFa, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                    DataCell(Text(currStr, style: const TextStyle(fontSize: 12))),
                    DataCell(Text(prevStr, style: const TextStyle(fontSize: 12))),
                    DataCell(
                      Text(
                        deltaPctStr,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: m.directionColor,
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(m.directionIcon, size: 16, color: m.directionColor),
                          const SizedBox(width: 4),
                          Text(
                            _getDirectionFa(m.direction),
                            style: TextStyle(fontSize: 11, color: m.directionColor, fontWeight: FontWeight.bold),
                          ),
                        ],
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

  String _getDirectionFa(String dir) {
    switch (dir) {
      case 'IMPROVING': return 'بهبود';
      case 'WORSENING': return 'افت';
      case 'STABLE': return 'باثبات';
      default: return 'داده ناکافی';
    }
  }

  Widget _buildMonitoringSummaryCard(BuildContext context, PartyMonitoringMetrics mon, bool isDark) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.paddingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "پایش هوشمند و هشدارها (Phase 3)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () => context.push(AppRoutes.monitoring),
                icon: const Icon(Icons.open_in_new, size: 18),
                tooltip: "مشاهده در پایش هوشمند",
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 360;
              if (isNarrow) {
                return Column(
                  children: [
                    Row(
                      children: [
                        _buildAlertBadge("بحرانی", mon.criticalAlerts, AppColors.severityCritical),
                        const SizedBox(width: 8),
                        _buildAlertBadge("بالا", mon.highAlerts, AppColors.severityHigh),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildAlertBadge("متوسط", mon.mediumAlerts, AppColors.severityMedium),
                        const SizedBox(width: 8),
                        _buildAlertBadge("پایین", mon.lowAlerts, AppColors.severityLow),
                      ],
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  _buildAlertBadge("بحرانی", mon.criticalAlerts, AppColors.severityCritical),
                  const SizedBox(width: 8),
                  _buildAlertBadge("بالا", mon.highAlerts, AppColors.severityHigh),
                  const SizedBox(width: 8),
                  _buildAlertBadge("متوسط", mon.mediumAlerts, AppColors.severityMedium),
                  const SizedBox(width: 8),
                  _buildAlertBadge("پایین", mon.lowAlerts, AppColors.severityLow),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBadge(String title, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              "$count",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
