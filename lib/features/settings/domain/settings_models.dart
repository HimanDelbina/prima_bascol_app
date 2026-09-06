class SystemSettingsModel {
  final String companyName;
  final double defaultTolerancePercent;
  final bool enforceSequentialWeights;
  final bool allowManualWeightEntry;
  final String apiBaseUrl;

  SystemSettingsModel({
    required this.companyName,
    required this.defaultTolerancePercent,
    required this.enforceSequentialWeights,
    required this.allowManualWeightEntry,
    required this.apiBaseUrl,
  });

  factory SystemSettingsModel.fromJson(Map<String, dynamic> json) {
    return SystemSettingsModel(
      companyName: json['company_name']?.toString() ?? 'سامانه هوشمند مدیریت باسکول پریما',
      defaultTolerancePercent: double.tryParse(json['default_tolerance_percent']?.toString() ?? '1.5') ?? 1.5,
      enforceSequentialWeights: json['enforce_sequential_weights'] != false,
      allowManualWeightEntry: json['allow_manual_weight_entry'] != false,
      apiBaseUrl: json['api_base_url']?.toString() ?? 'http://127.0.0.1:8000/api/v1',
    );
  }
}
