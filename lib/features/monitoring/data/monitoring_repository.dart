import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/errors/failures.dart';
import '../domain/monitoring_models.dart';

class MonitoringRepository {
  final ApiClient _apiClient;

  MonitoringRepository(this._apiClient);

  Future<List<MonitoringAlertItem>> fetchAlerts({
    String? status,
    String? severity,
    String? alertType,
    int? ticketId,
    int? vehicleId,
    int? partyId,
    int? productId,
    int? driverId,
    String? search,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (status != null && status.isNotEmpty) params['status'] = status.toUpperCase();
      if (severity != null && severity.isNotEmpty) params['severity'] = severity.toUpperCase();
      if (alertType != null && alertType.isNotEmpty) params['alert_type'] = alertType;
      if (ticketId != null) params['ticket'] = ticketId;
      if (vehicleId != null) params['vehicle'] = vehicleId;
      if (partyId != null) params['party'] = partyId;
      if (productId != null) params['product'] = productId;
      if (driverId != null) params['driver'] = driverId;
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (dateFrom != null && dateFrom.isNotEmpty) params['date_from'] = dateFrom;
      if (dateTo != null && dateTo.isNotEmpty) params['date_to'] = dateTo;

      final res = await _apiClient.request(
        ApiEndpoints.monitoringAlerts,
        queryParameters: params,
      );

      final data = res.data;
      List<dynamic> list = [];
      if (data is Map<String, dynamic>) {
        if (data['results'] is List) {
          list = data['results'] as List;
        } else if (data['data'] is List) {
          list = data['data'] as List;
        }
      } else if (data is List) {
        list = data;
      }
      return list.map((e) => MonitoringAlertItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<MonitoringAlertItem> fetchAlertDetail(int id) async {
    try {
      final res = await _apiClient.request(ApiEndpoints.monitoringAlertDetail(id));
      final data = res.data is Map<String, dynamic> ? res.data as Map<String, dynamic> : <String, dynamic>{};
      return MonitoringAlertItem.fromJson(data);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<MonitoringSummaryModel> fetchSummary() async {
    try {
      final res = await _apiClient.request(ApiEndpoints.monitoringSummary);
      if (res.data is Map<String, dynamic>) {
        return MonitoringSummaryModel.fromJson(res.data as Map<String, dynamic>);
      }
      return MonitoringSummaryModel(
        totalToday: 0,
        openCount: 0,
        reviewedCount: 0,
        resolvedCount: 0,
        ignoredCount: 0,
        highCount: 0,
        criticalCount: 0,
        totalOpen: 0,
        byType: {},
      );
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> reviewAlert(int id, {String? note}) async {
    try {
      await _apiClient.request(
        ApiEndpoints.monitoringAlertReview(id),
        method: 'POST',
        data: note != null && note.isNotEmpty ? {'note': note} : {},
      );
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> resolveAlert(int id, {required String note}) async {
    try {
      await _apiClient.request(
        ApiEndpoints.monitoringAlertResolve(id),
        method: 'POST',
        data: {'resolution_note': note},
      );
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> ignoreAlert(int id, {required String note}) async {
    try {
      await _apiClient.request(
        ApiEndpoints.monitoringAlertIgnore(id),
        method: 'POST',
        data: {'reason': note},
      );
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<List<MonitoringRuleItem>> fetchRules() async {
    try {
      final res = await _apiClient.request(ApiEndpoints.monitoringRules);
      final data = res.data;
      List<dynamic> list = [];
      if (data is Map<String, dynamic> && data['results'] is List) {
        list = data['results'] as List;
      } else if (data is List) {
        list = data;
      }
      return list.map((e) => MonitoringRuleItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> updateRule(int id, Map<String, dynamic> data) async {
    try {
      await _apiClient.request(
        ApiEndpoints.monitoringRuleDetail(id),
        method: 'PATCH',
        data: data,
      );
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<TicketAnalysisSummary> fetchTicketAnalysis(int ticketId) async {
    try {
      final res = await _apiClient.request(ApiEndpoints.ticketAnalysis(ticketId));
      final data = res.data is Map<String, dynamic> ? res.data as Map<String, dynamic> : <String, dynamic>{};
      return TicketAnalysisSummary.fromJson(data);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
