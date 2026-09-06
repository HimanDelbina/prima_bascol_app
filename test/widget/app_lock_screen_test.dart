import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prima_bascol_app/core/config/app_config.dart';
import 'package:prima_bascol_app/features/auth/data/auth_repository.dart';
import 'package:prima_bascol_app/features/auth/domain/auth_models.dart';
import 'package:prima_bascol_app/features/auth/presentation/auth_providers.dart';
import 'package:prima_bascol_app/features/security/domain/security_preferences.dart';
import 'package:prima_bascol_app/features/security/domain/unlock_method.dart';
import 'package:prima_bascol_app/features/security/presentation/controllers/app_lock_controller.dart';
import 'package:prima_bascol_app/features/security/presentation/controllers/security_providers.dart';
import 'package:prima_bascol_app/features/security/presentation/screens/app_lock_screen.dart';

class FakeAuthRepo implements AuthRepository {
  @override
  Future<bool> hasValidSession() async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final testUser = UserMe(
    id: 1,
    username: 'hemn',
    firstName: 'هیمن',
    lastName: 'دلبینا',
    fullName: 'هیمن دلبینا',
    email: 'hemn@example.com',
    role: UserRole(code: 'admin', label: 'مدیر ارشد سامانه'),
    mobile: '09180000000',
    personnelCode: 'EMP-01',
    permissions: ['*'],
    isActive: true,
  );

  testWidgets('AppLockScreen renders app name, user full name, and password fallback',
      (WidgetTester tester) async {
    final fakeRepo = FakeAuthRepo();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepo as dynamic),
          authControllerProvider.overrideWith((ref) {
            final ctrl = AuthController(fakeRepo as dynamic);
            ctrl.state = AuthState(user: testUser);
            return ctrl;
          }),
          appLockControllerProvider.overrideWith((ref) {
            final securityStorage = ref.watch(securityStorageServiceProvider);
            final biometricService = ref.watch(biometricServiceProvider);
            final patternCrypto = ref.watch(patternCryptoServiceProvider);

            final ctrl = AppLockController(
              securityStorage: securityStorage,
              biometricService: biometricService,
              patternCrypto: patternCrypto,
              authRepository: fakeRepo as dynamic,
              eventLogger: ref.watch(securityEventLoggerProvider),
              screenshotProtection: ref.watch(screenshotProtectionServiceProvider),
            );
            ctrl.state = AppLockState(
              status: AppLockStatus.authenticatedLocked,
              user: testUser,
              preferences: const SecurityPreferences(
                userId: 1,
                patternEnabled: true,
                preferredUnlockMethod: UnlockMethod.pattern,
                hasPattern: true,
              ),
              activeUnlockMethod: UnlockMethod.pattern,
            );
            return ctrl;
          }),
        ],
        child: const MaterialApp(
          home: AppLockScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify App Name is displayed
    expect(find.text(AppConfig.appName), findsOneWidget);

    // Verify User Full Name is displayed
    expect(find.text('هیمن دلبینا'), findsOneWidget);

    // Verify User Role is displayed
    expect(find.text('مدیر ارشد سامانه'), findsOneWidget);

    // Verify Fallback button
    expect(find.text('ورود با رمز عبور'), findsOneWidget);
    expect(find.text('الگو را فراموش کرده‌ام'), findsOneWidget);
  });
}
