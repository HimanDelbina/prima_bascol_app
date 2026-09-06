import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/api_response.dart';
import '../../../core/errors/failures.dart';
import '../domain/ticket_models.dart';

class TicketRepository {
  final ApiClient _apiClient;

  TicketRepository(this._apiClient);

  Future<PaginatedResponse<WeighTicketListModel>> fetchTickets({
    int page = 1,
    String? search,
    String? status,
    String? startDateJalali,
    String? endDateJalali,
    int? productId,
    int? partyId,
    int? driverId,
    int? vehicleId,
    String? ordering,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (startDateJalali != null) queryParams['first_weight_date__gte'] = startDateJalali;
      if (endDateJalali != null) queryParams['first_weight_date__lte'] = endDateJalali;
      if (productId != null) queryParams['product'] = productId;
      if (partyId != null) queryParams['party'] = partyId;
      if (driverId != null) queryParams['driver'] = driverId;
      if (vehicleId != null) queryParams['vehicle'] = vehicleId;
      if (ordering != null) queryParams['ordering'] = ordering;

      final res = await _apiClient.request(
        ApiEndpoints.tickets,
        queryParameters: queryParams,
      );

      return PaginatedResponse<WeighTicketListModel>.fromJson(
        res.data as Map<String, dynamic>,
        (json) => WeighTicketListModel.fromJson(json),
      );
    } on ApiException catch (e) {
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<WeighTicketDetailModel> fetchTicketDetail(int id) async {
    try {
      final res = await _apiClient.request(ApiEndpoints.ticketDetail(id));
      return WeighTicketDetailModel.fromJson(res.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<WeighTicketDetailModel> createTicket(Map<String, dynamic> payload) async {
    try {
      final res = await _apiClient.request(
        ApiEndpoints.tickets,
        method: 'POST',
        data: payload,
      );
      return WeighTicketDetailModel.fromJson(res.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.code == 'VALIDATION_ERROR') {
        throw ValidationFailure(e.message, fieldErrors: e.fieldErrors);
      }
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<WeighTicketDetailModel> recordFirstWeight(int id, double weight) async {
    try {
      final res = await _apiClient.request(
        ApiEndpoints.ticketFirstWeight(id),
        method: 'POST',
        data: {'weight': weight},
      );
      final envelope = ApiEnvelope.fromJson(
        res.data as Map<String, dynamic>,
        (d) => WeighTicketDetailModel.fromJson(d as Map<String, dynamic>),
      );
      return envelope.data!;
    } on ApiException catch (e) {
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<WeighTicketDetailModel> recordSecondWeight(
    int id, {
    required double weight,
    double? lossPercent,
    int? lossTypeId,
  }) async {
    try {
      final payload = <String, dynamic>{'weight': weight};
      if (lossPercent != null) payload['loss_percent'] = lossPercent;
      if (lossTypeId != null) payload['loss_type'] = lossTypeId;

      final res = await _apiClient.request(
        ApiEndpoints.ticketSecondWeight(id),
        method: 'POST',
        data: payload,
      );
      final envelope = ApiEnvelope.fromJson(
        res.data as Map<String, dynamic>,
        (d) => WeighTicketDetailModel.fromJson(d as Map<String, dynamic>),
      );
      return envelope.data!;
    } on ApiException catch (e) {
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<WeighTicketDetailModel> completeTicket(int id, {String? notes}) async {
    try {
      final res = await _apiClient.request(
        ApiEndpoints.ticketComplete(id),
        method: 'POST',
        data: {'notes': notes ?? ''},
      );
      final envelope = ApiEnvelope.fromJson(
        res.data as Map<String, dynamic>,
        (d) => WeighTicketDetailModel.fromJson(d as Map<String, dynamic>),
      );
      return envelope.data!;
    } on ApiException catch (e) {
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<WeighTicketDetailModel> cancelTicket(int id, {required String reason}) async {
    try {
      final res = await _apiClient.request(
        ApiEndpoints.ticketCancel(id),
        method: 'POST',
        data: {'reason': reason},
      );
      final envelope = ApiEnvelope.fromJson(
        res.data as Map<String, dynamic>,
        (d) => WeighTicketDetailModel.fromJson(d as Map<String, dynamic>),
      );
      return envelope.data!;
    } on ApiException catch (e) {
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<WeighTicketDetailModel> correctTicket(
    int id, {
    required String field,
    required String newValue,
    required String reason,
  }) async {
    try {
      final res = await _apiClient.request(
        ApiEndpoints.ticketCorrect(id),
        method: 'POST',
        data: {
          'field': field,
          'new_value': newValue,
          'reason': reason,
        },
      );
      final envelope = ApiEnvelope.fromJson(
        res.data as Map<String, dynamic>,
        (d) => WeighTicketDetailModel.fromJson(d as Map<String, dynamic>),
      );
      return envelope.data!;
    } on ApiException catch (e) {
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<List<Map<String, dynamic>>> fetchWaitingSecondWeight() async {
    try {
      final res = await _apiClient.request(ApiEndpoints.ticketsWaitingSecond);
      final data = res.data;
      if (data is Map<String, dynamic> && data['results'] is List) {
        return (data['results'] as List).map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } on ApiException catch (e) {
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
