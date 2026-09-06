import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/plate_formatter.dart';
import '../domain/masterdata_models.dart';

class MasterDataRepository {
  final ApiClient _apiClient;

  MasterDataRepository(this._apiClient);

  List<dynamic> _extractResults(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['results'] is List) return data['results'] as List;
      if (data['data'] is List) return data['data'] as List;
    } else if (data is List) {
      return data;
    }
    return [];
  }

  // Products
  Future<List<ProductItem>> fetchProducts({String? search}) async {
    try {
      final res = await _apiClient.request(
        ApiEndpoints.products,
        queryParameters: search != null && search.isNotEmpty ? {'search': search} : null,
      );
      return _extractResults(res.data).map((e) => ProductItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<ProductItem> saveProduct(Map<String, dynamic> data, {int? id}) async {
    try {
      final url = id != null ? ApiEndpoints.productDetail(id) : ApiEndpoints.products;
      final method = id != null ? 'PUT' : 'POST';
      final res = await _apiClient.request(url, method: method, data: data);
      return ProductItem.fromJson(res.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  // Parties
  Future<List<PartyItem>> fetchParties({String? search}) async {
    try {
      final res = await _apiClient.request(
        ApiEndpoints.parties,
        queryParameters: search != null && search.isNotEmpty ? {'search': search} : null,
      );
      return _extractResults(res.data).map((e) => PartyItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<PartyItem> saveParty(Map<String, dynamic> data, {int? id}) async {
    try {
      final url = id != null ? ApiEndpoints.partyDetail(id) : ApiEndpoints.parties;
      final method = id != null ? 'PUT' : 'POST';
      final res = await _apiClient.request(url, method: method, data: data);
      return PartyItem.fromJson(res.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  // Drivers
  Future<List<DriverItem>> fetchDrivers({String? search}) async {
    try {
      final res = await _apiClient.request(
        ApiEndpoints.drivers,
        queryParameters: search != null && search.isNotEmpty ? {'search': search} : null,
      );
      return _extractResults(res.data).map((e) => DriverItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<DriverItem> saveDriver(Map<String, dynamic> data, {int? id}) async {
    try {
      final payload = Map<String, dynamic>.from(data);
      if (!payload.containsKey('full_name') && payload.containsKey('name')) {
        payload['full_name'] = payload['name'];
      }
      final url = id != null ? ApiEndpoints.driverDetail(id) : ApiEndpoints.drivers;
      final method = id != null ? 'PUT' : 'POST';
      final res = await _apiClient.request(url, method: method, data: payload);
      return DriverItem.fromJson(res.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  // Vehicles
  Future<List<VehicleItem>> fetchVehicles({String? search}) async {
    try {
      final res = await _apiClient.request(
        ApiEndpoints.vehicles,
        queryParameters: search != null && search.isNotEmpty ? {'search': search} : null,
      );
      return _extractResults(res.data).map((e) => VehicleItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<VehicleItem> saveVehicle(Map<String, dynamic> data, {int? id}) async {
    try {
      final payload = Map<String, dynamic>.from(data);
      if (!payload.containsKey('plate_part1') && payload.containsKey('plate_number')) {
        final parsed = PlateFormatter.parsePlate(payload['plate_number']?.toString());
        if (parsed != null) {
          payload['plate_part1'] = parsed.part1;
          payload['plate_letter'] = parsed.letter;
          payload['plate_part2'] = parsed.part2;
          payload['plate_iran'] = parsed.iranCode;
        }
      }
      final url = id != null ? ApiEndpoints.vehicleDetail(id) : ApiEndpoints.vehicles;
      final method = id != null ? 'PUT' : 'POST';
      final res = await _apiClient.request(url, method: method, data: payload);
      return VehicleItem.fromJson(res.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  // Generic Simple Lists (Locations, LossTypes, OperationTypes)
  Future<List<SimpleMasterItem>> fetchGenericList(String endpoint, {String? search}) async {
    try {
      final res = await _apiClient.request(
        endpoint,
        queryParameters: search != null && search.isNotEmpty ? {'search': search} : null,
      );
      return _extractResults(res.data).map((e) => SimpleMasterItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<SimpleMasterItem> saveGenericItem(String endpoint, Map<String, dynamic> data, {int? id}) async {
    try {
      final url = id != null ? '$endpoint$id/' : endpoint;
      final method = id != null ? 'PUT' : 'POST';
      final res = await _apiClient.request(url, method: method, data: data);
      return SimpleMasterItem.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
