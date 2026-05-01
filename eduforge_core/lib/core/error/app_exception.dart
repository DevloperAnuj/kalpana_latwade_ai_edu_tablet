/// Typed application exceptions used across all packages.
/// Throw these from repositories; catch them in BLoCs.

sealed class AppException implements Exception {
  const AppException(this.message, [this.cause]);
  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message${cause != null ? ' ($cause)' : ''}';
}

class NetworkException extends AppException {
  const NetworkException(super.message, [super.cause]);
}

class AuthException extends AppException {
  const AuthException(super.message, [super.cause]);
}

class DatabaseException extends AppException {
  const DatabaseException(super.message, [super.cause]);
}

class ValidationException extends AppException {
  const ValidationException(super.message, [super.cause]);
}

class RateLimitException extends AppException {
  const RateLimitException([String message = 'Too many requests. Please wait before trying again.'])
      : super(message);
}

class NotFoundException extends AppException {
  const NotFoundException(super.message, [super.cause]);
}

class PermissionException extends AppException {
  const PermissionException(super.message, [super.cause]);
}
