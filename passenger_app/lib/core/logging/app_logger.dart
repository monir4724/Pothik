import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

enum LogLevel { debug, info, warn, error }

/// Structured logger with PII scrubbing. Everything that could leave the
/// device (Sentry breadcrumbs, crash context) passes through [scrub] first:
/// phone numbers are masked and coordinates are truncated to ~1km precision.
final class AppLogger {
  const AppLogger(this.scope);

  final String scope;

  static final RegExp _phone = RegExp(r'(\+?880|0)1[3-9]\d{8}');
  static final RegExp _coord = RegExp(r'(-?\d{1,3}\.\d{3})\d+');
  static final RegExp _bearer = RegExp(r'Bearer\s+[A-Za-z0-9\-_.]+');

  static String scrub(String input) => input
      .replaceAllMapped(_phone, (m) {
        final s = m.group(0)!;
        return '${s.substring(0, 4)}****${s.substring(s.length - 2)}';
      })
      .replaceAllMapped(_coord, (m) => '${m.group(1)}x')
      .replaceAll(_bearer, 'Bearer [redacted]');

  void debug(String message, [Map<String, Object?>? data]) =>
      _log(LogLevel.debug, message, data);

  void info(String message, [Map<String, Object?>? data]) =>
      _log(LogLevel.info, message, data);

  void warn(String message, [Map<String, Object?>? data]) =>
      _log(LogLevel.warn, message, data);

  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? data,
  }) {
    _log(LogLevel.error, message, data);
    if (error != null) {
      unawaited(
        Sentry.captureException(
          error,
          stackTrace: stackTrace,
          withScope: (s) {
            s.setTag('scope', scope);
            if (data != null) s.setContexts('data', _scrubMap(data));
          },
        ),
      );
    }
  }

  void _log(LogLevel level, String message, Map<String, Object?>? data) {
    final scrubbed = scrub(message);
    final scrubbedData = data == null ? null : _scrubMap(data);
    if (kDebugMode) {
      dev.log(
        scrubbedData == null ? scrubbed : '$scrubbed $scrubbedData',
        name: 'pothik.$scope',
        level: switch (level) {
          LogLevel.debug => 500,
          LogLevel.info => 800,
          LogLevel.warn => 900,
          LogLevel.error => 1000,
        },
      );
    }
    if (level.index >= LogLevel.info.index) {
      Sentry.addBreadcrumb(
        Breadcrumb(
          category: scope,
          message: scrubbed,
          data: scrubbedData,
          level: switch (level) {
            LogLevel.debug => SentryLevel.debug,
            LogLevel.info => SentryLevel.info,
            LogLevel.warn => SentryLevel.warning,
            LogLevel.error => SentryLevel.error,
          },
        ),
      );
    }
  }

  static Map<String, Object?> _scrubMap(Map<String, Object?> data) => {
    for (final e in data.entries)
      e.key: e.value is String ? scrub(e.value! as String) : e.value,
  };
}
