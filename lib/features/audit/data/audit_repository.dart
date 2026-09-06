import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/errors/failures.dart';
import '../domain/audit_models.dart';

class AuditRepository {
  final ApiClient _apiClient;

  AuditRepository(this._apiClient);

  Future<List<AuditLogItem>> fetchAuditLogs({String? search, String? action}) async {
    try {
      final params = <String, dynamic>{};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (action != null && action.isNotEmpty) params['action'] = action;

      final res = await _apiClient.request(ApiEndpoints.audit, queryParameters: params);
      final data = res.data;
      List<dynamic> list = [];
      if (data is Map<String, dynamic> && data['results'] is List) {
        list = data['results'] as List;
      } else if (data is List) {
        list = data;
      }
      return list.map((e) => AuditLogItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
