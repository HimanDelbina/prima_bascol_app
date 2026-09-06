import 'package:flutter_test/flutter_test.dart';
import 'package:prima_bascol_app/features/monitoring/domain/monitoring_models.dart';

void main() {
  group('Monitoring Models Tests', () {
    test('MonitoringAlertItem parses complete backend JSON accurately', () {
      final json = {
        'id': 101,
        'ticket': 55,
        'ticket_serial': 'T-2026-001',
        'ticket_plate': '12 ع 345 - ایران 67',
        'product_name': 'آهن اسفنجی',
        'party_name': 'فولاد مبارکه',
        'alert_type': {
          'code': 'VEHICLE_TARE_ANOMALY',
          'title': 'وزن خالی غیرعادی خودرو',
        },
        'severity': {
          'code': 'HIGH',
          'title': 'بالا (High)',
        },
        'status': {
          'code': 'OPEN',
          'title': 'باز',
        },
        'confidence': {
          'code': 'high',
          'title': 'بالا (۵۰+ نمونه)',
        },
        'title': 'انحراف وزن خالی خودرو',
        'description': 'وزن خالی ثبت‌شده ۶۴۰ کیلوگرم با میانگین تاریخی تفاوت دارد.',
        'reason': 'وزن خالی فعلی خودرو ۱۰,۴۲۰ کیلوگرم است. میانگین وزن خالی این خودرو در ۴۸ سرویس قبلی ۹,۷۸۰ کیلوگرم بوده است. اختلاف ۶۴۰ کیلوگرم معادل ۶.۵۴٪ است.',
        'current_value': '10420.00',
        'baseline_value': '9780.00',
        'deviation_value': '640.00',
        'deviation_percent': '6.54',
        'sample_size': 48,
        'baseline_source': 'VEHICLE',
        'created_at_jalali': '1405/06/01 10:30',
        'metadata': {
          'average': 9780.0,
          'median': 9775.0,
          'stddev': 120.5,
          'min': 9500.0,
          'max': 10100.0,
          'last_5_average': 9790.0,
        },
        'historical_summary': {
          'average': 9780.0,
          'median': 9775.0,
          'stddev': 120.5,
          'min': 9500.0,
          'max': 10100.0,
          'sample_size': 48,
          'last_5_average': 9790.0,
        },
      };

      final alert = MonitoringAlertItem.fromJson(json);

      expect(alert.id, 101);
      expect(alert.ticketId, 55);
      expect(alert.ticketSerial, 'T-2026-001');
      expect(alert.ticketPlate, '12 ع 345 - ایران 67');
      expect(alert.productName, 'آهن اسفنجی');
      expect(alert.partyName, 'فولاد مبارکه');
      expect(alert.alertTypeCode, 'VEHICLE_TARE_ANOMALY');
      expect(alert.severityCode, 'HIGH');
      expect(alert.statusCode, 'OPEN');
      expect(alert.confidenceCode, 'high');
      expect(alert.currentValue, 10420.0);
      expect(alert.baselineValue, 9780.0);
      expect(alert.deviationValue, 640.0);
      expect(alert.deviationPercent, 6.54);
      expect(alert.sampleSize, 48);
      expect(alert.baselineSource, 'VEHICLE');
      expect(alert.baselineSourceFa, 'سوابق تاریخی این خودرو');
      expect(alert.confidenceExplanation.contains('بیش از ۵۰'), isTrue);
      expect(alert.historicalSummary?['median'], 9775.0);
    });

    test('MonitoringSummaryModel parses aggregate counters correctly', () {
      final json = {
        'total_today': 14,
        'today': 14,
        'open': 6,
        'reviewed': 4,
        'resolved': 3,
        'ignored': 1,
        'high': 4,
        'critical': 2,
        'total_open': 10,
        'by_type': {
          'VEHICLE_TARE_ANOMALY': 4,
          'WEIGHT_DISCREPANCY': 3,
          'LOSS_ANOMALY': 2,
          'LONG_WAITING_TIME': 1,
        },
      };

      final summary = MonitoringSummaryModel.fromJson(json);

      expect(summary.totalToday, 14);
      expect(summary.openCount, 6);
      expect(summary.reviewedCount, 4);
      expect(summary.resolvedCount, 3);
      expect(summary.ignoredCount, 1);
      expect(summary.highCount, 4);
      expect(summary.criticalCount, 2);
      expect(summary.totalOpen, 10);
      expect(summary.byType['VEHICLE_TARE_ANOMALY'], 4);
      expect(summary.byType['WEIGHT_DISCREPANCY'], 3);
    });

    test('MonitoringRuleItem parses configuration thresholds and parameters', () {
      final json = {
        'id': 1,
        'rule_type': 'VEHICLE_TARE_ANOMALY',
        'rule_type_display': 'وزن خالی غیرعادی خودرو',
        'name_fa': 'تحلیل وزن خالی غیرعادی خودرو',
        'description': 'پایش انحراف وزن خالی ثبت‌شده نسبت به میانگین تاریخی',
        'enabled': true,
        'warning_threshold': '300.00',
        'high_threshold': '500.00',
        'critical_threshold': '800.00',
        'percentage_warning': '3.00',
        'percentage_high': '5.00',
        'percentage_critical': '8.00',
        'minimum_history': 10,
      };

      final rule = MonitoringRuleItem.fromJson(json);

      expect(rule.id, 1);
      expect(rule.ruleType, 'VEHICLE_TARE_ANOMALY');
      expect(rule.enabled, isTrue);
      expect(rule.warningThreshold, 300.0);
      expect(rule.highThreshold, 500.0);
      expect(rule.criticalThreshold, 800.0);
      expect(rule.percentageWarning, 3.0);
      expect(rule.percentageHigh, 5.0);
      expect(rule.percentageCritical, 8.0);
      expect(rule.minimumHistory, 10);
    });

    test('TicketAnalysisSummary parses risk scores and level styles', () {
      final json = {
        'ticket_id': 99,
        'serial_number': 'T-99',
        'risk_score': 65,
        'risk_level': 'HIGH_RISK',
        'has_critical': false,
        'has_high': true,
        'open_alerts_count': 2,
        'alerts': [
          {
            'id': 1,
            'alert_type': 'WEIGHT_DISCREPANCY',
            'severity': 'HIGH',
            'status': 'OPEN',
            'title': 'مغایرت بارنامه',
            'reason': 'اختلاف ۱۵۰ کیلوگرمی',
            'sample_size': 12,
          }
        ],
      };

      final analysis = TicketAnalysisSummary.fromJson(json);

      expect(analysis.ticketId, 99);
      expect(analysis.riskScore, 65);
      expect(analysis.riskLevel, 'HIGH_RISK');
      expect(analysis.riskLevelTitle.contains('High Risk'), isTrue);
      expect(analysis.hasHigh, isTrue);
      expect(analysis.hasCritical, isFalse);
      expect(analysis.openAlertsCount, 2);
      expect(analysis.alerts.length, 1);
      expect(analysis.alerts.first.alertTypeCode, 'WEIGHT_DISCREPANCY');
    });
  });
}
