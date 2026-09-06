import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prima_bascol_app/features/monitoring/domain/monitoring_models.dart';
import 'package:prima_bascol_app/features/monitoring/presentation/monitoring_providers.dart';
import 'package:prima_bascol_app/features/monitoring/presentation/monitoring_screen.dart';
import 'package:prima_bascol_app/features/monitoring/presentation/widgets/alert_detail_sheet.dart';

void main() {
  final testAlert = MonitoringAlertItem(
    id: 1,
    ticketId: 10,
    ticketSerial: 'T-100',
    ticketPlate: '12 ع 345 - ایران 67',
    productName: 'آهن اسفنجی',
    partyName: 'فولاد مبارکه',
    alertTypeCode: 'VEHICLE_TARE_ANOMALY',
    alertTypeTitle: 'وزن خالی غیرعادی خودرو',
    severityCode: 'HIGH',
    severityTitle: 'بالا (High)',
    statusCode: 'OPEN',
    statusTitle: 'باز',
    confidenceCode: 'high',
    confidenceTitle: 'بالا (۵۰+ نمونه)',
    title: 'انحراف وزن خالی خودرو',
    description: 'وزن خالی ثبت‌شده ۶۴۰ کیلوگرم با میانگین تاریخی تفاوت دارد.',
    reason: 'وزن خالی فعلی خودرو ۱۰,۴۲۰ کیلوگرم است. میانگین وزن خالی این خودرو ۹,۷۸۰ کیلوگرم بوده است.',
    currentValue: 10420.0,
    baselineValue: 9780.0,
    deviationValue: 640.0,
    deviationPercent: 6.54,
    sampleSize: 48,
    baselineSource: 'VEHICLE',
    createdAtJalali: '1405/06/01 10:30',
    metadata: {
      'average': 9780.0,
      'median': 9775.0,
      'min': 9500.0,
      'max': 10100.0,
    },
  );

  final testSummary = MonitoringSummaryModel(
    totalToday: 5,
    openCount: 3,
    reviewedCount: 1,
    resolvedCount: 1,
    ignoredCount: 0,
    highCount: 2,
    criticalCount: 1,
    totalOpen: 4,
    byType: {'VEHICLE_TARE_ANOMALY': 2},
  );

  Widget createTestWidget(Widget child, {List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: child,
        ),
      ),
    );
  }

  group('Monitoring Widget Tests', () {
    testWidgets('AlertDetailSheet renders explainable reason and quantitative metrics', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestWidget(
          Scaffold(
            body: AlertDetailSheet(alert: testAlert),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check title and explainable reason
      expect(find.text('انحراف وزن خالی خودرو'), findsOneWidget);
      expect(find.textContaining('وزن خالی فعلی خودرو ۱۰,۴۲۰ کیلوگرم است'), findsOneWidget);

      // Check values
      expect(find.text('مقدار فعلی این قبض'), findsOneWidget);
      expect(find.text('میانگین مبنای تاریخی'), findsOneWidget);
      expect(find.text('درصد انحراف نسبی'), findsOneWidget);
      expect(find.text('6.54٪'), findsOneWidget);

      // Check action buttons for open alert
      expect(find.text('اقدام شد / حل هشدار'), findsOneWidget);
      expect(find.text('بررسی شد (تحت بررسی)'), findsOneWidget);
      expect(find.text('نادیده‌گرفتن'), findsOneWidget);
    });

    testWidgets('MonitoringScreen renders KPI summary and alert list in Desktop mode', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestWidget(
          const MonitoringScreen(),
          overrides: [
            monitoringSummaryProvider.overrideWith((ref) => Future.value(testSummary)),
            monitoringAlertsProvider.overrideWith((ref) => Future.value([testAlert])),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Check KPIs
      expect(find.text('هشدارهای امروز'), findsOneWidget);
      expect(find.text('کل هشدارهای باز'), findsOneWidget);
      expect(find.text('هشدارهای بحرانی'), findsOneWidget);

      // Check Table headers
      expect(find.text('سطح اهمیت'), findsOneWidget);
      expect(find.text('نوع هشدار'), findsOneWidget);
      expect(find.text('قبض و پلاک'), findsOneWidget);

      // Check Data in Table
      expect(find.text('مشاهده و اقدام'), findsOneWidget);
    });

    testWidgets('MonitoringScreen renders empty state when no alerts exist', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestWidget(
          const MonitoringScreen(),
          overrides: [
            monitoringSummaryProvider.overrideWith((ref) => Future.value(testSummary)),
            monitoringAlertsProvider.overrideWith((ref) => Future.value([])),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('هیچ هشدار مغایرتی یافت نشد'), findsOneWidget);
    });
  });
}
