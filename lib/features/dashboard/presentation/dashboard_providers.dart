import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/dashboard_repository.dart';
import '../domain/dashboard_models.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return DashboardRepository(client);
});

final dashboardSummaryProvider = FutureProvider.autoDispose<DashboardSummaryModel>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.fetchSummary();
});

final dashboardTrendsProvider = FutureProvider.autoDispose<DashboardTrendModel>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.fetchTrends();
});
