class MonitoringAlertItem {
  final int id;
  final int? ticketId;
  final String? ticketSerial;
  final String ruleCode;
  final String ruleName;
  final String severity; // critical, high, medium, low
  final String status;   // open, reviewed, resolved, ignored
  final String description;
  final double? currentValue;
  final double? baselineValue;
  final double? deviationPercent;
  final String? resolvedNotes;
  final String? createdAtJalali;

  MonitoringAlertItem({
    required this.id,
    this.ticketId,
    this.ticketSerial,
    required this.ruleCode,
    required this.ruleName,
    required this.severity,
    required this.status,
    required this.description,
    this.currentValue,
    this.baselineValue,
    this.deviationPercent,
    this.resolvedNotes,
    this.createdAtJalali,
  });

  factory MonitoringAlertItem.fromJson(Map<String, dynamic> json) {
    return MonitoringAlertItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      ticketId: json['ticket'] as int? ?? json['ticket_id'] as int?,
      ticketSerial: json['ticket_serial']?.toString() ?? json['serial_number']?.toString(),
      ruleCode: json['rule_code']?.toString() ?? '',
      ruleName: (json['title'] ?? json['rule_name'] ?? json['rule_title'])?.toString() ?? 'قانون پایش',
      severity: json['severity']?.toString().toUpperCase() ?? 'MEDIUM',
      status: json['status']?.toString().toUpperCase() ?? 'OPEN',
      description: (json['description'] ?? json['message'] ?? json['reason'])?.toString() ?? '',
      currentValue: double.tryParse(json['current_value']?.toString() ?? ''),
      baselineValue: double.tryParse(json['baseline_value']?.toString() ?? ''),
      deviationPercent: double.tryParse(json['deviation_percent']?.toString() ?? ''),
      resolvedNotes: (json['resolution_note'] ?? json['resolution_notes'] ?? json['notes'])?.toString(),
      createdAtJalali: json['created_at_jalali']?.toString(),
    );
  }
}

class MonitoringSummaryModel {
  final int openCount;
  final int criticalCount;
  final int reviewedCount;
  final int resolvedCount;

  MonitoringSummaryModel({
    required this.openCount,
    required this.criticalCount,
    required this.reviewedCount,
    required this.resolvedCount,
  });

  factory MonitoringSummaryModel.fromJson(Map<String, dynamic> json) {
    return MonitoringSummaryModel(
      openCount: json['open_count'] is int ? json['open_count'] : int.tryParse(json['open_count']?.toString() ?? '0') ?? 0,
      criticalCount: json['critical_count'] is int ? json['critical_count'] : int.tryParse(json['critical_count']?.toString() ?? '0') ?? 0,
      reviewedCount: json['reviewed_count'] is int ? json['reviewed_count'] : int.tryParse(json['reviewed_count']?.toString() ?? '0') ?? 0,
      resolvedCount: json['resolved_count'] is int ? json['resolved_count'] : int.tryParse(json['resolved_count']?.toString() ?? '0') ?? 0,
    );
  }
}

class MonitoringRuleItem {
  final int id;
  final String code;
  final String name;
  final String severity;
  final double threshold;
  final bool isActive;

  MonitoringRuleItem({
    required this.id,
    required this.code,
    required this.name,
    required this.severity,
    required this.threshold,
    required this.isActive,
  });

  factory MonitoringRuleItem.fromJson(Map<String, dynamic> json) {
    return MonitoringRuleItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      severity: json['severity']?.toString() ?? 'medium',
      threshold: double.tryParse(json['threshold']?.toString() ?? '0') ?? 0.0,
      isActive: json['is_active'] != false,
    );
  }
}
