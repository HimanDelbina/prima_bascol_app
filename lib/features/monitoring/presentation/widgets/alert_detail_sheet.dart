import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/iranian_plate_widget.dart';
import '../../domain/monitoring_models.dart';
import '../monitoring_providers.dart';

class AlertDetailSheet extends ConsumerStatefulWidget {
  final MonitoringAlertItem alert;
  final VoidCallback? onStatusChanged;

  const AlertDetailSheet({
    super.key,
    required this.alert,
    this.onStatusChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required MonitoringAlertItem alert,
    VoidCallback? onStatusChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AlertDetailSheet(
        alert: alert,
        onStatusChanged: onStatusChanged,
      ),
    );
  }

  @override
  ConsumerState<AlertDetailSheet> createState() => _AlertDetailSheetState();
}

class _AlertDetailSheetState extends ConsumerState<AlertDetailSheet> {
  bool _isLoading = false;

  String _formatValueByRule(String alertType, double? val) {
    if (val == null) return '-';
    if (alertType == 'LOSS_ANOMALY') {
      return '${val.toStringAsFixed(2)}٪';
    } else if (alertType == 'LONG_WAITING_TIME') {
      final totalMins = val.toInt();
      if (totalMins >= 60) {
        final h = totalMins ~/ 60;
        final m = totalMins % 60;
        return '$h ساعت و $m دقیقه';
      }
      return '$totalMins دقیقه';
    } else {
      return WeightFormatter.formatKg(val);
    }
  }

  void _showResolveDialog() {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.success),
            SizedBox(width: 8),
            Text("اقدام و حل هشدار"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "لطفاً اقدامات انجام‌شده یا توضیحات را جهت مختومه کردن هشدار ثبت نمایید: *",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "مثال: وزن بارنامه با فرستنده تطبیق داده شد و مغایرت تایید شد.",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("انصراف"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () async {
              final note = noteCtrl.text.trim();
              if (note.length < 3) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("لطفاً حداقل ۳ کاراکتر یادداشت اقدام وارد فرمایید."),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                await ref.read(monitoringRepositoryProvider).resolveAlert(widget.alert.id, note: note);
                if (mounted) {
                  Navigator.pop(context);
                  widget.onStatusChanged?.call();
                  ref.invalidate(monitoringAlertsProvider);
                  ref.invalidate(monitoringSummaryProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("هشدار با موفقیت حل و ثبت شد."),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("خطا در ثبت اقدام: $e"), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text("ثبت و حل نهایی"),
          ),
        ],
      ),
    );
  }

  void _showIgnoreDialog() {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.visibility_off_outlined, color: Colors.grey),
            SizedBox(width: 8),
            Text("نادیده‌گرفتن هشدار"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "علت نادیده‌گرفتن این هشدار چیست؟ (الزامی) *",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: "مثال: تغییر باک سوخت یا بارگیری نامتعارف به صورت استثنایی...",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("انصراف"),
          ),
          ElevatedButton(
            onPressed: () async {
              final note = noteCtrl.text.trim();
              if (note.length < 3) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("لطفاً حداقل ۳ کاراکتر دلیل را وارد فرمایید."),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                await ref.read(monitoringRepositoryProvider).ignoreAlert(widget.alert.id, note: note);
                if (mounted) {
                  Navigator.pop(context);
                  widget.onStatusChanged?.call();
                  ref.invalidate(monitoringAlertsProvider);
                  ref.invalidate(monitoringSummaryProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("هشدار نادیده گرفته شد."),
                      backgroundColor: Colors.grey,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("خطا در نادیده‌گرفتن: $e"), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text("تأیید نادیده‌گرفتن"),
          ),
        ],
      ),
    );
  }

  void _reviewAlert() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(monitoringRepositoryProvider).reviewAlert(widget.alert.id);
      if (mounted) {
        Navigator.pop(context);
        widget.onStatusChanged?.call();
        ref.invalidate(monitoringAlertsProvider);
        ref.invalidate(monitoringSummaryProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("وضعیت هشدار به «تحت بررسی» تغییر یافت."),
            backgroundColor: Color(0xFF0284C7),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("خطا: $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alert = widget.alert;
    final hSummary = alert.historicalSummary;
    final hasHistory = hSummary != null && (alert.sampleSize > 0 || (hSummary['sample_size'] ?? 0) > 0);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: alert.severityColor.withValues(alpha: 0.15),
                  child: Icon(alert.severityIcon, color: alert.severityColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        alert.alertTypeTitle,
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: alert.statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: alert.statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    alert.statusTitle,
                    style: TextStyle(
                      color: alert.statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Body Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Explainable Reason Box (Core Requirement)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: alert.severityColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: alert.severityColor.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_outline, size: 18, color: alert.severityColor),
                            const SizedBox(width: 8),
                            Text(
                              "دلیل و تحلیل هوشمند سیستم:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: alert.severityColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          alert.reason.isNotEmpty ? alert.reason : alert.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quantitative Metrics Grid
                  Text(
                    "مقایسه شاخص‌های آماری",
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _metricCard(
                          context,
                          title: "مقدار فعلی این قبض",
                          value: _formatValueByRule(alert.alertTypeCode, alert.currentValue),
                          color: alert.severityColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _metricCard(
                          context,
                          title: "میانگین مبنای تاریخی",
                          value: _formatValueByRule(alert.alertTypeCode, alert.baselineValue),
                          color: const Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _metricCard(
                          context,
                          title: "میزان اختلاف (انحراف)",
                          value: alert.deviationValue != null
                              ? _formatValueByRule(alert.alertTypeCode, alert.deviationValue)
                              : "-",
                          color: Colors.deepOrange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _metricCard(
                          context,
                          title: "درصد انحراف نسبی",
                          value: alert.deviationPercent != null
                              ? "${alert.deviationPercent!.toStringAsFixed(2)}٪"
                              : "-",
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Baseline Quality & Confidence (Explainability & Data Quality)
                  AppCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.analytics_outlined, size: 18, color: Colors.blueGrey),
                            const SizedBox(width: 8),
                            Text(
                              "اعتبار مبنای مقایسه و جامعه آماری",
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("تعداد سوابق مقایسه‌شده:", style: TextStyle(color: Colors.grey, fontSize: 13)),
                            Text(
                              "${alert.sampleSize} سند تکمیل‌شده گذشته",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("مبنای استخراج الگو:", style: TextStyle(color: Colors.grey, fontSize: 13)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                alert.baselineSourceFa,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("درجه اطمینان مبنا:", style: TextStyle(color: Colors.grey, fontSize: 13)),
                            Text(
                              alert.confidenceTitle,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: alert.confidenceCode == 'high'
                                    ? AppColors.success
                                    : alert.confidenceCode == 'medium'
                                        ? const Color(0xFF0284C7)
                                        : Colors.amber.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "💡 ${alert.confidenceExplanation}",
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Historical Distribution Cards (Average, Median, StdDev, Min, Max)
                  if (hasHistory) ...[
                    Text(
                      "توزیع تاریخی مقادیر گذشته",
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    AppCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _statRow("میانگین کل:", _formatValueByRule(alert.alertTypeCode, double.tryParse(hSummary['average']?.toString() ?? ''))),
                              ),
                              Expanded(
                                child: _statRow("میانه (Median):", _formatValueByRule(alert.alertTypeCode, double.tryParse(hSummary['median']?.toString() ?? ''))),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _statRow("کمترین مقدار:", _formatValueByRule(alert.alertTypeCode, double.tryParse(hSummary['min']?.toString() ?? ''))),
                              ),
                              Expanded(
                                child: _statRow("بیشترین مقدار:", _formatValueByRule(alert.alertTypeCode, double.tryParse(hSummary['max']?.toString() ?? ''))),
                              ),
                            ],
                          ),
                          if (hSummary['stddev'] != null || hSummary['last_5_average'] != null) ...[
                            const Divider(height: 16),
                            Row(
                              children: [
                                if (hSummary['stddev'] != null)
                                  Expanded(
                                    child: _statRow("انحراف معیار (StdDev):", "${double.tryParse(hSummary['stddev'].toString())?.toStringAsFixed(1) ?? hSummary['stddev']} kg"),
                                  ),
                                if (hSummary['last_5_average'] != null)
                                  Expanded(
                                    child: _statRow("میانگین ۵ مورد اخیر:", _formatValueByRule(alert.alertTypeCode, double.tryParse(hSummary['last_5_average']?.toString() ?? ''))),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Ticket & Fleet Info Card
                  Text(
                    "اطلاعات قبض و ناوگان",
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("شماره قبض:", style: TextStyle(color: Colors.grey, fontSize: 13)),
                            Text(
                              alert.ticketSerial ?? alert.ticketId?.toString() ?? "-",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                            ),
                          ],
                        ),
                        if (alert.ticketPlate != null && alert.ticketPlate!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("پلاک خودرو:", style: TextStyle(color: Colors.grey, fontSize: 13)),
                              IranianPlateWidget(plateDisplay: alert.ticketPlate!, scale: 0.8),
                            ],
                          ),
                        ],
                        if (alert.productName != null && alert.productName!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("کالا / محموله:", style: TextStyle(color: Colors.grey, fontSize: 13)),
                              Text(alert.productName!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            ],
                          ),
                        ],
                        if (alert.partyName != null && alert.partyName!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("طرف حساب:", style: TextStyle(color: Colors.grey, fontSize: 13)),
                              Text(alert.partyName!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("تاریخ کشف هشدار:", style: TextStyle(color: Colors.grey, fontSize: 13)),
                            Text(alert.createdAtJalali ?? "-", style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Resolution / Audit info if resolved
                  if (alert.statusCode == 'RESOLVED' || alert.statusCode == 'IGNORED') ...[
                    const SizedBox(height: 16),
                    AppCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                alert.statusCode == 'RESOLVED' ? Icons.check_circle : Icons.visibility_off,
                                size: 18,
                                color: alert.statusColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                alert.statusCode == 'RESOLVED' ? "گزارش اقدام نهایی و حل هشدار:" : "دلیل نادیده‌گرفتن:",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: alert.statusColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(alert.resolutionNote ?? "-", style: const TextStyle(fontSize: 13, height: 1.5)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("اقدام‌کننده: ${alert.resolvedByName ?? 'مدیر سیستم'}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              Text("زمان: ${alert.resolvedAtJalali ?? '-'}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Action Buttons (Review / Resolve / Ignore)
                  if (alert.statusCode == 'OPEN' || alert.statusCode == 'REVIEWED') ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (alert.statusCode == 'OPEN')
                          OutlinedButton.icon(
                            onPressed: _isLoading ? null : _reviewAlert,
                            icon: const Icon(Icons.pending_actions_rounded, size: 18),
                            label: const Text("بررسی شد (تحت بررسی)"),
                          ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                          onPressed: _isLoading ? null : _showResolveDialog,
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text("اقدام شد / حل هشدار"),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
                          onPressed: _isLoading ? null : _showIgnoreDialog,
                          icon: const Icon(Icons.visibility_off_outlined, size: 18),
                          label: const Text("نادیده‌گرفتن"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(BuildContext context, {required String title, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
