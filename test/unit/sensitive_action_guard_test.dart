import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prima_bascol_app/core/constants/permissions.dart';
import 'package:prima_bascol_app/features/auth/data/auth_repository.dart';
import 'package:prima_bascol_app/features/auth/domain/auth_models.dart';
import 'package:prima_bascol_app/features/auth/presentation/auth_providers.dart';
import 'package:prima_bascol_app/features/security/data/security_event_logger.dart';
import 'package:prima_bascol_app/features/security/data/sensitive_action_guard.dart';
import 'package:prima_bascol_app/features/security/domain/reauth_session.dart';
import 'package:prima_bascol_app/features/security/domain/sensitive_action.dart';

class MockAuthRepo implements AuthRepository {
  @override
  Future<bool> hasValidSession() async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final Map<String, String> mockStorage = {};

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall methodCall) async {
        final key = methodCall.arguments is Map
            ? methodCall.arguments['key']?.toString()
            : null;
        if (methodCall.method == 'read') {
          return key != null ? mockStorage[key] : null;
        } else if (methodCall.method == 'write') {
          final val = methodCall.arguments['value']?.toString() ?? '';
          if (key != null) mockStorage[key] = val;
          return null;
        } else if (methodCall.method == 'delete') {
          if (key != null) mockStorage.remove(key);
          return null;
        }
        return null;
      },
    );
  });

  tearDown(() {
    mockStorage.clear();
  });

  group('SensitiveActionGuard Tests', () {
    testWidgets('rejects action if user lacks backend permission without prompting reauth',
        (WidgetTester tester) async {
      final userWithoutPermission = UserMe(
        id: 1,
        username: 'operator1',
        firstName: 'علی',
        lastName: 'محمدی',
        fullName: 'علی محمدی',
        email: 'ali@example.com',
        role: UserRole(code: 'operator', label: 'اپراتور'),
        mobile: '09120000000',
        personnelCode: 'OP-01',
        permissions: [AppPermissions.ticketView], // NO ticketCancel permission!
        isActive: true,
      );

      late SensitiveActionGuard guard;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(MockAuthRepo() as dynamic),
            authControllerProvider.overrideWith((ref) {
              final ctrl = AuthController(MockAuthRepo() as dynamic);
              ctrl.state = AuthState(user: userWithoutPermission);
              return ctrl;
            }),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return Consumer(
                    builder: (ctx, ref, _) {
                      guard = SensitiveActionGuard(
                        ref: ref,
                        eventLogger: SecurityEventLogger(),
                      );
                      return ElevatedButton(
                        onPressed: () async {
                          final result = await guard.authorize(
                            context,
                            action: SensitiveAction.cancelTicket,
                          );
                          expect(result, isFalse);
                        },
                        child: const Text('Cancel Ticket'),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Tap button to attempt unauthorized action
      await tester.tap(find.text('Cancel Ticket'));
      await tester.pumpAndSettle();

      // Verify SnackBar warning is displayed
      expect(find.text('شما دسترسی لازم برای انجام «ابطال قبض» را ندارید.'), findsOneWidget);
    });

    test('validates reauth session timeout properly', () {
      final container = ProviderContainer();
      final guard = SensitiveActionGuard(
        ref: container as dynamic,
        eventLogger: SecurityEventLogger(),
      );

      expect(guard.isSessionValid(5), isFalse);

      guard.invalidateSession();
      expect(guard.lastReauthenticatedAt, isNull);
    });

    test('ReauthSession enforces securityLevel hierarchy and user isolation', () {
      final session = ReauthSession(
        authenticatedAt: DateTime.now(),
        method: ReauthMethod.pattern,
        securityLevel: ReauthSecurityLevel.pattern,
        userId: 10,
      );

      // Same user within 5 minutes meets biometric and pattern levels
      expect(session.isValid(timeoutMinutes: 5, currentUserId: 10), isTrue);
      expect(
        session.isValid(
          timeoutMinutes: 5,
          currentUserId: 10,
          minimumSecurityLevel: ReauthSecurityLevel.biometric,
        ),
        isTrue,
      );
      expect(
        session.isValid(
          timeoutMinutes: 5,
          currentUserId: 10,
          minimumSecurityLevel: ReauthSecurityLevel.pattern,
        ),
        isTrue,
      );

      // Pattern level DOES NOT satisfy backendPassword required level!
      expect(
        session.isValid(
          timeoutMinutes: 5,
          currentUserId: 10,
          minimumSecurityLevel: ReauthSecurityLevel.backendPassword,
        ),
        isFalse,
      );

      // Different user cannot reuse this session
      expect(session.isValid(timeoutMinutes: 5, currentUserId: 99), isFalse);

      // Backend password session satisfies all levels
      final passwordSession = ReauthSession(
        authenticatedAt: DateTime.now(),
        method: ReauthMethod.password,
        securityLevel: ReauthSecurityLevel.backendPassword,
        userId: 10,
      );
      expect(
        passwordSession.isValid(
          timeoutMinutes: 5,
          currentUserId: 10,
          minimumSecurityLevel: ReauthSecurityLevel.backendPassword,
        ),
        isTrue,
      );
    });

    test('invalidates session when user permissions change or user switches', () {
      final container = ProviderContainer();
      final guard = SensitiveActionGuard(
        ref: container as dynamic,
        eventLogger: SecurityEventLogger(),
      );

      final session = ReauthSession(
        authenticatedAt: DateTime.now(),
        method: ReauthMethod.password,
        securityLevel: ReauthSecurityLevel.backendPassword,
        userId: 10,
      );
      final initialPermissions = {'ticket.view', 'ticket.cancel'};

      guard.setSessionForTesting(session, permissions: initialPermissions);

      // 1. Same user and same permissions -> Session is valid
      expect(
        guard.isSessionValid(
          5,
          currentUserId: 10,
          currentUserPermissions: ['ticket.view', 'ticket.cancel'],
        ),
        isTrue,
      );

      // 2. Permission revoked -> Session invalidated
      expect(
        guard.isSessionValid(
          5,
          currentUserId: 10,
          currentUserPermissions: ['ticket.view'],
        ),
        isFalse,
      );
      expect(guard.currentSession, isNull);

      // 3. Re-set session and test user switch
      guard.setSessionForTesting(session, permissions: initialPermissions);
      expect(
        guard.isSessionValid(
          5,
          currentUserId: 99,
          currentUserPermissions: ['ticket.view', 'ticket.cancel'],
        ),
        isFalse,
      );
      expect(guard.currentSession, isNull);
    });
  });
}
