import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Central error logger.  In debug, prints to console.
/// In production, the [addReporter] hook lets you wire Sentry or any other
/// remote service without changing call sites.
class ErrorLogger {
  ErrorLogger._();
  static final ErrorLogger instance = ErrorLogger._();

  final List<ErrorReporter> _reporters = [];

  void addReporter(ErrorReporter reporter) => _reporters.add(reporter);

  void logError(
    dynamic error,
    StackTrace? stack, {
    String? context,
    Map<String, dynamic>? extra,
  }) {
    final userId = _currentUserId();
    final timestamp = DateTime.now().toIso8601String();
    final message = _format(error, context, userId, timestamp, extra);

    if (kDebugMode) {
      developer.log(message, name: 'EduForge', error: error, stackTrace: stack);
    }

    for (final reporter in _reporters) {
      try {
        reporter.report(error, stack, context: context, extra: {
          'userId': userId,
          'timestamp': timestamp,
          if (extra != null) ...extra,
        });
      } catch (_) {
        // Never let a reporter crash the app.
      }
    }
  }

  void logWarning(String message, {String? context}) {
    if (kDebugMode) {
      developer.log('[WARN] $message', name: context ?? 'EduForge');
    }
  }

  String _currentUserId() {
    try {
      return Supabase.instance.client.auth.currentUser?.id ?? 'unauthenticated';
    } catch (_) {
      return 'unauthenticated';
    }
  }

  String _format(
    dynamic error,
    String? context,
    String userId,
    String timestamp,
    Map<String, dynamic>? extra,
  ) {
    final buf = StringBuffer()
      ..write('[EduForge] ')
      ..write(timestamp)
      ..write(' | user=$userId');
    if (context != null) buf.write(' | ctx=$context');
    buf.write('\n  error: $error');
    if (extra != null && extra.isNotEmpty) buf.write('\n  extra: $extra');
    return buf.toString();
  }
}

abstract interface class ErrorReporter {
  void report(
    dynamic error,
    StackTrace? stack, {
    String? context,
    Map<String, dynamic>? extra,
  });
}
