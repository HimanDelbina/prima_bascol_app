import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/errors/failures.dart';
import '../domain/monitoring_models.dart';

class MonitoringRepository {
  final ApiClient _apiClient;

  MonitoringRepository(this._apiClient);

  Future<List<MonitoringAlertItem>> fetchAlerts({String? status, String? severity}) async {
    try {
      final params = <String, dynamic>{};
      if (status != null && status.isNotEmpty) params['status'] = status.toUpperCase();
      if (severity != null && severity.isNotEmpty) params['severity'] = severity.toUpperCase();

      final res = await _apiClient.request(
        ApiEndpoints.monitoringAlerts,
        queryParameters: params,
      );

      final data = res.data;
      List<dynamic> list = [];
      if (data is Map<String, dynamic>) {
        if (data['results'] is List) list = data['results'] as List;
        else if (data['data'] is List) list = data['data'] as List;
      } else if (data is List) {
        list = data;
      }
      return list.map((e) => MonitoringAlertItem.fromJson(e as Map<String, dynamic>)).toList();
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
      return MonitoringSummaryModel(openCount: 0, criticalCount: 0, reviewedCount: 0, resolvedCount: 0);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> reviewAlert(int id) async {
    try {
      await _apiClient.request(ApiEndpoints.monitoringAlertReview(id), method: 'POST');
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
}
