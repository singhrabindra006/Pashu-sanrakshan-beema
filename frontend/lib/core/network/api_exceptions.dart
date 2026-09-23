/// One failure type per thing the UI reacts to differently.
sealed class AppException implements Exception {
  const AppException(this.message, {this.statusCode, this.code, this.fieldErrors});

  final String message;
  final int? statusCode;
  final String? code;

  /// Field-level messages from the backend's 422 response, keyed by field name.
  final Map<String, String>? fieldErrors;

  @override
  String toString() => '$runtimeType($statusCode): $message';
}

/// 5xx, or a response the app could not interpret.
class ServerException extends AppException {
  const ServerException(super.message, {super.statusCode, super.code});
}

/// No connectivity, DNS failure, timeout.
class NetworkException extends AppException {
  const NetworkException([
    super.message =
        'Cannot reach the LIMS server. Keep the phone on USB debugging and try again.',
  ]);
}

/// 401/403, or a Firebase credential problem.
class AuthException extends AppException {
  const AuthException(super.message, {super.statusCode, super.code});
}

/// 400/404/409 - the request was understood but refused.
class RequestException extends AppException {
  const RequestException(super.message, {super.statusCode, super.code});
}

/// 422 with per-field messages the forms can surface inline.
class ValidationException extends AppException {
  const ValidationException(super.message, {super.statusCode, super.code, super.fieldErrors});
}

/// User aborted (e.g. closed the file picker) - never show an error for this.
class CancelledException extends AppException {
  const CancelledException([super.message = 'Cancelled']);
}
