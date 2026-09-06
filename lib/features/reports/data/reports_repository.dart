import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/errors/failures.dart';
import '../../tickets/domain/ticket_models.dart';
import '../domain/report_models.dart';

class ReportsRepository {
  final ApiClient _apiClient;

  ReportsRepository(this._apiClient);

  Future<ReportSummaryModel> fetchSummary(Map<String, dynamic> params) async {
    try {
      final res = await _apiClient.request(
        ApiEndpoints.reportSummary,
        queryParameters: params,
      );
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return ReportSummaryModel.fromJson(data);
      }
      return ReportSummaryModel(
        totalTickets: 0,
        totalGrossWeight: 0,
        totalTareWeight: 0,
        totalNetWeight: 0,
        totalSentWeight: 0,
        totalWeightDifference: 0,
        totalLossWeight: 0,
        totalFinalWeight: 0,
      );
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<List<GroupedReportItem>> fetchGrouped(Map<String, dynamic> params) async {
    try {
      final res = await _apiClient.request(
        ApiEndpoints.reportGrouped,
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
      return list.map((e) => GroupedReportItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<List<WeighTicketListModel>> fetchReportTickets(Map<String, dynamic> params) async {
    try {
      final res = await _apiClient.request(
        ApiEndpoints.reportTickets,
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
      return list.map((e) => WeighTicketListModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
