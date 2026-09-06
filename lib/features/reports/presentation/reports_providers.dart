import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../tickets/domain/ticket_models.dart';
import '../data/reports_repository.dart';
import '../domain/report_models.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository(ref.watch(apiClientProvider));
});

class ReportFilterState {
  final String? startDateJalali;
  final String? endDateJalali;
  final String groupBy; // 'product', 'party', 'driver', 'vehicle'
  final int? productId;
  final int? partyId;
  final String? status;
  final String? search;

  const ReportFilterState({
    this.startDateJalali,
    this.endDateJalali,
    this.groupBy = 'product',
    this.productId,
    this.partyId,
    this.status,
    this.search,
  });

  ReportFilterState copyWith({
    String? startDateJalali,
    String? endDateJalali,
    String? groupBy,
    int? productId,
    int? partyId,
    String? status,
    String? search,
  }) {
    return ReportFilterState(
      startDateJalali: startDateJalali ?? this.startDateJalali,
      endDateJalali: endDateJalali ?? this.endDateJalali,
      groupBy: groupBy ?? this.groupBy,
      productId: productId ?? this.productId,
      partyId: partyId ?? this.partyId,
      status: status ?? this.status,
      search: search ?? this.search,
    );
  }

  Map<String, dynamic> toParams() {
    final map = <String, dynamic>{'group_by': groupBy};
    if (startDateJalali != null && startDateJalali!.isNotEmpty) {
      map['start_date'] = startDateJalali;
      map['date_from'] = startDateJalali;
    }
    if (endDateJalali != null && endDateJalali!.isNotEmpty) {
      map['end_date'] = endDateJalali;
      map['date_to'] = endDateJalali;
    }
    if (productId != null) map['product'] = productId;
    if (partyId != null) map['party'] = partyId;
    if (status != null && status!.isNotEmpty) map['status'] = status;
    if (search != null && search!.isNotEmpty) map['search'] = search;
    return map;
  }
}

final reportFilterProvider = StateProvider<ReportFilterState>((ref) => const ReportFilterState());

final reportSummaryProvider = FutureProvider.autoDispose<ReportSummaryModel>((ref) async {
  final repo = ref.watch(reportsRepositoryProvider);
  final filter = ref.watch(reportFilterProvider);
  return repo.fetchSummary(filter.toParams());
});

final reportGroupedProvider = FutureProvider.autoDispose<List<GroupedReportItem>>((ref) async {
  final repo = ref.watch(reportsRepositoryProvider);
  final filter = ref.watch(reportFilterProvider);
  return repo.fetchGrouped(filter.toParams());
});

final reportTicketsProvider = FutureProvider.autoDispose<List<WeighTicketListModel>>((ref) async {
  final repo = ref.watch(reportsRepositoryProvider);
  final filter = ref.watch(reportFilterProvider);
  return repo.fetchReportTickets(filter.toParams());
});

