/// Stable, UI-facing error codes. The UI maps these to localized copy and
/// **never** shows raw server text (production build doc §5).
enum ApiErrorCode {
  /// No connectivity / DNS / socket failure.
  network,

  /// Request exceeded its timeout — distinct from "no drivers found".
  timeout,

  /// 401 — session invalid and refresh failed. Caller must re-auth.
  unauthenticated,

  /// 403.
  forbidden,

  /// 404.
  notFound,

  /// 409 — e.g. booking while an active ride exists.
  conflict,

  /// 422 — field errors available in [ApiException.fieldErrors].
  validation,

  /// 429 — retry-after in [ApiException.retryAfter].
  rateLimited,

  /// 5xx.
  server,

  /// Request was cancelled by the caller.
  cancelled,

  /// Anything we couldn't classify.
  unknown,
}

/// Server-specific business codes carried in the error envelope's `code`.
/// Kept as strings so a new backend code doesn't crash old clients.
abstract final class ServerErrorCodes {
  static const String activeRideExists = 'ACTIVE_RIDE_EXISTS';
  static const String otpInvalid = 'OTP_INVALID';
  static const String otpExpired = 'OTP_EXPIRED';
  static const String rideNotCancellable = 'RIDE_NOT_CANCELLABLE';
  static const String tripNotActive = 'TRIP_NOT_ACTIVE';
  static const String chatClosed = 'CHAT_CLOSED';
  static const String shareLinkExpired = 'SHARE_LINK_EXPIRED';
  static const String noDriversAvailable = 'NO_DRIVERS_AVAILABLE';
}

final class ApiException implements Exception {
  const ApiException({
    required this.code,
    this.statusCode,
    this.serverCode,
    this.serverMessage,
    this.fieldErrors = const {},
    this.retryAfter,
    this.cause,
  });

  const ApiException.network([Object? cause])
    : this(code: ApiErrorCode.network, cause: cause);

  const ApiException.timeout([Object? cause])
    : this(code: ApiErrorCode.timeout, cause: cause);

  const ApiException.cancelled() : this(code: ApiErrorCode.cancelled);

  const ApiException.unknown([Object? cause])
    : this(code: ApiErrorCode.unknown, cause: cause);

  final ApiErrorCode code;
  final int? statusCode;

  /// Business code from the envelope, e.g. `ACTIVE_RIDE_EXISTS`.
  final String? serverCode;

  /// Server message — for logs only, never for UI.
  final String? serverMessage;

  /// 422 field → messages.
  final Map<String, List<String>> fieldErrors;
  final Duration? retryAfter;
  final Object? cause;

  bool get isRetryable => switch (code) {
    ApiErrorCode.network || ApiErrorCode.timeout || ApiErrorCode.server => true,
    _ => false,
  };

  bool hasServerCode(String c) => serverCode == c;

  @override
  String toString() =>
      'ApiException($code, status=$statusCode, serverCode=$serverCode)';
}
