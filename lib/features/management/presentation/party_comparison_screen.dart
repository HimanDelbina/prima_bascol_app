import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../domain/party_analytics_models.dart';
import 'management_providers.dart';

class PartyComparisonScreen extends ConsumerStatefulWidget {
  const PartyComparisonScreen({super.key});

  @override
  ConsumerState<PartyComparisonScreen> createState() => _PartyComparisonScreenState();
}

class _PartyComparisonScreenState extends ConsumerState<PartyComparisonScreen> {
  final List<int> _selectedPartyIds = [];
  String _selectedPeriod = 'this_month';
  PartyComparisonModel? _comparisonResult;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialSelection();
    });
  }

  void _loadInitialSelection() {
    final rankingAsync = ref.read(partyRankingProvider);
    rankingAsync.whenData((items) {
      if (items.length >= 2 && _selectedPartyIds.isEmpty) {
        setState(() {
          _selectedPartyIds.add(items[0].partyId);
          _selectedPartyIds.add(items[1].partyId);
        });
        _runComparison();
      }
    });
  }

  Future<void> _runComparison() async {
    if (_selectedPartyIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("لطفاً حداقل ۲ طرف‌حساب را انتخاب کنید.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(managementRepositoryProvider);
      final res = await repo.compareParties(
        _selectedPartyIds,
        quickPeriod: _selectedPeriod,
      );
      setState(() {
        _comparisonResult = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rankingAsync = ref.watch(partyRankingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "مقایسه همزمان طرف‌های حساب (Peer Comparison)",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Selection Card
            AppCard(
              padding: const EdgeInsets.all(AppDimensions.paddingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "انتخاب طرف‌های حساب جهت مقایسه (۲ تا ۴ طرف‌حساب):",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  rankingAsync.when(
                    loading: () => const AppLoadingIndicator(message: "در حال بارگذاری لیست طرف‌ها..."),
                    error: (err, _) => Text("خطا در بارگذاری طرف‌ها: $err"),
                    data: (items) {
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: items.map((item) {
                          final isSelected = _selectedPartyIds.contains(item.partyId);
                          return FilterChip(
                            label: Text(
                              "${item.partyName} (${item.partyTypeFa})",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  if (_selectedPartyIds.length < 4) {
                                    _selectedPartyIds.add(item.partyId);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("امکان انتخاب حداکثر ۴ طرف‌حساب وجود دارد.")),
                                    );
                                  }
                                } else {
                                  _selectedPartyIds.remove(item.partyId);
                                }
                              });
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text("ماه جاری", style: TextStyle(fontSize: 12)),
                            selected: _selectedPeriod == 'this_month',
                            onSelected: (val) {
                              if (val) setState(() => _selectedPeriod = 'this_month');
                            },
                          ),
                          ChoiceChip(
                            label: const Text("ماه گذشته", style: TextStyle(fontSize: 12)),
                            selected: _selectedPeriod == 'last_month',
                            onSelected: (val) {
                              if (val) setState(() => _selectedPeriod = 'last_month');
                            },
                          ),
                          ChoiceChip(
                            label: const Text("سال جاری", style: TextStyle(fontSize: 12)),
                            selected: _selectedPeriod == 'this_year',
                            onSelected: (val) {
                              if (val) setState(() => _selectedPeriod = 'this_year');
                            },
                          ),
                        ],
                      ),
                      FilledButton.icon(
                        onPressed: _isLoading ? null : _runComparison,
                        icon: const Icon(Icons.compare_arrows, size: 18),
                        label: const Text("اجرای مقایسه", style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMd),

            // Comparison Results
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(40.0),
                child: Center(child: AppLoadingIndicator(message: "در حال محاسبه مقایسه شاخص‌ها...")),
              )
            else if (_errorMessage != null)
              AppErrorState(message: _errorMessage!, onRetry: _runComparison)
            else if (_comparisonResult != null)
              _buildComparisonView(context, _comparisonResult!, isDark)
            else
              const AppEmptyState(
                icon: Icons.compare_arrows,
                title: "طرف‌های حساب را انتخاب کنید",
                description: "حداقل ۲ طرف‌حساب را از کادر بالا انتخاب کرده و دکمه اجرای مقایسه را بزنید.",
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonView(BuildContext context, PartyComparisonModel model, bool isDark) {
    final parties = model.comparison;

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.paddingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.analytics_outlined, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    "جدول مقایسه همزمان (${parties.length} طرف‌حساب)",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              Chip(
                label: Text("کانتکست: ${model.productContext}", style: const TextStyle(fontSize: 11)),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 16),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                isDark ? const Color(0xFF1E3A8A).withOpacity(0.25) : const Color(0xFF1E3A8A).withOpacity(0.08),
              ),
              columnSpacing: 28,
              columns: [
                const DataColumn(label: Text("شاخص مقایسه‌ای", style: TextStyle(fontWeight: FontWeight.bold))),
                ...parties.map((p) => DataColumn(
                      label: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.partyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(p.partyTypeFa, style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54)),
                        ],
                      ),
                    )),
              ],
              rows: [
                // Score Row
                DataRow(cells: [
                  const DataCell(Text("امتیاز کل عملکرد (0-100)", style: TextStyle(fontWeight: FontWeight.bold))),
                  ...parties.map((p) {
                    final sc = p.score.overallScore;
                    final scColor = p.score.scoreColor;
                    return DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: scColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          sc != null ? "${sc.toStringAsFixed(1)} (${p.score.levelFa})" : "داده ناکافی",
                          style: TextStyle(fontWeight: FontWeight.bold, color: scColor),
                        ),
                      ),
                    );
                  }),
                ]),
                // Trips
                DataRow(cells: [
                  const DataCell(Text("تعداد بار تکمیل‌شده")),
                  ...parties.map((p) => DataCell(Text("${p.volume['completed_tickets'] ?? 0} سرویس"))),
                ]),
                // Net Tonnage
                DataRow(cells: [
                  const DataCell(Text("مجموع تناژ خالص")),
                  ...parties.map((p) => DataCell(Text("${p.volume['net_tonnage'] ?? 0.0} Ton"))),
                ]),
                // Discrepancy
                DataRow(cells: [
                  const DataCell(Text("میانگین اختلاف وزن")),
                  ...parties.map((p) => DataCell(Text("${p.discrepancy['avg_abs_discrepancy_kg'] ?? 0.0} Kg"))),
                ]),
                // Loss
                DataRow(cells: [
                  const DataCell(Text("میانگین درصد افت")),
                  ...parties.map((p) => DataCell(Text("${p.loss['avg_loss_percent'] ?? 0.0}%"))),
                ]),
                // Alerts Rate
                DataRow(cells: [
                  const DataCell(Text("نرخ هشدار در ۱۰۰ سرویس")),
                  ...parties.map((p) => DataCell(Text("${p.monitoring['alerts_per_100'] ?? 0.0}%"))),
                ]),
                // Critical Alerts
                DataRow(cells: [
                  const DataCell(Text("هشدارهای بحرانی")),
                  ...parties.map((p) => DataCell(Text(
                        "${p.monitoring['critical_alerts'] ?? 0}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: (p.monitoring['critical_alerts'] ?? 0) > 0 ? AppColors.error : AppColors.success,
                        ),
                      ))),
                ]),
                // Turnaround
                DataRow(cells: [
                  const DataCell(Text("متوسط زمان توقف خودرو")),
                  ...parties.map((p) => DataCell(Text("${p.turnaround['avg_minutes'] ?? 0.0} دقیقه"))),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
