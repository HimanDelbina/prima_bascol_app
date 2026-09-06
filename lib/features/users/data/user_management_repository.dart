import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/errors/failures.dart';
import '../domain/user_management_models.dart';

class UserManagementRepository {
  final ApiClient _apiClient;

  UserManagementRepository(this._apiClient);

  Future<List<UserAccountItem>> fetchUsers({String? search}) async {
    try {
      final res = await _apiClient.request(
        ApiEndpoints.users,
        queryParameters: search != null && search.isNotEmpty ? {'search': search} : null,
      );
      final data = res.data;
      List<dynamic> list = [];
      if (data is Map<String, dynamic> && data['results'] is List) {
        list = data['results'] as List;
      } else if (data is List) {
        list = data;
      }
      return list.map((e) => UserAccountItem.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> createUser(Map<String, dynamic> data) async {
    try {
      await _apiClient.request(ApiEndpoints.users, method: 'POST', data: data);
    } on ApiException catch (e) {
      if (e.code == 'VALIDATION_ERROR' && e.fieldErrors != null) {
        final messages = e.fieldErrors!.entries
            .map((entry) => "${entry.key}: ${(entry.value as List).join(' ')}")
            .join('\n');
        throw ValidationFailure(messages.isNotEmpty ? messages : e.message, fieldErrors: e.fieldErrors);
      }
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> toggleActive(int id, bool active) async {
    try {
      await _apiClient.request(
        ApiEndpoints.userDetail(id),
        method: 'PATCH',
        data: {'is_active': active},
      );
    } on ApiException catch (e) {
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
