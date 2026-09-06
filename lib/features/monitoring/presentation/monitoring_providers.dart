import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/monitoring_repository.dart';
import '../domain/monitoring_models.dart';

final monitoringRepositoryProvider = Provider<MonitoringRepository>((ref) {
  return MonitoringRepository(ref.watch(apiClientProvider));
});

final monitoringFilterStatusProvider = StateProvider<String?>((ref) => null);
final monitoringFilterSeverityProvider = StateProvider<String?>((ref) => null);

final monitoringSummaryProvider = FutureProvider.autoDispose<MonitoringSummaryModel>((ref) async {
  final repo = ref.watch(monitoringRepositoryProvider);
  return repo.fetchSummary();
});

final monitoringAlertsProvider = FutureProvider.autoDispose<List<MonitoringAlertItem>>((ref) async {
  final repo = ref.watch(monitoringRepositoryProvider);
  final status = ref.watch(monitoringFilterStatusProvider);
  final severity = ref.watch(monitoringFilterSeverityProvider);
  return repo.fetchAlerts(status: status, severity: severity);
});

final monitoringRulesProvider = FutureProvider.autoDispose<List<MonitoringRuleItem>>((ref) async {
  final repo = ref.watch(monitoringRepositoryProvider);
  return repo.fetchRules();
});
