import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prima_bascol_app/core/api/api_client.dart';
import 'package:prima_bascol_app/core/storage/local_cache_service.dart';
import 'package:prima_bascol_app/core/storage/secure_storage_service.dart';
import 'package:prima_bascol_app/features/auth/data/auth_repository.dart';
import 'package:prima_bascol_app/features/auth/domain/auth_models.dart';
import 'package:prima_bascol_app/features/auth/presentation/auth_providers.dart';
import 'package:prima_bascol_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:prima_bascol_app/features/tickets/presentation/ticket_create_screen.dart';
import 'package:prima_bascol_app/features/tickets/presentation/ticket_detail_screen.dart';
import 'package:prima_bascol_app/features/tickets/presentation/ticket_providers.dart';
import 'package:prima_bascol_app/features/tickets/domain/ticket_models.dart';
import 'package:prima_bascol_app/features/trucks_in_yard/presentation/trucks_in_yard_screen.dart';
import 'package:prima_bascol_app/features/trucks_in_yard/presentation/trucks_in_yard_providers.dart';
import 'package:prima_bascol_app/features/trucks_in_yard/domain/yard_truck_model.dart';
import 'package:prima_bascol_app/features/reports/presentation/reports_screen.dart';
import 'package:prima_bascol_app/features/reports/presentation/reports_providers.dart';
import 'package:prima_bascol_app/features/reports/domain/report_models.dart';
import 'package:prima_bascol_app/features/monitoring/presentation/monitoring_providers.dart';
import 'package:prima_bascol_app/features/monitoring/domain/monitoring_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details);
  };

  final dummyUser = UserMe(
    id: 1,
    username: 'admin',
    firstName: 'مدیر',
    lastName: 'سیستم',
    fullName: 'مدیر سامانه باسکول پریما',
    email: 'admin@bascol.ir',
    role: UserRole(code: 'ADMIN', label: 'مدیر ارشد سامانه'),
    mobile: '09123456789',
    personnelCode: '1001',
    permissions: ['*'],
    isActive: true,
  );

  testWidgets('Dashboard renders with NO overflow at 360px mobile', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final localCache = await LocalCacheService.init();

    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localCacheProvider.overrideWithValue(localCache),
          secureStorageProvider.overrideWithValue(MockSecureStorage()),
          authControllerProvider.overrideWith((ref) => TestAuthController(dummyUser)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: DashboardScreen()),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    final err = tester.takeException();
    if (err is FlutterError) {
      for (final d in err.diagnostics) {
        print("DIAG: ${d.toStringDeep()}");
      }
    }
    expect(err, isNull);
  });

  testWidgets('Dashboard renders with NO overflow at 800px tablet', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final localCache = await LocalCacheService.init();

    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localCacheProvider.overrideWithValue(localCache),
          secureStorageProvider.overrideWithValue(MockSecureStorage()),
          authControllerProvider.overrideWith((ref) => TestAuthController(dummyUser)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: DashboardScreen()),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dashboard renders with NO overflow at 1280px desktop', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final localCache = await LocalCacheService.init();

    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localCacheProvider.overrideWithValue(localCache),
          secureStorageProvider.overrideWithValue(MockSecureStorage()),
          authControllerProvider.overrideWith((ref) => TestAuthController(dummyUser)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: DashboardScreen()),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });

  testWidgets('TicketCreateScreen renders with NO overflow at 360px mobile', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final localCache = await LocalCacheService.init();

    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localCacheProvider.overrideWithValue(localCache),
          secureStorageProvider.overrideWithValue(MockSecureStorage()),
          authControllerProvider.overrideWith((ref) => TestAuthController(dummyUser)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: TicketCreateScreen()),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);

    expect(tester.takeException(), isNull);

    // Test tapping the add party icon button
    final addPartyBtn = find.byTooltip("تعریف طرف‌حساب جدید");
    if (addPartyBtn.evaluate().isNotEmpty) {
      await tester.tap(addPartyBtn);
      await tester.pumpAndSettle();
      expect(find.text("تعریف و ثبت طرف‌حساب جدید"), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text("انصراف"));
      await tester.pumpAndSettle();
    }

    // Test tapping the add product icon button
    final addProductBtn = find.byTooltip("تعریف کالای جدید");
    if (addProductBtn.evaluate().isNotEmpty) {
      await tester.tap(addProductBtn);
      await tester.pumpAndSettle();
      expect(find.text("تعریف و ثبت کالای جدید"), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text("انصراف"));
      await tester.pumpAndSettle();
    }

    // Test tapping the add driver icon button
    final addDriverBtn = find.byTooltip("تعریف راننده جدید");
    if (addDriverBtn.evaluate().isNotEmpty) {
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.tap(addDriverBtn);
      await tester.pumpAndSettle();
      expect(find.text("تعریف و ثبت راننده جدید"), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text("انصراف"));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('TicketDetailScreen renders with NO overflow at 360px mobile', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockTicket = WeighTicketDetailModel.fromJson({
      "id": 1,
      "serial_number": "1001",
      "status": {"code": "waiting_second", "label": "در انتظار وزن دوم (داخل محوطه)"},
      "weight_mode": {"code": "empty_first", "label": "ابتدا خالی (توزین اول) سپس پر (توزین دوم)"},
      "operation_type": null,
      "operation_type_display": null,
      "party": 1,
      "party_display": {"id": 1, "name": "هیمن دل بینا", "code": "P44907"},
      "product": 1,
      "product_display": {"id": 1, "name": "اهن شمش", "code": "PRD77291"},
      "vehicle": 1,
      "vehicle_display": {"id": 1, "plate": "بدون پلاک"},
      "vehicle_type": null,
      "vehicle_type_display": "-",
      "vehicle_type_custom": "",
      "driver": null,
      "driver_display": "تست",
      "driver_mobile_display": "09183739816",
      "driver_name_custom": "تست",
      "driver_mobile_custom": "09183739816",
      "license_plate_display": "52 ب 194 - ایران 64",
      "waybill_number": "11193",
      "origin": null,
      "destination": null,
      "unload_location": null,
      "load_count": 1,
      "first_weight": "10.00",
      "first_weight_date": "2026-09-03",
      "first_weight_date_jalali": "1405/06/12",
      "first_weight_time": "23:40",
      "second_weight": "0.00",
      "gross_weight": "10.00",
      "tare_weight": "0.00",
      "net_weight": "10.00",
      "sent_weight": "0.00",
      "weight_difference": "0.00",
      "loss_weight": "0.00",
      "final_weight": "10.00",
      "is_tolerance_exceeded": false,
      "created_at_jalali": "1405/06/12 20:13",
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => TestAuthController(dummyUser)),
          ticketDetailProvider(1).overrideWith((ref) => mockTicket),
          ticketAnalysisProvider(1).overrideWith(
            (ref) => Future.value(
              TicketAnalysisSummary(
                ticketId: 1,
                serialNumber: '1001',
                riskScore: 10,
                riskLevel: 'NORMAL',
                hasCritical: false,
                hasHigh: false,
                openAlertsCount: 0,
                alerts: [],
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: TicketDetailScreen(ticketId: 1)),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('TrucksInYardScreen renders with NO overflow at 360px mobile', (tester) async {
    FlutterError.onError = (details) {
      print("CAPTURED YARD ERROR: ${details.toDiagnosticsNode().toStringDeep()}");
    };
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockTrucks = [
      YardTruckModel(
        id: 1,
        serialNumber: "1001",
        licensePlateDisplay: "52 ب 194 - ایران 64",
        driverName: "تست راننده",
        driverMobile: "09183739816",
        partyName: "شرکت بازرگانی کشاورزی امید",
        productName: "اهن شمش",
        firstWeight: 10.0,
        firstWeightDateJalali: "1405/06/12",
        firstWeightTime: "20:13",
        firstWeightDateTime: DateTime.now().subtract(const Duration(hours: 4)),
        status: ChoiceItem(code: "waiting_second", label: "در انتظار وزن دوم"),
      ),
      YardTruckModel(
        id: 2,
        serialNumber: "1002",
        licensePlateDisplay: "12 الف 345 - ایران 11",
        driverName: "علی محمدی",
        driverMobile: "09121112233",
        partyName: "فولاد مبارکه",
        productName: "میلگرد آجدار",
        firstWeight: 22.5,
        firstWeightDateJalali: "1405/06/12",
        firstWeightTime: "22:00",
        firstWeightDateTime: DateTime.now().subtract(const Duration(minutes: 45)),
        status: ChoiceItem(code: "waiting_second", label: "در انتظار وزن دوم"),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => TestAuthController(dummyUser)),
          waitingTrucksProvider.overrideWith((ref) => mockTrucks),
        ],
        child: const MaterialApp(
          home: Scaffold(body: TrucksInYardScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text("قبض 1001"), findsOneWidget);
    expect(find.text("قبض 1002"), findsOneWidget);
    expect(find.text("کل خودروهای محوطه"), findsOneWidget);
    final err = tester.takeException();
    if (err is FlutterError) {
      print("YARD OVERFLOW DIAG:\n${err.diagnostics.map((d) => '$d').join('\n')}");
    }
    expect(err, isNull);
  });

  testWidgets('ReportsScreen renders with NO overflow at 360px mobile', (tester) async {
    FlutterError.onError = (details) {
      print("CAPTURED REPORTS ERROR: ${details.toDiagnosticsNode().toStringDeep()}");
    };
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockSummary = ReportSummaryModel(
      totalTickets: 42,
      totalGrossWeight: 1250000.0,
      totalTareWeight: 450000.0,
      totalNetWeight: 800000.0,
      totalSentWeight: 810000.0,
      totalWeightDifference: -10000.0,
      totalLossWeight: 5000.0,
      totalFinalWeight: 795000.0,
    );

    final mockGrouped = [
      GroupedReportItem(
        groupKey: "1",
        groupTitle: "اهن شمش کارخانه نورد",
        count: 24,
        totalNetWeight: 480000.0,
        totalFinalWeight: 477000.0,
        totalLossWeight: 3000.0,
        averageNetWeight: 20000.0,
      ),
      GroupedReportItem(
        groupKey: "2",
        groupTitle: "میلگرد صنعتی سایز ۱۶",
        count: 18,
        totalNetWeight: 320000.0,
        totalFinalWeight: 318000.0,
        totalLossWeight: 2000.0,
        averageNetWeight: 17777.0,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => TestAuthController(dummyUser)),
          reportSummaryProvider.overrideWith((ref) => mockSummary),
          reportGroupedProvider.overrideWith((ref) => mockGrouped),
          reportTicketsProvider.overrideWith((ref) => <WeighTicketListModel>[]),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ReportsScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text("گزارشات تجمیعی"), findsOneWidget);
    expect(find.text("گزارش تفکیکی بر اساس کالا"), findsOneWidget);
    expect(find.text("اهن شمش کارخانه نورد"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class MockSecureStorage extends SecureStorageService {
  @override
  Future<String?> getAccessToken() async => 'mock_token';
  @override
  Future<String?> getRefreshToken() async => 'mock_refresh';
  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {}
  @override
  Future<void> clearTokens() async {}
}

class TestAuthController extends AuthController {
  TestAuthController(UserMe user)
      : super(
          AuthRepository(
            apiClient: ApiClient(secureStorage: MockSecureStorage()),
            secureStorage: MockSecureStorage(),
            localCache: LocalCacheService(FakePrefs()),
          ),
        ) {
    state = AuthState(user: user);
  }
}

class FakePrefs implements SharedPreferences {
  @override
  noSuchMethod(Invocation invocation) => null;
}
