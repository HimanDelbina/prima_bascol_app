abstract class Failure {
  final String message;
  final String? code;
  final Map<String, dynamic>? details;

  const Failure(this.message, {this.code, this.details});

  @override
  String toString() => message;
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = "خطای اتصال به شبکه. لطفاً ارتباط اینترنت یا سرور را بررسی کنید."])
      : super(message, code: "NETWORK_ERROR");
}

class ServerFailure extends Failure {
  const ServerFailure(String message, {String? code, Map<String, dynamic>? details})
      : super(message, code: code ?? "SERVER_ERROR", details: details);
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure([String message = "احراز هویت ناموفق بود یا نشست شما منقضی شده است."])
      : super(message, code: "AUTH_ERROR");
}

class PermissionFailure extends Failure {
  const PermissionFailure([String message = "شما دسترسی لازم برای انجام این عملیات را ندارید."])
      : super(message, code: "PERMISSION_DENIED");
}

class ValidationFailure extends Failure {
  final Map<String, List<String>> fieldErrors;
  const ValidationFailure(String message, {this.fieldErrors = const {}, String? code})
      : super(message, code: code ?? "VALIDATION_ERROR");
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([String message = "مهلت زمانی ارتباط با سرور به پایان رسید."])
      : super(message, code: "TIMEOUT_ERROR");
}

class ConflictFailure extends Failure {
  const ConflictFailure(String message)
      : super(message, code: "CONFLICT_ERROR");
}
