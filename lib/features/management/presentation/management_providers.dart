import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/management_repository.dart';
import '../domain/management_models.dart';

class ManagementFilterState {
  final String quickPeriod;
  final String? startDateJalali;
  final String? endDateJalali;

  const ManagementFilterState({
    this.quickPeriod = 'this_month',
    this.startDateJalali,
    this.endDateJalali,
  });

  ManagementFilterState copyWith({
    String? quickPeriod,
    String? startDateJalali,
    String? endDateJalali,
    bool clearDates = false,
  }) {
    return ManagementFilterState(
      quickPeriod: quickPeriod ?? this.quickPeriod,
      startDateJalali: clearDates ? null : (startDateJalali ?? this.startDateJalali),
      endDateJalali: clearDates ? null : (endDateJalali ?? this.endDateJalali),
    );
  }
}

final managementRepositoryProvider = Provider<ManagementRepository>((ref) {
  return ManagementRepository(ref.watch(apiClientProvider));
});

final selectedPeriodProvider = StateProvider<String>((ref) => 'this_month');

final managementFilterProvider = StateProvider<ManagementFilterState>((ref) {
  final period = ref.watch(selectedPeriodProvider);
  return ManagementFilterState(quickPeriod: period);
});

final managementSummaryProvider = FutureProvider.autoDispose<ManagementSummaryModel>((ref) async {
  final repo = ref.watch(managementRepositoryProvider);
  final filter = ref.watch(managementFilterProvider);
  return repo.fetchSummary(
    filter.quickPeriod,
    filter.startDateJalali,
    filter.endDateJalali,
  );
});

final managementProductsProvider = FutureProvider.autoDispose<List<ManagementBreakdownItem>>((ref) async {
  final repo = ref.watch(managementRepositoryProvider);
  final filter = ref.watch(managementFilterProvider);
  return repo.fetchProductBreakdown(
    filter.quickPeriod,
    filter.startDateJalali,
    filter.endDateJalali,
  );
});

final managementPartiesProvider = FutureProvider.autoDispose<List<ManagementBreakdownItem>>((ref) async {
  final repo = ref.watch(managementRepositoryProvider);
  final filter = ref.watch(managementFilterProvider);
  return repo.fetchPartyBreakdown(
    filter.quickPeriod,
    filter.startDateJalali,
    filter.endDateJalali,
  );
});
