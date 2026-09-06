import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prima_bascol_app/core/storage/local_cache_service.dart';
import 'package:prima_bascol_app/core/theme/theme_provider.dart';
import 'package:prima_bascol_app/features/auth/presentation/auth_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ThemeModeNotifier switches themes and persists choice', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final cache = LocalCacheService(prefs);

    final container = ProviderContainer(
      overrides: [
        localCacheProvider.overrideWithValue(cache),
      ],
    );
    addTearDown(container.dispose);

    // Initial should be light (or default)
    expect(container.read(themeModeProvider), ThemeMode.light);

    // Switch to dark
    await container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(cache.getThemeMode(), 'dark');

    // Toggle back to light
    await container.read(themeModeProvider.notifier).toggleTheme();
    expect(container.read(themeModeProvider), ThemeMode.light);
    expect(cache.getThemeMode(), 'light');

    // Switch to system
    await container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
    expect(container.read(themeModeProvider), ThemeMode.system);
    expect(cache.getThemeMode(), 'system');
  });
}
