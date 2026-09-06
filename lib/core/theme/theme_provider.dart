import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/local_cache_service.dart';
import '../../features/auth/presentation/auth_providers.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final cache = ref.watch(localCacheProvider);
  return ThemeModeNotifier(cache);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final LocalCacheService _cache;

  ThemeModeNotifier(this._cache) : super(_loadInitialTheme(_cache));

  static ThemeMode _loadInitialTheme(LocalCacheService cache) {
    final modeStr = cache.getThemeMode();
    switch (modeStr) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final modeStr = mode == ThemeMode.dark
        ? 'dark'
        : mode == ThemeMode.light
            ? 'light'
            : 'system';
    await _cache.setThemeMode(modeStr);
  }

  Future<void> toggleTheme() async {
    if (state == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }
}
