class PaginatedResponse<T> {
  final int count;
  final String? next;
  final String? previous;
  final List<T> results;

  PaginatedResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final rawResults = json['results'];
    final List<T> items = [];
    if (rawResults is List) {
      for (var item in rawResults) {
        if (item is Map<String, dynamic>) {
          items.add(fromJsonT(item));
        }
      }
    }
    return PaginatedResponse<T>(
      count: json['count'] is int ? json['count'] : items.length,
      next: json['next']?.toString(),
      previous: json['previous']?.toString(),
      results: items,
    );
  }
}

class ApiEnvelope<T> {
  final bool success;
  final String message;
  final T? data;

  ApiEnvelope({
    required this.success,
    required this.message,
    this.data,
  });

  factory ApiEnvelope.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    return ApiEnvelope<T>(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: json['data'] != null ? fromJsonT(json['data']) : null,
    );
  }
}
