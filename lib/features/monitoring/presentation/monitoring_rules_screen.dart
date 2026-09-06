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
import '../domain/monitoring_models.dart';
import 'monitoring_providers.dart';

class MonitoringRulesScreen extends ConsumerWidget {
  const MonitoringRulesScreen({super.key});

  void _showEditRuleDialog(BuildContext context, WidgetRef ref, MonitoringRuleItem rule) {
    final formKey = GlobalKey<FormState>();
    final minHistCtrl = TextEditingController(text: rule.minimumHistory.toString());
    final warnCtrl = TextEditingController(text: rule.warningThreshold.toStringAsFixed(1));
    final highCtrl = TextEditingController(text: rule.highThreshold.toStringAsFixed(1));
    final critCtrl = TextEditingController(text: rule.criticalThreshold.toStringAsFixed(1));
    final pWarnCtrl = TextEditingController(text: rule.percentageWarning.toStringAsFixed(1));
    final pHighCtrl = TextEditingController(text: rule.percentageHigh.toStringAsFixed(1));
    final pCritCtrl = TextEditingController(text: rule.percentageCritical.toStringAsFixed(1));
    bool isEnabled = rule.enabled;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.tune_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "تنظیمات: ${rule.nameFa}",
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (rule.description.isNotEmpty) ...[
                      Text(
                        rule.description,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Enable Switch
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("وضعیت فعال بودن قانون:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      value: isEnabled,
                      onChanged: (v) => setDialogState(() => isEnabled = v),
                    ),
                    const Divider(height: 16),

                    // Minimum History
                    TextFormField(
                      controller: minHistCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "حداقل تعداد سابقه جهت تحلیل (Minimum History) *",
                        hintText: "مثال: 10",
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        final v = int.tryParse(val?.trim() ?? '');
                        if (v == null || v < 1) return "حداقل ۱ سابقه برای فعال‌سازی لازم است.";
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Numeric Thresholds
                    const Text("آستانه‌های عددی انحراف (Kg یا دقیقه):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: warnCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: "هشدار (Warning)",
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => _validateThreshold(v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: highCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: "بالا (High)",
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => _validateThreshold(v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: critCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: "بحرانی (Critical)",
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => _validateThreshold(v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Percentage Thresholds
                    const Text("آستانه‌های درصدی انحراف (%):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: pWarnCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: "هشدار %",
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => _validateThreshold(v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: pHighCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: "بالا %",
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => _validateThreshold(v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: pCritCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: "بحرانی %",
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => _validateThreshold(v),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("انصراف"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final warn = double.parse(warnCtrl.text.trim());
                final high = double.parse(highCtrl.text.trim());
                final crit = double.parse(critCtrl.text.trim());

                if (warn > high || high > crit) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("ترتیب آستانه‌های عددی باید رعایت شود: هشدار <= بالا <= بحرانی."),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                  return;
                }

                final pWarn = double.parse(pWarnCtrl.text.trim());
                final pHigh = double.parse(pHighCtrl.text.trim());
                final pCrit = double.parse(pCritCtrl.text.trim());

                if (pWarn > pHigh || pHigh > pCrit) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("ترتیب درصدهای انحراف باید رعایت شود: هشدار <= بالا <= بحرانی."),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                  return;
                }

                final payload = {
                  "enabled": isEnabled,
                  "minimum_history": int.parse(minHistCtrl.text.trim()),
                  "warning_threshold": warn,
                  "high_threshold": high,
                  "critical_threshold": crit,
                  "percentage_warning": pWarn,
                  "percentage_high": pHigh,
                  "percentage_critical": pCrit,
                };

                try {
                  await ref.read(monitoringRepositoryProvider).updateRule(rule.id, payload);
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ref.invalidate(monitoringRulesProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("تنظیمات قانون با موفقیت ذخیره شد."),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("خطا در ذخیره تنظیمات: $e"), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              child: const Text("ذخیره تنظیمات"),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateThreshold(String? val) {
    if (val == null || val.trim().isEmpty) return "اجباری";
    final num = double.tryParse(val.trim());
    if (num == null) return "عدد نامعتبر";
    if (num < 0) return "منفی مجاز نیست";
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(monitoringRulesProvider);
    final isMobile = ResponsiveLayout.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("تنظیمات و آستانه‌های قوانین پایش هوشمند"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'بازگشت به مرکز پایش',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.monitoring);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'بروزرسانی',
            onPressed: () => ref.invalidate(monitoringRulesProvider),
          ),
        ],
      ),
      body: rulesAsync.when(
        loading: () => const AppLoadingIndicator(message: "در حال دریافت قوانین و آستانه‌های پایش..."),
        error: (err, _) => AppErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(monitoringRulesProvider),
        ),
        data: (rules) {
          if (rules.isEmpty) {
            return const AppEmptyState(
              icon: Icons.rule_folder_outlined,
              title: "قانونی تعریف نشده است",
              description: "تنظیمات قوانین پایش از طرف سرور مدیریت می‌گردند.",
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.paddingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFF0284C7), size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "پایش هوشمند پریما بر مبنای تحلیل‌های آماری و تاریخی عمل می‌کند. آستانه‌های زیر مشخص‌کننده حساسیت صدور هشدارهای زرد (هشدار)، نارنجی (بالا) و قرمز (بحرانی) هستند.",
                          style: TextStyle(fontSize: 12, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rules.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final r = rules[i];
                    return AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: (r.enabled ? AppColors.primary : Colors.grey).withValues(alpha: 0.12),
                                child: Icon(
                                  Icons.shield_outlined,
                                  color: r.enabled ? AppColors.primary : Colors.grey,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.nameFa,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      r.ruleType,
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontFamily: 'monospace'),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (r.enabled ? AppColors.success : Colors.grey).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: (r.enabled ? AppColors.success : Colors.grey).withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  r.enabled ? "فعال" : "غیرفعال",
                                  style: TextStyle(
                                    color: r.enabled ? AppColors.success : Colors.grey,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                                tooltip: "ویرایش آستانه‌ها",
                                onPressed: () => _showEditRuleDialog(context, ref, r),
                              ),
                            ],
                          ),
                          if (r.description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              r.description,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4),
                            ),
                          ],
                          const Divider(height: 20),

                          // Thresholds display
                          isMobile
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _ruleMetricRow("حداقل سابقه مورد نیاز:", "${r.minimumHistory} سند"),
                                    const SizedBox(height: 6),
                                    _ruleMetricRow("آستانه عددی هشدار / بالا / بحرانی:", "${r.warningThreshold} / ${r.highThreshold} / ${r.criticalThreshold}"),
                                    const SizedBox(height: 6),
                                    _ruleMetricRow("آستانه درصدی هشدار / بالا / بحرانی:", "${r.percentageWarning}٪ / ${r.percentageHigh}٪ / ${r.percentageCritical}٪"),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: _ruleMetricBox("حداقل سابقه", "${r.minimumHistory} سند معتبر"),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _ruleMetricBox("آستانه عددی", "${r.warningThreshold} | ${r.highThreshold} | ${r.criticalThreshold}"),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _ruleMetricBox("آستانه درصدی", "${r.percentageWarning}٪ | ${r.percentageHigh}٪ | ${r.percentageCritical}٪"),
                                    ),
                                  ],
                                ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _ruleMetricRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _ruleMetricBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
