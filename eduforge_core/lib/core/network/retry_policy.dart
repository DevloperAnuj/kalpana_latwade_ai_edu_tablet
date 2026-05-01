import '../error/app_exception.dart';

/// Exponential-backoff retry for network / database calls.
///
/// Usage:
///   final result = await RetryPolicy.run(() => mySupabaseCall());
class RetryPolicy {
  const RetryPolicy._();

  static const int _maxAttempts = 3;
  static const Duration _baseDelay = Duration(seconds: 1);

  /// Retries [fn] up to [maxAttempts] times with exponential backoff.
  ///
  /// Only retries on [NetworkException] or when [shouldRetry] returns true.
  /// Never retries on [AuthException], [PermissionException], or
  /// [ValidationException] — those are caller errors, not transient faults.
  static Future<T> run<T>(
    Future<T> Function() fn, {
    int maxAttempts = _maxAttempts,
    bool Function(Object error)? shouldRetry,
  }) async {
    int attempt = 0;
    while (true) {
      try {
        return await fn();
      } catch (e) {
        attempt++;
        final retry = shouldRetry?.call(e) ?? _defaultShouldRetry(e);
        if (!retry || attempt >= maxAttempts) rethrow;
        final delay = _baseDelay * (1 << (attempt - 1)); // 1s, 2s, 4s
        await Future<void>.delayed(delay);
      }
    }
  }

  static bool _defaultShouldRetry(Object error) {
    if (error is AuthException || error is PermissionException || error is ValidationException) {
      return false;
    }
    if (error is NetworkException) return true;
    // Retry Supabase network-level and 5xx errors but not client errors.
    final msg = error.toString().toLowerCase();
    return msg.contains('network') ||
        msg.contains('timeout') ||
        msg.contains('connection') ||
        msg.contains('503') ||
        msg.contains('502') ||
        msg.contains('500');
  }
}
