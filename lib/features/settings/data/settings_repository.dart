import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/errors/failures.dart';
import '../domain/settings_models.dart';

class SettingsRepository {
  final ApiClient _apiClient;

  SettingsRepository(this._apiClient);

  Future<SystemSettingsModel> fetchSettings() async {
    try {
      final res = await _apiClient.request(ApiEndpoints.settings);
      if (res.data is Map<String, dynamic>) {
        return SystemSettingsModel.fromJson(res.data as Map<String, dynamic>);
      }
      return SystemSettingsModel(
        companyName: 'سامانه مدیریت باسکول پریما',
        defaultTolerancePercent: 1.5,
        enforceSequentialWeights: true,
        allowManualWeightEntry: true,
        apiBaseUrl: 'http://127.0.0.1:8000/api/v1',
      );
    } catch (e) {
      return SystemSettingsModel(
        companyName: 'سامانه مدیریت باسکول پریما',
        defaultTolerancePercent: 1.5,
        enforceSequentialWeights: true,
        allowManualWeightEntry: true,
        apiBaseUrl: 'http://127.0.0.1:8000/api/v1',
      );
    }
  }

  Future<void> updateSettings(Map<String, dynamic> data) async {
    try {
      await _apiClient.request(ApiEndpoints.settings, method: 'POST', data: data);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
