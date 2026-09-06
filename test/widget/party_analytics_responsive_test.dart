import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prima_bascol_app/features/management/domain/party_analytics_models.dart';
import 'package:prima_bascol_app/features/management/presentation/management_providers.dart';
import 'package:prima_bascol_app/features/management/presentation/party_comparison_screen.dart';
import 'package:prima_bascol_app/features/management/presentation/party_detail_analytics_screen.dart';
import 'package:prima_bascol_app/features/management/presentation/party_ranking_screen.dart';

PartyRankingItem createDummyItem(int id, String name, double score) {
  return PartyRankingItem(
    rank: id,
    partyId: id,
    partyName: name,
    partyCode: 'PRT-$id',
    partyType: 'supplier',
    partyTypeFa: 'تأمین‌کننده',
    overallScore: score,
    scoreLevel: 'GOOD',
    scoreLevelFa: 'خوب',
    confidence: 'HIGH',
    confidenceFa: 'بالا',
    completedTickets: 120,
    totalTonnage: 3200.0,
    avgDiscrepancyKg: 24.5,
    avgLossPercent: 0.45,
    alertRate: 1.5,
    avgTurnaroundMin: 45.0,
    weightAccuracyScore: 92.0,
    lossPerformanceScore: 86.0,
    consistencyScore: 84.0,
    monitoringQualityScore: 88.0,
    operationalEfficiencyScore: 90.0,
    dataReliabilityScore: 95.0,
    percentile: 85.0,
    explanation: PartyScoreExplanation(
      positivePoints: ['دقت وزنی مطلوب', 'فاقد هشدار بحرانی'],
      attentionPoints: ['۱ مورد ویرایش وزن'],
    ),
  );
}

PartyDetailAnalytics createDummyDetail() {
  return PartyDetailAnalytics(
    party: {'id': 101, 'name': 'شرکت تامین فولاد خوزستان', 'code': 'PRT-101'},
    profile: PartyAnalyticsProfile(
      partyId: 101,
      partyName: 'شرکت تامین فولاد خوزستان',
      partyType: 'supplier',
      partyTypeDisplay: 'تأمین‌کننده',
      totalTickets: 125,
      completedTickets: 120,
      cancelledTickets: 5,
      totalNetWeightKg: 3200000.0,
      totalNetWeightTon: 3200.0,
      totalFinalWeightKg: 3185000.0,
      totalFinalWeightTon: 3185.0,
      averageNetWeightKg: 26666.0,
      averageFinalWeightKg: 26541.0,
      minNetWeightKg: 20000.0,
      maxNetWeightKg: 30000.0,
      firstTicketDateFa: '1405/01/05',
      lastTicketDateFa: '1405/06/20',
      activeDays: 60,
    ),
    discrepancyMetrics: PartyDiscrepancyMetrics(
      totalDiscrepancyKg: -450.0,
      avgSignedDiscrepancyKg: -3.7,
      avgAbsoluteDiscrepancyKg: 24.5,
      medianAbsoluteDiscrepancyKg: 20.0,
      maxAbsoluteDiscrepancyKg: 50.0,
      avgDiscrepancyPercent: 0.1,
      discrepancyStddev: 14.0,
      ticketsWithDiscrepancy: 2,
      discrepancyRate: 1.6,
      ticketsWithSentWeight: 120,
      missingSentWeightRate: 0.0,
    ),
    lossMetrics: PartyLossMetrics(
      totalLossWeight: 15000.0,
      avgLossWeight: 125.0,
      avgLossPercent: 0.45,
      medianLossPercent: 0.40,
      maxLossPercent: 0.90,
      lossStddev: 0.15,
      ticketsWithLoss: 120,
      lossRate: 100.0,
    ),
    monitoringMetrics: PartyMonitoringMetrics(
      totalAlerts: 2,
      openAlerts: 0,
      reviewedAlerts: 1,
      resolvedAlerts: 1,
      ignoredAlerts: 0,
      lowAlerts: 1,
      mediumAlerts: 1,
      highAlerts: 0,
      criticalAlerts: 0,
      alertsPer100Tickets: 1.67,
      breakdownByType: {'LONG_WAITING_TIME': 1, 'WEIGHT_DISCREPANCY': 1},
    ),
    turnaroundMetrics: PartyTurnaroundMetrics(
      avgTurnaroundMinutes: 45.0,
      medianTurnaroundMinutes: 42.0,
      maxTurnaroundMinutes: 80.0,
      turnaroundStddev: 12.0,
      longWaitingTicketCount: 0,
      longWaitingRate: 0.0,
    ),
    correctionMetrics: PartyCorrectionMetrics(
      weightCorrectionCount: 1,
      lossOverrideCount: 0,
      cancelCount: 5,
      ticketsWithCorrection: 1,
      correctionRate: 0.8,
    ),
    consistencyMetrics: PartyConsistencyMetrics(
      isSufficientSample: true,
      weightStddev: 1200.0,
      weightVariationCoef: 0.045,
      lossStddev: 0.15,
      lossVariationCoef: 0.33,
    ),
    score: PartyScoreBreakdown(
      overallScore: 86.4,
      rawScore: 86.4,
      level: 'GOOD',
      levelFa: 'خوب',
      confidence: 'HIGH',
      confidenceFa: 'بالا',
      isScoreReliable: true,
      dimensionScores: {
        'weight_accuracy': 92.0,
        'loss_performance': 86.0,
        'consistency': 84.0,
        'monitoring_quality': 88.0,
        'operational_efficiency': 90.0,
        'data_reliability': 95.0,
      },
      dimensionWeights: {
        'weight_accuracy': 30.0,
        'loss_performance': 20.0,
        'consistency': 15.0,
        'monitoring_quality': 20.0,
        'operational_efficiency': 10.0,
        'data_reliability': 5.0,
      },
      explanation: PartyScoreExplanation(
        positivePoints: ['دقت وزنی مطلوب', 'فاقد هشدار بحرانی'],
        attentionPoints: ['۱ مورد ویرایش وزن'],
      ),
      calculationVersion: 'party_score_v1',
    ),
  );
}

PartyTrendModel createDummyTrend() {
  final d = createDummyDetail();
  return PartyTrendModel(
    period: {'current_start_fa': '1405/01/01', 'current_end_fa': '1405/01/30'},
    kpiComparison: {
      'score': MetricComparisonModel(current: 88.0, previous: 82.0, deltaAbs: 6.0, deltaPercent: 7.3, direction: 'IMPROVING'),
    },
    currentAnalysis: d,
    previousAnalysis: d,
  );
}

void main() {
  const resolutions = [
    Size(375, 667),   // Mobile Small
    Size(430, 932),   // Mobile Large
    Size(768, 1024),  // Tablet
    Size(1024, 768),  // Small Desktop
    Size(1366, 768),  // Standard Desktop
    Size(1920, 1080), // Full HD Desktop
  ];

  group('Party Analytics Multi-Resolution Responsive Validation', () {
    for (final size in resolutions) {
      testWidgets('PartyRankingScreen at ${size.width.toInt()}x${size.height.toInt()} has 0 overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final items = [
          createDummyItem(1, 'فولاد خوزستان', 91.0),
          createDummyItem(2, 'فولاد مبارکه', 86.5),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              partyRankingProvider.overrideWith((ref) => Future.value(items)),
            ],
            child: const MaterialApp(
              home: Directionality(
                textDirection: TextDirection.rtl,
                child: PartyRankingScreen(),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Render overflow detected at ${size.width}x${size.height}');
      });

      testWidgets('PartyDetailAnalyticsScreen at ${size.width.toInt()}x${size.height.toInt()} has 0 overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final detail = createDummyDetail();
        final trend = createDummyTrend();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              partyAnalyticsDetailProvider(101).overrideWith((ref) => Future.value(detail)),
              partyTrendProvider(101).overrideWith((ref) => Future.value(trend)),
            ],
            child: const MaterialApp(
              home: Directionality(
                textDirection: TextDirection.rtl,
                child: PartyDetailAnalyticsScreen(partyId: 101),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Render overflow detected at ${size.width}x${size.height}');
      });

      testWidgets('PartyComparisonScreen at ${size.width.toInt()}x${size.height.toInt()} has 0 overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final items = [
          createDummyItem(1, 'فولاد خوزستان', 91.0),
          createDummyItem(2, 'فولاد مبارکه', 86.5),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              partyRankingProvider.overrideWith((ref) => Future.value(items)),
            ],
            child: const MaterialApp(
              home: Directionality(
                textDirection: TextDirection.rtl,
                child: PartyComparisonScreen(),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Render overflow detected at ${size.width}x${size.height}');
      });
    }
  });
}
