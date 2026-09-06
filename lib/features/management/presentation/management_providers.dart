import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/management_repository.dart';
import '../domain/management_models.dart';
import '../domain/party_analytics_models.dart';

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

// ==========================================
// Phase 4: Party Ranking & Analytics Providers
// ==========================================

class PartyRankingFilter {
  final String quickPeriod;
  final String? partyType;
  final int? product;
  final int minimumTickets;
  final String ordering;
  final String searchQuery;

  const PartyRankingFilter({
    this.quickPeriod = 'this_month',
    this.partyType,
    this.product,
    this.minimumTickets = 20,
    this.ordering = 'overall_score',
    this.searchQuery = '',
  });

  PartyRankingFilter copyWith({
    String? quickPeriod,
    String? partyType,
    int? product,
    int? minimumTickets,
    String? ordering,
    String? searchQuery,
    bool clearPartyType = false,
    bool clearProduct = false,
  }) {
    return PartyRankingFilter(
      quickPeriod: quickPeriod ?? this.quickPeriod,
      partyType: clearPartyType ? null : (partyType ?? this.partyType),
      product: clearProduct ? null : (product ?? this.product),
      minimumTickets: minimumTickets ?? this.minimumTickets,
      ordering: ordering ?? this.ordering,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final partyRankingFilterProvider = StateProvider<PartyRankingFilter>((ref) {
  return const PartyRankingFilter();
});

final partyRankingProvider = FutureProvider.autoDispose<List<PartyRankingItem>>((ref) async {
  final repo = ref.watch(managementRepositoryProvider);
  final filter = ref.watch(partyRankingFilterProvider);

  final items = await repo.fetchPartyRanking(
    quickPeriod: filter.quickPeriod,
    partyType: filter.partyType,
    product: filter.product,
    minimumTickets: filter.minimumTickets,
    ordering: filter.ordering,
  );

  if (filter.searchQuery.trim().isEmpty) {
    return items;
  }

  final query = filter.searchQuery.trim().toLowerCase();
  return items.where((item) {
    return item.partyName.toLowerCase().contains(query) ||
        (item.partyCode?.toLowerCase().contains(query) ?? false);
  }).toList();
});

final partyAnalyticsDetailProvider = FutureProvider.autoDispose.family<PartyDetailAnalytics, int>((ref, partyId) async {
  final repo = ref.watch(managementRepositoryProvider);
  final filter = ref.watch(managementFilterProvider);
  return repo.fetchPartyAnalytics(
    partyId,
    quickPeriod: filter.quickPeriod,
    startDate: filter.startDateJalali,
    endDate: filter.endDateJalali,
  );
});

final partyTrendProvider = FutureProvider.autoDispose.family<PartyTrendModel, int>((ref, partyId) async {
  final repo = ref.watch(managementRepositoryProvider);
  final filter = ref.watch(managementFilterProvider);
  return repo.fetchPartyTrend(
    partyId,
    quickPeriod: filter.quickPeriod,
  );
});
