import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prima_bascol_app/core/routing/route_names.dart';
import 'package:prima_bascol_app/features/management/domain/party_analytics_models.dart';
import 'package:prima_bascol_app/features/management/presentation/management_providers.dart';
import 'package:prima_bascol_app/features/management/presentation/management_screen.dart';
import 'package:prima_bascol_app/features/management/presentation/party_ranking_screen.dart';
import 'package:prima_bascol_app/features/management/presentation/party_detail_analytics_screen.dart';

PartyRankingItem createDummyRankingItem({
  int rank = 1,
  String name = 'شرکت تامین فولاد خوزستان',
  double? score = 86.4,
  String levelFa = 'خوب',
  String confidence = 'HIGH',
}) {
  return PartyRankingItem(
    rank: rank,
    percentile: 95.0,
    partyId: 101,
    partyName: name,
    partyCode: 'PRT-101',
    partyType: 'supplier',
    partyTypeFa: 'تأمین‌کننده',
    overallScore: score,
    scoreLevel: 'GOOD',
    scoreLevelFa: levelFa,
    confidence: confidence,
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
    explanation: PartyScoreExplanation(
      positivePoints: ['دقت وزنی مطلوب', 'فاقد هشدار بحرانی'],
      attentionPoints: ['۱ مورد ویرایش وزن'],
    ),
  );
}

PartyDetailAnalytics createDummyDetailAnalytics({bool reliable = true}) {
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
      overallScore: reliable ? 86.4 : null,
      rawScore: 86.4,
      level: 'GOOD',
      levelFa: 'خوب',
      confidence: reliable ? 'HIGH' : 'INSUFFICIENT',
      confidenceFa: reliable ? 'بالا' : 'داده ناکافی',
      isScoreReliable: reliable,
      dimensionScores: {
        'weight_accuracy': 92.0,
        'loss_performance': 86.0,
        'consistency': 84.0,
        'monitoring_quality': 88.0,
        'operational_efficiency': 90.0,
        'data_reliability': 95.0,
      },
      dimensionWeights: {
        'weight_accuracy': 30,
        'loss_performance': 20,
        'consistency': 15,
        'monitoring_quality': 20,
        'operational_efficiency': 10,
        'data_reliability': 5,
      },
      calculationVersion: 'party_score_v1',
      explanation: PartyScoreExplanation(
        positivePoints: ['میانگین اختلاف وزن فقط ۲۴.۵ کیلوگرم است.', 'فاقد هرگونه هشدار پایش بحرانی.'],
        attentionPoints: ['ثبت ۱ مورد اصلاح دستی اوزان در قبوض.'],
      ),
    ),
  );
}

PartyTrendModel createDummyTrend() {
  final dummy = createDummyDetailAnalytics(reliable: true);
  return PartyTrendModel(
    period: {'current_start_fa': '1405/01/01', 'current_end_fa': '1405/01/30'},
    kpiComparison: {
      'score': MetricComparisonModel(current: 85.0, previous: 80.0, deltaAbs: 5.0, deltaPercent: 6.25, direction: 'IMPROVING'),
    },
    currentAnalysis: dummy,
    previousAnalysis: dummy,
  );
}

void main() {
  group('Party Ranking Screen Widget Tests', () {
    testWidgets('PartyRankingScreen renders table on desktop and cards on mobile without overflow', (tester) async {
      final items = [
        createDummyRankingItem(rank: 1, name: 'فولاد خوزستان', score: 88.5),
        createDummyRankingItem(rank: 2, name: 'فولاد مبارکه', score: 84.0),
      ];

      // 1. Desktop 1280x800
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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

      expect(find.text('رتبه‌بندی و ارزیابی طرف‌های حساب'), findsOneWidget);
      expect(find.text('فولاد خوزستان'), findsOneWidget);
      expect(find.text('فولاد مبارکه'), findsOneWidget);
      expect(find.byType(DataTable), findsOneWidget);

      // 2. Mobile 375x667
      tester.view.physicalSize = const Size(375, 667);
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

      expect(find.text('#1'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);
      expect(find.text('مشاهده تحلیل'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('PartyDetailAnalyticsScreen renders KPIs and score bars without overflow', (tester) async {
      final detail = createDummyDetailAnalytics(reliable: true);

      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            partyAnalyticsDetailProvider(101).overrideWith((ref) => Future.value(detail)),
            partyTrendProvider(101).overrideWith((ref) => Future.value(createDummyTrend())),
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

      expect(find.text('کارنامه تحلیلی و امتیاز طرف‌حساب'), findsOneWidget);
      expect(find.text('شرکت تامین فولاد خوزستان'), findsOneWidget);
      expect(find.text('86.4'), findsOneWidget);
      expect(find.text('خوب'), findsOneWidget);
      expect(find.text('تعداد بار تکمیل‌شده'), findsOneWidget);
      expect(find.text('تفکیک ابعاد ۶ گانه ارزیابی عملکرد (0-100)'), findsOneWidget);
      expect(find.text('تحلیل و دلایل امتیاز (چرا این امتیاز؟)'), findsOneWidget);
      expect(find.text('میانگین اختلاف وزن فقط ۲۴.۵ کیلوگرم است.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('PartyDetailAnalyticsScreen shows insufficient data banner when sample is low', (tester) async {
      final detail = createDummyDetailAnalytics(reliable: false);

      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            partyAnalyticsDetailProvider(101).overrideWith((ref) => Future.value(detail)),
            partyTrendProvider(101).overrideWith((ref) => Future.value(createDummyTrend())),
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

      expect(find.text('داده ناکافی'), findsWidgets);
      expect(find.textContaining('داده کافی برای امتیازدهی معتبر وجود ندارد'), findsOneWidget);
    });

    testWidgets('ManagementScreen banner button navigates to PartyRankingScreen via GoRouter', (tester) async {
      final items = [createDummyRankingItem(rank: 1, name: 'تست')];
      final router = GoRouter(
        initialLocation: AppRoutes.management,
        routes: [
          GoRoute(
            path: AppRoutes.management,
            builder: (context, state) => const Directionality(
              textDirection: TextDirection.rtl,
              child: ManagementScreen(),
            ),
            routes: [
              GoRoute(
                path: 'parties/ranking',
                name: 'partyRanking',
                builder: (context, state) => const Directionality(
                  textDirection: TextDirection.rtl,
                  child: PartyRankingScreen(),
                ),
              ),
            ],
          ),
        ],
      );

      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            managementSummaryProvider.overrideWith((ref) => Future.value(null)),
            managementProductsProvider.overrideWith((ref) => Future.value([])),
            managementPartiesProvider.overrideWith((ref) => Future.value([])),
            partyRankingProvider.overrideWith((ref) => Future.value(items)),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final button = find.text('مشاهده رتبه‌بندی');
      expect(button, findsOneWidget);

      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.text('رتبه‌بندی و ارزیابی طرف‌های حساب'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
