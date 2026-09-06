import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:prima_bascol_app/core/constants/app_colors.dart';
import 'package:prima_bascol_app/features/management/domain/party_analytics_models.dart';

void main() {
  group('Party Analytics Domain Models Tests', () {
    test('PartyRankingItem parses valid JSON with overallScore correctly', () {
      final json = {
        'rank': 1,
        'percentile': 100.0,
        'party_id': 10,
        'party_name': 'شرکت فولاد هرمزگان',
        'party_code': 'PRT-10',
        'party_type': 'supplier',
        'party_type_fa': 'تأمین‌کننده',
        'overall_score': 88.5,
        'score_level': 'GOOD',
        'score_level_fa': 'خوب',
        'confidence': 'HIGH',
        'confidence_fa': 'بالا',
        'completed_tickets': 140,
        'total_tonnage': 3500.5,
        'avg_discrepancy_kg': 22.4,
        'avg_loss_percent': 0.42,
        'alert_rate': 1.8,
        'avg_turnaround_min': 42.0,
        'weight_accuracy_score': 94.0,
        'loss_performance_score': 88.0,
        'consistency_score': 82.0,
        'monitoring_quality_score': 85.0,
        'operational_efficiency_score': 90.0,
        'data_reliability_score': 95.0,
        'explanation': {
          'positive_points': ['دقت وزنی بالا', 'سرعت تخلیه مطلوب'],
          'attention_points': ['۲ مورد اصلاح وزن'],
        },
      };

      final item = PartyRankingItem.fromJson(json);

      expect(item.rank, 1);
      expect(item.partyName, 'شرکت فولاد هرمزگان');
      expect(item.overallScore, 88.5);
      expect(item.scoreLevelFa, 'خوب');
      expect(item.confidence, 'HIGH');
      expect(item.completedTickets, 140);
      expect(item.explanation.positivePoints.length, 2);
      expect(item.explanation.attentionPoints.length, 1);
      expect(item.scoreColor, AppColors.primaryLight);
      expect(item.confidenceColor, AppColors.success);
    });

    test('PartyRankingItem handles null overallScore when confidence is INSUFFICIENT', () {
      final json = {
        'rank': 5,
        'percentile': 20.0,
        'party_id': 15,
        'party_name': 'تأمین‌کننده آزمایشی',
        'party_type': 'supplier',
        'party_type_fa': 'تأمین‌کننده',
        'overall_score': null,
        'score_level': 'NEEDS_ATTENTION',
        'score_level_fa': 'نیازمند بررسی',
        'confidence': 'INSUFFICIENT',
        'confidence_fa': 'داده ناکافی',
        'completed_tickets': 4,
        'total_tonnage': 80.0,
        'avg_discrepancy_kg': 15.0,
        'avg_loss_percent': 0.5,
        'alert_rate': 0.0,
        'avg_turnaround_min': 50.0,
        'weight_accuracy_score': 70.0,
        'loss_performance_score': 70.0,
        'consistency_score': 70.0,
        'monitoring_quality_score': 100.0,
        'operational_efficiency_score': 80.0,
        'data_reliability_score': 30.0,
        'explanation': null,
      };

      final item = PartyRankingItem.fromJson(json);

      expect(item.overallScore, isNull);
      expect(item.confidence, 'INSUFFICIENT');
      expect(item.scoreColor, Colors.grey);
      expect(item.confidenceColor, Colors.grey);
      expect(item.explanation.positivePoints, isEmpty);
    });

    test('PartyDetailAnalytics parses full nested metrics correctly', () {
      final json = {
        'party': {'id': 1, 'name': 'فولاد خوزستان'},
        'profile': {
          'party_id': 1,
          'party_name': 'فولاد خوزستان',
          'party_type': 'supplier',
          'party_type_display': 'تأمین‌کننده',
          'total_tickets': 50,
          'completed_tickets': 48,
          'cancelled_tickets': 2,
          'total_net_weight_kg': 1200000.0,
          'total_net_weight_ton': 1200.0,
          'total_final_weight_kg': 1195000.0,
          'total_final_weight_ton': 1195.0,
          'average_net_weight_kg': 25000.0,
          'average_final_weight_kg': 24895.0,
          'min_net_weight_kg': 18000.0,
          'max_net_weight_kg': 28000.0,
          'first_ticket_date_fa': '1405/01/10',
          'last_ticket_date_fa': '1405/06/15',
          'active_days': 35,
        },
        'discrepancy_metrics': {
          'total_discrepancy_kg': -350.0,
          'average_signed_discrepancy_kg': -7.3,
          'average_absolute_discrepancy_kg': 18.5,
          'median_absolute_discrepancy_kg': 15.0,
          'maximum_absolute_discrepancy_kg': 45.0,
          'average_discrepancy_percent': 0.08,
          'discrepancy_stddev': 12.0,
          'tickets_with_discrepancy': 1,
          'discrepancy_rate': 2.1,
          'tickets_with_sent_weight': 48,
          'missing_sent_weight_rate': 0.0,
        },
        'loss_metrics': {
          'total_loss_weight': 5000.0,
          'average_loss_weight': 104.2,
          'average_loss_percent': 0.42,
          'median_loss_percent': 0.40,
          'maximum_loss_percent': 0.85,
          'loss_stddev': 0.12,
          'tickets_with_loss': 48,
          'loss_rate': 100.0,
        },
        'monitoring_metrics': {
          'total_alerts': 3,
          'open_alerts': 1,
          'reviewed_alerts': 1,
          'resolved_alerts': 1,
          'ignored_alerts': 0,
          'low_alerts': 2,
          'medium_alerts': 1,
          'high_alerts': 0,
          'critical_alerts': 0,
          'alerts_per_100_tickets': 6.25,
          'breakdown_by_type': {
            'WEIGHT_DISCREPANCY': 1,
            'LONG_WAITING_TIME': 2,
          },
        },
        'turnaround_metrics': {
          'average_turnaround_minutes': 48.0,
          'median_turnaround_minutes': 45.0,
          'max_turnaround_minutes': 90.0,
          'turnaround_stddev': 15.0,
          'long_waiting_ticket_count': 0,
          'long_waiting_rate': 0.0,
        },
        'correction_metrics': {
          'weight_correction_count': 0,
          'loss_override_count': 1,
          'cancel_count': 2,
          'tickets_with_correction': 1,
          'correction_rate': 2.1,
        },
        'consistency_metrics': {
          'is_sufficient_sample': true,
          'weight_stddev': 1500.0,
          'weight_variation_coef': 0.06,
          'loss_stddev': 0.12,
          'loss_variation_coef': 0.28,
        },
        'score': {
          'overall_score': 91.2,
          'raw_score': 91.2,
          'level': 'EXCELLENT',
          'level_fa': 'عالی',
          'confidence': 'MEDIUM',
          'confidence_fa': 'متوسط',
          'is_score_reliable': true,
          'dimension_scores': {
            'weight_accuracy': 96.0,
            'loss_performance': 92.0,
            'consistency': 95.0,
            'monitoring_quality': 88.0,
            'operational_efficiency': 92.0,
            'data_reliability': 80.0,
          },
          'dimension_weights': {
            'weight_accuracy': 30,
            'loss_performance': 20,
            'consistency': 15,
            'monitoring_quality': 20,
            'operational_efficiency': 10,
            'data_reliability': 5,
          },
          'calculation_version': 'party_score_v1',
          'explanation': {
            'positive_points': ['دقت وزنی عالی', 'عدم وجود هشدار بحرانی'],
            'attention_points': ['۱ مورد هشدار با اولویت متوسط'],
          },
        },
      };

      final detail = PartyDetailAnalytics.fromJson(json);

      expect(detail.profile.completedTickets, 48);
      expect(detail.discrepancyMetrics.avgAbsoluteDiscrepancyKg, 18.5);
      expect(detail.lossMetrics.avgLossPercent, 0.42);
      expect(detail.monitoringMetrics.totalAlerts, 3);
      expect(detail.monitoringMetrics.criticalAlerts, 0);
      expect(detail.turnaroundMetrics.avgTurnaroundMinutes, 48.0);
      expect(detail.score.overallScore, 91.2);
      expect(detail.score.levelFa, 'عالی');
      expect(detail.score.isScoreReliable, true);
    });
  });
}
