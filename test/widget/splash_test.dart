import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prima_bascol_app/main.dart';
import 'package:prima_bascol_app/core/storage/local_cache_service.dart';
import 'package:prima_bascol_app/features/auth/presentation/auth_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App boots up from splash and transitions to LoginScreen when unauthenticated', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final localCache = await LocalCacheService.init();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localCacheProvider.overrideWithValue(localCache),
        ],
        child: const PrimaBascolApp(),
      ),
    );

    // Shows splash initially
    await tester.pump();
    expect(find.text("در حال بارگذاری و برقراری ارتباط با سرور..."), findsOneWidget);

    // Wait for bootstrap and transition to complete
    for (int i = 0; i < 35; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(milliseconds: 500));

    // Navigates to login screen
    expect(find.text("ورود به سامانه"), findsOneWidget);
    final creatorFinder = find.text("سازنده: سارا حقیری");
    expect(creatorFinder, findsOneWidget);
    expect(find.text("در حال بارگذاری و برقراری ارتباط با سرور..."), findsNothing);

    // Tap creator badge and verify SnackBar with phone number appears
    await tester.tap(creatorFinder);
    await tester.pumpAndSettle();
    expect(find.textContaining("09183739816"), findsOneWidget);
  });
}
