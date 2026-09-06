import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/errors/failures.dart';
import '../domain/yard_truck_model.dart';

class YardRepository {
  final ApiClient _apiClient;

  YardRepository(this._apiClient);

  Future<List<YardTruckModel>> fetchWaitingTrucks() async {
    try {
      final res = await _apiClient.request(ApiEndpoints.ticketsWaitingSecond);
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
      return list.map((item) => YardTruckModel.fromJson(item as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
