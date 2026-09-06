import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_response.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/ticket_repository.dart';
import '../domain/ticket_models.dart';

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return TicketRepository(client);
});

class TicketFilterState {
  final int page;
  final String search;
  final String? status;
  final String? startDateJalali;
  final String? endDateJalali;
  final int? productId;
  final int? partyId;
  final int? driverId;
  final int? vehicleId;

  const TicketFilterState({
    this.page = 1,
    this.search = '',
    this.status,
    this.startDateJalali,
    this.endDateJalali,
    this.productId,
    this.partyId,
    this.driverId,
    this.vehicleId,
  });

  int get activeFilterCount {
    int count = 0;
    if (search.isNotEmpty) count++;
    if (status != null) count++;
    if (startDateJalali != null) count++;
    if (endDateJalali != null) count++;
    if (productId != null) count++;
    if (partyId != null) count++;
    if (driverId != null) count++;
    if (vehicleId != null) count++;
    return count;
  }

  TicketFilterState copyWith({
    int? page,
    String? search,
    String? status,
    String? startDateJalali,
    String? endDateJalali,
    int? productId,
    int? partyId,
    int? driverId,
    int? vehicleId,
    bool clearStatus = false,
    bool clearDates = false,
    bool clearProduct = false,
    bool clearParty = false,
  }) {
    return TicketFilterState(
      page: page ?? this.page,
      search: search ?? this.search,
      status: clearStatus ? null : (status ?? this.status),
      startDateJalali: clearDates ? null : (startDateJalali ?? this.startDateJalali),
      endDateJalali: clearDates ? null : (endDateJalali ?? this.endDateJalali),
      productId: clearProduct ? null : (productId ?? this.productId),
      partyId: clearParty ? null : (partyId ?? this.partyId),
      driverId: driverId ?? this.driverId,
      vehicleId: vehicleId ?? this.vehicleId,
    );
  }
}

final ticketFilterProvider = StateProvider<TicketFilterState>((ref) {
  return const TicketFilterState();
});

final ticketListFutureProvider = FutureProvider.autoDispose<PaginatedResponse<WeighTicketListModel>>((ref) async {
  final repo = ref.watch(ticketRepositoryProvider);
  final filter = ref.watch(ticketFilterProvider);
  return repo.fetchTickets(
    page: filter.page,
    search: filter.search,
    status: filter.status,
    startDateJalali: filter.startDateJalali,
    endDateJalali: filter.endDateJalali,
    productId: filter.productId,
    partyId: filter.partyId,
    driverId: filter.driverId,
    vehicleId: filter.vehicleId,
  );
});

final ticketDetailProvider = FutureProvider.autoDispose.family<WeighTicketDetailModel, int>((ref, id) async {
  final repo = ref.watch(ticketRepositoryProvider);
  return repo.fetchTicketDetail(id);
});

final waitingSecondWeightProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(ticketRepositoryProvider);
  return repo.fetchWaitingSecondWeight();
});
