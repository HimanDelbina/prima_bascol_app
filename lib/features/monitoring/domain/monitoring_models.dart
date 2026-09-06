import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class MonitoringAlertItem {
  final int id;
  final int? ticketId;
  final String? ticketSerial;
  final String? ticketPlate;
  final String? productName;
  final String? partyName;

  final String alertTypeCode;
  final String alertTypeTitle;
  final String severityCode;
  final String severityTitle;
  final String statusCode;
  final String statusTitle;
  final String confidenceCode;
  final String confidenceTitle;

  final String title;
  final String description;
  final String reason;

  final double? currentValue;
  final double? baselineValue;
  final double? deviationValue;
  final double? deviationPercent;
  final int sampleSize;
  final String baselineSource;

  final String? createdAt;
  final String? createdAtJalali;
  final String? updatedAt;
  final String? updatedAtJalali;

  final String? reviewedAt;
  final String? reviewedAtJalali;
  final String? reviewedByName;

  final String? resolvedAt;
  final String? resolvedAtJalali;
  final String? resolvedByName;
  final String? resolutionNote;

  final Map<String, dynamic> metadata;
  final Map<String, dynamic>? ticketSummary;
  final Map<String, dynamic>? historicalSummary;
  final List<dynamic>? recentHistory;

  MonitoringAlertItem({
    required this.id,
    this.ticketId,
    this.ticketSerial,
    this.ticketPlate,
    this.productName,
    this.partyName,
    required this.alertTypeCode,
    required this.alertTypeTitle,
    required this.severityCode,
    required this.severityTitle,
    required this.statusCode,
    required this.statusTitle,
    required this.confidenceCode,
    required this.confidenceTitle,
    required this.title,
    required this.description,
    required this.reason,
    this.currentValue,
    this.baselineValue,
    this.deviationValue,
    this.deviationPercent,
    required this.sampleSize,
    required this.baselineSource,
    this.createdAt,
    this.createdAtJalali,
    this.updatedAt,
    this.updatedAtJalali,
    this.reviewedAt,
    this.reviewedAtJalali,
    this.reviewedByName,
    this.resolvedAt,
    this.resolvedAtJalali,
    this.resolvedByName,
    this.resolutionNote,
    required this.metadata,
    this.ticketSummary,
    this.historicalSummary,
    this.recentHistory,
  });

  factory MonitoringAlertItem.fromJson(Map<String, dynamic> json) {
    // Parse alert_type
    String aCode = '';
    String aTitle = '';
    if (json['alert_type'] is Map) {
      aCode = json['alert_type']['code']?.toString() ?? '';
      aTitle = json['alert_type']['title']?.toString() ?? aCode;
    } else {
      aCode = json['alert_type']?.toString() ?? json['rule_code']?.toString() ?? '';
      aTitle = json['title']?.toString() ?? aCode;
    }

    // Parse severity
    String sCode = 'MEDIUM';
    String sTitle = 'متوسط';
    if (json['severity'] is Map) {
      sCode = json['severity']['code']?.toString().toUpperCase() ?? 'MEDIUM';
      sTitle = json['severity']['title']?.toString() ?? sCode;
    } else if (json['severity'] != null) {
      sCode = json['severity'].toString().toUpperCase();
      sTitle = sCode == 'CRITICAL'
          ? 'بحرانی'
          : sCode == 'HIGH'
              ? 'بالا'
              : sCode == 'LOW'
                  ? 'پایین'
                  : sCode == 'INFO'
                      ? 'اطلاعات'
                      : 'متوسط';
    }

    // Parse status
    String stCode = 'OPEN';
    String stTitle = 'باز';
    if (json['status'] is Map) {
      stCode = json['status']['code']?.toString().toUpperCase() ?? 'OPEN';
      stTitle = json['status']['title']?.toString() ?? stCode;
    } else if (json['status'] != null) {
      stCode = json['status'].toString().toUpperCase();
      stTitle = stCode == 'RESOLVED'
          ? 'حل‌شده'
          : stCode == 'REVIEWED'
              ? 'بررسی‌شده'
              : stCode == 'IGNORED'
                  ? 'نادیده‌گرفته'
                  : 'باز';
    }

    // Parse confidence
    String cCode = 'insufficient';
    String cTitle = 'داده ناکافی';
    if (json['confidence'] is Map) {
      cCode = json['confidence']['code']?.toString().toLowerCase() ?? 'insufficient';
      cTitle = json['confidence']['title']?.toString() ?? cCode;
    } else if (json['confidence'] != null) {
      cCode = json['confidence'].toString().toLowerCase();
      cTitle = cCode == 'high'
          ? 'بالا (۵۰+ نمونه)'
          : cCode == 'medium'
              ? 'متوسط (۲۰-۴۹ نمونه)'
              : cCode == 'low'
                  ? 'پایین (۱۰-۱۹ نمونه)'
                  : 'داده ناکافی';
    }

    final meta = json['metadata'] is Map<String, dynamic>
        ? json['metadata'] as Map<String, dynamic>
        : <String, dynamic>{};

    return MonitoringAlertItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      ticketId: json['ticket'] is int
          ? json['ticket']
          : int.tryParse(json['ticket']?.toString() ?? json['ticket_id']?.toString() ?? ''),
      ticketSerial: json['ticket_serial']?.toString() ??
          (json['ticket_summary'] is Map ? json['ticket_summary']['serial_number']?.toString() : null),
      ticketPlate: json['ticket_plate']?.toString() ??
          (json['ticket_summary'] is Map ? json['ticket_summary']['license_plate']?.toString() : null),
      productName: json['product_name']?.toString() ??
          (json['ticket_summary'] is Map ? json['ticket_summary']['product_name']?.toString() : null),
      partyName: json['party_name']?.toString() ??
          (json['ticket_summary'] is Map ? json['ticket_summary']['party_name']?.toString() : null),
      alertTypeCode: aCode,
      alertTypeTitle: aTitle.isNotEmpty ? aTitle : 'هشدار پایش هوشمند',
      severityCode: sCode,
      severityTitle: sTitle,
      statusCode: stCode,
      statusTitle: stTitle,
      confidenceCode: cCode,
      confidenceTitle: cTitle,
      title: json['title']?.toString() ?? aTitle,
      description: json['description']?.toString() ?? '',
      reason: json['reason']?.toString() ?? json['description']?.toString() ?? '',
      currentValue: double.tryParse(json['current_value']?.toString() ?? ''),
      baselineValue: double.tryParse(json['baseline_value']?.toString() ?? ''),
      deviationValue: double.tryParse(json['deviation_value']?.toString() ?? ''),
      deviationPercent: double.tryParse(json['deviation_percent']?.toString() ?? ''),
      sampleSize: json['sample_size'] is int
          ? json['sample_size']
          : int.tryParse(json['sample_size']?.toString() ?? '0') ?? 0,
      baselineSource: json['baseline_source']?.toString() ?? meta['baseline_source']?.toString() ?? '',
      createdAt: json['created_at']?.toString(),
      createdAtJalali: json['created_at_jalali']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      updatedAtJalali: json['updated_at_jalali']?.toString(),
      reviewedAt: json['reviewed_at']?.toString(),
      reviewedAtJalali: json['reviewed_at_jalali']?.toString(),
      reviewedByName: json['reviewed_by_name']?.toString(),
      resolvedAt: json['resolved_at']?.toString(),
      resolvedAtJalali: json['resolved_at_jalali']?.toString(),
      resolvedByName: json['resolved_by_name']?.toString(),
      resolutionNote: json['resolution_note']?.toString(),
      metadata: meta,
      ticketSummary: json['ticket_summary'] is Map<String, dynamic>
          ? json['ticket_summary'] as Map<String, dynamic>
          : null,
      historicalSummary: json['historical_summary'] is Map<String, dynamic>
          ? json['historical_summary'] as Map<String, dynamic>
          : null,
      recentHistory: json['recent_history'] is List ? json['recent_history'] as List : null,
    );
  }

  Color get severityColor {
    switch (severityCode.toUpperCase()) {
      case 'CRITICAL':
        return AppColors.riskCritical;
      case 'HIGH':
        return AppColors.riskHigh;
      case 'MEDIUM':
        return AppColors.riskMedium;
      case 'INFO':
        return const Color(0xFF0284C7);
      case 'LOW':
      default:
        return AppColors.riskLow;
    }
  }

  IconData get severityIcon {
    switch (severityCode.toUpperCase()) {
      case 'CRITICAL':
        return Icons.dangerous_rounded;
      case 'HIGH':
        return Icons.error_outline_rounded;
      case 'MEDIUM':
        return Icons.warning_amber_rounded;
      case 'INFO':
        return Icons.info_outline_rounded;
      case 'LOW':
      default:
        return Icons.check_circle_outline_rounded;
    }
  }

  Color get statusColor {
    switch (statusCode.toUpperCase()) {
      case 'OPEN':
        return AppColors.warning;
      case 'REVIEWED':
        return const Color(0xFF0284C7);
      case 'RESOLVED':
        return AppColors.success;
      case 'IGNORED':
      default:
        return Colors.grey;
    }
  }

  String get baselineSourceFa {
    switch (baselineSource.toUpperCase()) {
      case 'VEHICLE_PRODUCT':
        return 'سوابق این خودرو و این کالا';
      case 'VEHICLE':
        return 'سوابق تاریخی این خودرو';
      case 'PRODUCT':
        return 'میانگین تاریخی محصول در باسکول';
      case 'PARTY_PRODUCT':
        return 'سوابق طرف حساب با این محصول';
      case 'PARTY':
        return 'میانگین سوابق این طرف حساب';
      case 'GLOBAL':
        return 'میانگین کل مجموعه باسکول';
      default:
        return baselineSource.isNotEmpty ? baselineSource : 'سوابق تاریخی معتبر';
    }
  }

  String get confidenceExplanation {
    switch (confidenceCode.toLowerCase()) {
      case 'high':
        return 'پایگاه داده قوی (بیش از ۵۰ توزین معتبر گذشته)';
      case 'medium':
        return 'پایگاه داده متوسط (۲۰ الی ۴۹ توزین معتبر گذشته)';
      case 'low':
        return 'پایگاه داده مقدماتی (۱۰ الی ۱۹ توزین معتبر گذشته)';
      case 'insufficient':
      default:
        return 'داده تاریخی برای مقایسه دقیق آماری ناکافی است';
    }
  }
}

class MonitoringSummaryModel {
  final int totalToday;
  final int openCount;
  final int reviewedCount;
  final int resolvedCount;
  final int ignoredCount;
  final int highCount;
  final int criticalCount;
  final int totalOpen;
  final Map<String, int> byType;

  MonitoringSummaryModel({
    required this.totalToday,
    required this.openCount,
    required this.reviewedCount,
    required this.resolvedCount,
    required this.ignoredCount,
    required this.highCount,
    required this.criticalCount,
    required this.totalOpen,
    required this.byType,
  });

  factory MonitoringSummaryModel.fromJson(Map<String, dynamic> json) {
    final bt = <String, int>{};
    if (json['by_type'] is Map) {
      (json['by_type'] as Map).forEach((k, v) {
        bt[k.toString()] = v is int ? v : int.tryParse(v?.toString() ?? '0') ?? 0;
      });
    }

    final open = json['open'] is int ? json['open'] : int.tryParse(json['open']?.toString() ?? '0') ?? 0;
    final reviewed = json['reviewed'] is int ? json['reviewed'] : int.tryParse(json['reviewed']?.toString() ?? '0') ?? 0;

    return MonitoringSummaryModel(
      totalToday: json['total_today'] is int
          ? json['total_today']
          : int.tryParse(json['total_today']?.toString() ?? json['today']?.toString() ?? '0') ?? 0,
      openCount: open,
      reviewedCount: reviewed,
      resolvedCount: json['resolved'] is int ? json['resolved'] : int.tryParse(json['resolved']?.toString() ?? '0') ?? 0,
      ignoredCount: json['ignored'] is int ? json['ignored'] : int.tryParse(json['ignored']?.toString() ?? '0') ?? 0,
      highCount: json['high'] is int ? json['high'] : int.tryParse(json['high']?.toString() ?? '0') ?? 0,
      criticalCount: json['critical'] is int ? json['critical'] : int.tryParse(json['critical']?.toString() ?? '0') ?? 0,
      totalOpen: json['total_open'] is int ? json['total_open'] : (open + reviewed),
      byType: bt,
    );
  }
}

class MonitoringRuleItem {
  final int id;
  final String ruleType;
  final String ruleTypeDisplay;
  final String nameFa;
  final String description;
  final bool enabled;

  final double warningThreshold;
  final double highThreshold;
  final double criticalThreshold;

  final double percentageWarning;
  final double percentageHigh;
  final double percentageCritical;

  final int minimumHistory;
  final Map<String, dynamic> extraParams;
  final String? updatedAt;
  final String? updatedByName;

  MonitoringRuleItem({
    required this.id,
    required this.ruleType,
    required this.ruleTypeDisplay,
    required this.nameFa,
    required this.description,
    required this.enabled,
    required this.warningThreshold,
    required this.highThreshold,
    required this.criticalThreshold,
    required this.percentageWarning,
    required this.percentageHigh,
    required this.percentageCritical,
    required this.minimumHistory,
    required this.extraParams,
    this.updatedAt,
    this.updatedByName,
  });

  factory MonitoringRuleItem.fromJson(Map<String, dynamic> json) {
    return MonitoringRuleItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      ruleType: json['rule_type']?.toString() ?? json['code']?.toString() ?? '',
      ruleTypeDisplay: json['rule_type_display']?.toString() ?? json['name']?.toString() ?? '',
      nameFa: json['name_fa']?.toString() ?? json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      enabled: json['enabled'] != false,
      warningThreshold: double.tryParse(json['warning_threshold']?.toString() ?? '') ?? 0.0,
      highThreshold: double.tryParse(json['high_threshold']?.toString() ?? '') ?? 0.0,
      criticalThreshold: double.tryParse(json['critical_threshold']?.toString() ?? '') ?? 0.0,
      percentageWarning: double.tryParse(json['percentage_warning']?.toString() ?? '') ?? 0.0,
      percentageHigh: double.tryParse(json['percentage_high']?.toString() ?? '') ?? 0.0,
      percentageCritical: double.tryParse(json['percentage_critical']?.toString() ?? '') ?? 0.0,
      minimumHistory: json['minimum_history'] is int
          ? json['minimum_history']
          : int.tryParse(json['minimum_history']?.toString() ?? '10') ?? 10,
      extraParams: json['extra_params'] is Map<String, dynamic>
          ? json['extra_params'] as Map<String, dynamic>
          : <String, dynamic>{},
      updatedAt: json['updated_at']?.toString(),
      updatedByName: json['updated_by_name']?.toString(),
    );
  }
}

class TicketAnalysisSummary {
  final int ticketId;
  final String serialNumber;
  final int riskScore;
  final String riskLevel;
  final bool hasCritical;
  final bool hasHigh;
  final int openAlertsCount;
  final List<MonitoringAlertItem> alerts;

  TicketAnalysisSummary({
    required this.ticketId,
    required this.serialNumber,
    required this.riskScore,
    required this.riskLevel,
    required this.hasCritical,
    required this.hasHigh,
    required this.openAlertsCount,
    required this.alerts,
  });

  factory TicketAnalysisSummary.fromJson(Map<String, dynamic> json) {
    List<MonitoringAlertItem> alertList = [];
    if (json['alerts'] is List) {
      alertList = (json['alerts'] as List)
          .map((e) => MonitoringAlertItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return TicketAnalysisSummary(
      ticketId: json['ticket_id'] is int ? json['ticket_id'] : int.tryParse(json['ticket_id']?.toString() ?? '0') ?? 0,
      serialNumber: json['serial_number']?.toString() ?? '',
      riskScore: json['risk_score'] is int ? json['risk_score'] : int.tryParse(json['risk_score']?.toString() ?? '0') ?? 0,
      riskLevel: json['risk_level']?.toString() ?? 'NORMAL',
      hasCritical: json['has_critical'] == true,
      hasHigh: json['has_high'] == true,
      openAlertsCount: json['open_alerts_count'] is int
          ? json['open_alerts_count']
          : int.tryParse(json['open_alerts_count']?.toString() ?? '0') ?? 0,
      alerts: alertList,
    );
  }

  Color get riskLevelColor {
    switch (riskLevel.toUpperCase()) {
      case 'CRITICAL':
        return AppColors.riskCritical;
      case 'HIGH_RISK':
        return AppColors.riskHigh;
      case 'NEEDS_REVIEW':
        return AppColors.riskMedium;
      case 'LOW_RISK':
        return AppColors.riskLow;
      case 'NORMAL':
      default:
        return AppColors.success;
    }
  }

  String get riskLevelTitle {
    switch (riskLevel.toUpperCase()) {
      case 'CRITICAL':
        return 'بحرانی (Critical)';
      case 'HIGH_RISK':
        return 'ریسک بالا (High Risk)';
      case 'NEEDS_REVIEW':
        return 'نیازمند بررسی (Needs Review)';
      case 'LOW_RISK':
        return 'ریسک پایین (Low Risk)';
      case 'NORMAL':
      default:
        return 'عادی (Normal)';
    }
  }
}
