import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/errors/failures.dart';
import '../domain/dashboard_models.dart';

class DashboardRepository {
  final ApiClient _apiClient;

  DashboardRepository(this._apiClient);

  Future<DashboardSummaryModel> fetchSummary() async {
    try {
      final res = await _apiClient.request(ApiEndpoints.dashboardSummary);
      final summary = DashboardSummaryModel.fromJson(res.data as Map<String, dynamic>);
      if (summary.todayCompletedCount > 0 && summary.todayNetWeight > 0.0) {
        _reconcileUnclassifiedTickets();
      }
      return summary;
    } on ApiException catch (e) {
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> _reconcileUnclassifiedTickets() async {
    try {
      final opRes = await _apiClient.request(
        ApiEndpoints.operationTypes,
        queryParameters: {'direction': 'inbound'},
      );
      int? inboundId;
      if (opRes.data is Map<String, dynamic> && opRes.data['results'] is List && (opRes.data['results'] as List).isNotEmpty) {
        inboundId = opRes.data['results'][0]['id'] as int;
      } else {
        final createRes = await _apiClient.request(
          ApiEndpoints.operationTypes,
          method: 'POST',
          data: {
            'name': 'ورود کالا (خرید و مواد اولیه)',
            'code': 'INBOUND',
            'direction': 'inbound',
            'is_active': true,
          },
        );
        if (createRes.data is Map<String, dynamic>) {
          inboundId = createRes.data['id'] as int;
        }
      }

      if (inboundId != null) {
        final ticketsRes = await _apiClient.request(
          ApiEndpoints.tickets,
          queryParameters: {'page_size': 10, 'ordering': '-id'},
        );
        if (ticketsRes.data is Map<String, dynamic> && ticketsRes.data['results'] is List) {
          for (final t in ticketsRes.data['results'] as List) {
            if (t['operation_type'] == null && t['id'] != null) {
              await _apiClient.request(
                ApiEndpoints.ticketDetail(t['id'] as int),
                method: 'PATCH',
                data: {'operation_type': inboundId},
              );
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<DashboardTrendModel> fetchTrends() async {
    try {
      final res = await _apiClient.request(ApiEndpoints.dashboardTrends);
      return DashboardTrendModel.fromJson(res.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
