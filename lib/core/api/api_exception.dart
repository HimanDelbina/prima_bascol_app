class ApiException implements Exception {
  final String message;
  final String code;
  final int? statusCode;
  final Map<String, List<String>> fieldErrors;

  ApiException({
    required this.message,
    this.code = 'UNKNOWN_ERROR',
    this.statusCode,
    this.fieldErrors = const {},
  });

  factory ApiException.fromResponse(Map<String, dynamic> json, int? statusCode) {
    String msg = "خطایی در پردازش درخواست رخ داد.";
    String code = "API_ERROR";
    Map<String, List<String>> fields = {};

    if (json.containsKey('error') && json['error'] is Map) {
      final err = json['error'] as Map<String, dynamic>;
      msg = err['message']?.toString() ?? msg;
      code = err['code']?.toString() ?? code;
      
      if (err.containsKey('fields') && err['fields'] is Map) {
        final fMap = err['fields'] as Map<String, dynamic>;
        fMap.forEach((key, val) {
          if (val is List) {
            fields[key] = val.map((e) => e.toString()).toList();
          } else {
            fields[key] = [val.toString()];
          }
        });
      }
    } else if (json.containsKey('detail')) {
      msg = json['detail'].toString();
    } else if (json.containsKey('message')) {
      msg = json['message'].toString();
    }

    return ApiException(
      message: msg,
      code: code,
      statusCode: statusCode,
      fieldErrors: fields,
    );
  }

  @override
  String toString() => message;
}
