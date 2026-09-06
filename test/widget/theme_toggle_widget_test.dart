import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prima_bascol_app/core/api/api_client.dart';
import 'package:prima_bascol_app/core/storage/local_cache_service.dart';
import 'package:prima_bascol_app/core/storage/secure_storage_service.dart';
import 'package:prima_bascol_app/core/theme/app_theme.dart';
import 'package:prima_bascol_app/core/theme/theme_provider.dart';
import 'package:prima_bascol_app/features/auth/data/auth_repository.dart';
import 'package:prima_bascol_app/features/auth/domain/auth_models.dart';
import 'package:prima_bascol_app/features/auth/presentation/auth_providers.dart';
import 'package:prima_bascol_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Theme toggling while Dashboard is mounted causes NO GlobalKey exception', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final localCache = await LocalCacheService.init();

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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localCacheProvider.overrideWithValue(localCache),
          secureStorageProvider.overrideWithValue(MockSecureStorage()),
          authControllerProvider.overrideWith((ref) => TestAuthController(dummyUser)),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final themeMode = ref.watch(themeModeProvider);
            return MaterialApp(
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              home: const Scaffold(body: DashboardScreen()),
            );
          },
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));

    // Verify dashboard is rendered
    expect(find.text("داشبورد عملیات باسکول"), findsOneWidget);
    expect(find.text("ثبت قبض جدید"), findsOneWidget);

    // Toggle theme to dark
    final element = tester.element(find.byType(DashboardScreen));
    final container = ProviderScope.containerOf(element);
    await container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
    await tester.pump(const Duration(milliseconds: 300));

    // Verify still rendered with no exception
    expect(find.text("داشبورد عملیات باسکول"), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Toggle theme back to light
    await container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text("داشبورد عملیات باسکول"), findsOneWidget);
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
