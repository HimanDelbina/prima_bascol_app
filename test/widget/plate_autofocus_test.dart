import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prima_bascol_app/core/api/api_client.dart';
import 'package:prima_bascol_app/core/storage/local_cache_service.dart';
import 'package:prima_bascol_app/core/storage/secure_storage_service.dart';
import 'package:prima_bascol_app/features/auth/data/auth_repository.dart';
import 'package:prima_bascol_app/features/auth/domain/auth_models.dart';
import 'package:prima_bascol_app/features/auth/presentation/auth_providers.dart';
import 'package:prima_bascol_app/features/tickets/presentation/ticket_create_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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

  testWidgets('License plate inputs auto-advance focus on fill', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final localCache = await LocalCacheService.init();

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

    await tester.pumpAndSettle();

    // Find the 3 text fields for plate: hint "12", hint "345", hint "72"
    final part1Finder = find.widgetWithText(TextFormField, "12");
    final part2Finder = find.widgetWithText(TextFormField, "345");
    final iranFinder = find.widgetWithText(TextFormField, "72");

    expect(part1Finder, findsOneWidget);
    expect(part2Finder, findsOneWidget);
    expect(iranFinder, findsOneWidget);

    // 1. Enter 2 digits in Part 1
    await tester.enterText(part1Finder, "24");
    await tester.pump();

    // Verify part 2 now has focus
    final part2TextField = tester.widget<TextField>(find.descendant(of: part2Finder, matching: find.byType(TextField)));
    expect(part2TextField.focusNode?.hasFocus, isTrue);

    // 2. Enter 3 digits in Part 2
    await tester.enterText(part2Finder, "685");
    await tester.pump();

    // Verify iran code now has focus
    final iranTextField = tester.widget<TextField>(find.descendant(of: iranFinder, matching: find.byType(TextField)));
    expect(iranTextField.focusNode?.hasFocus, isTrue);

    // 3. Enter 2 digits in Iran code
    await tester.enterText(iranFinder, "72");
    await tester.pump();

    // Verify iran code is unfocused
    expect(iranTextField.focusNode?.hasFocus, isFalse);
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
