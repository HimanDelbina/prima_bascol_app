import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/settings_repository.dart';
import '../domain/settings_models.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(apiClientProvider));
});

final systemSettingsProvider = FutureProvider.autoDispose<SystemSettingsModel>((ref) async {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.fetchSettings();
});
