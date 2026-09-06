import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/errors/failures.dart';
import '../domain/management_models.dart';

class ManagementRepository {
  final ApiClient _apiClient;

  ManagementRepository(this._apiClient);

  static String normalizePeriod(String period) {
    switch (period) {
      case 'week':
        return 'this_week';
      case 'month':
        return 'this_month';
      case 'year':
        return 'this_year';
      default:
        return period;
    }
  }

  Map<String, dynamic> _buildQueryParams({
    String? period,
    String? quickPeriod,
    String? startDateJalali,
    String? endDateJalali,
  }) {
    final qp = <String, dynamic>{};
    final p = quickPeriod ?? period ?? 'this_month';
    if (p != 'custom') {
      final normalized = normalizePeriod(p);
      qp['quick_period'] = normalized;
      qp['period'] = normalized;
    }
    if (startDateJalali != null && startDateJalali.isNotEmpty) {
      qp['start_date_jalali'] = startDateJalali;
    }
    if (endDateJalali != null && endDateJalali.isNotEmpty) {
      qp['end_date_jalali'] = endDateJalali;
    }
    return qp;
  }

  Future<ManagementSummaryModel> fetchSummary([
    dynamic filterOrPeriod,
    String? startDateJalali,
    String? endDateJalali,
  ]) async {
    try {
      String? periodStr;
      if (filterOrPeriod is String) {
        periodStr = filterOrPeriod;
      }
      final qp = _buildQueryParams(
        quickPeriod: periodStr,
        startDateJalali: startDateJalali,
        endDateJalali: endDateJalali,
      );
      final res = await _apiClient.request(
        ApiEndpoints.managementSummary,
        queryParameters: qp,
      );
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return ManagementSummaryModel.fromJson(data);
      }
      return ManagementSummaryModel(
        period: qp['quick_period']?.toString() ?? 'this_month',
        totalTonnage: 0,
        totalServices: 0,
        tonnageChangePct: 0,
        servicesChangePct: 0,
        totalDiscrepancyTonnage: 0,
        totalLossTonnage: 0,
        averageTurnaroundMinutes: 0,
      );
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<List<ManagementBreakdownItem>> fetchProductBreakdown([
    dynamic filterOrPeriod,
    String? startDateJalali,
    String? endDateJalali,
  ]) async {
    try {
      String? periodStr;
      if (filterOrPeriod is String) {
        periodStr = filterOrPeriod;
      }
      final qp = _buildQueryParams(
        quickPeriod: periodStr,
        startDateJalali: startDateJalali,
        endDateJalali: endDateJalali,
      );
      final res = await _apiClient.request(
        ApiEndpoints.managementProducts,
        queryParameters: qp,
      );
      return _extractList(res.data);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<List<ManagementBreakdownItem>> fetchPartyBreakdown([
    dynamic filterOrPeriod,
    String? startDateJalali,
    String? endDateJalali,
  ]) async {
    try {
      String? periodStr;
      if (filterOrPeriod is String) {
        periodStr = filterOrPeriod;
      }
      final qp = _buildQueryParams(
        quickPeriod: periodStr,
        startDateJalali: startDateJalali,
        endDateJalali: endDateJalali,
      );
      final res = await _apiClient.request(
        ApiEndpoints.managementParties,
        queryParameters: qp,
      );
      return _extractList(res.data);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  List<ManagementBreakdownItem> _extractList(dynamic data) {
    List<dynamic> list = [];
    if (data is Map<String, dynamic>) {
      if (data['results'] is List) list = data['results'] as List;
      else if (data['data'] is List) list = data['data'] as List;
    } else if (data is List) {
      list = data;
    }
    return list.map((e) => ManagementBreakdownItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}
