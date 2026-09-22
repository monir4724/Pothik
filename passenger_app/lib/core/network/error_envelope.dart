import 'package:dio/dio.dart';

import 'api_exception.dart';

/// Parses the backend's consistent error envelope:
///
/// ```json
/// { "error": { "code": "ACTIVE_RIDE_EXISTS", "message": "...", "details": {...} } }
/// ```
/// and tolerates Laravel's default 422 shape
/// `{ "message": "...", "errors": { "field": ["msg"] } }`.
abstract final class ErrorEnvelope {
  static ApiException fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException.timeout(e);
      case DioExceptionType.connectionError:
        return ApiException.network(e);
      case DioExceptionType.cancel:
        return const ApiException.cancelled();
      case DioExceptionType.badCertificate:
        return ApiException(code: ApiErrorCode.network, cause: e);
      case DioExceptionType.badResponse:
        return fromResponse(e.response!, cause: e);
      case DioExceptionType.unknown:
        return ApiException.network(e);
      default:
        return ApiException.unknown(e);
    }
  }

  static ApiException fromResponse(
    Response<Object?> response, {
    Object? cause,
  }) {
    final status = response.statusCode ?? 0;
    final data = response.data;
    String? serverCode;
    String? message;
    final fieldErrors = <String, List<String>>{};

    if (data is Map<String, Object?>) {
      final error = data['error'];
      if (error is Map<String, Object?>) {
        serverCode = error['code']?.toString();
        message = error['message']?.toString();
        final details = error['details'];
        if (details is Map<String, Object?>) {
          _collectFields(details, fieldErrors);
        }
      } else {
        message = data['message']?.toString();
        serverCode = data['code']?.toString();
      }
      final errors = data['errors'];
      if (errors is Map<String, Object?>) _collectFields(errors, fieldErrors);
    }

    final retryAfterHeader = response.headers.value('retry-after');
    final retryAfter = retryAfterHeader == null
        ? null
        : Duration(seconds: int.tryParse(retryAfterHeader) ?? 60);

    final code = switch (status) {
      401 => ApiErrorCode.unauthenticated,
      403 => ApiErrorCode.forbidden,
      404 => ApiErrorCode.notFound,
      409 => ApiErrorCode.conflict,
      422 => ApiErrorCode.validation,
      429 => ApiErrorCode.rateLimited,
      >= 500 => ApiErrorCode.server,
      _ => ApiErrorCode.unknown,
    };

    return ApiException(
      code: code,
      statusCode: status,
      serverCode: serverCode,
      serverMessage: message,
      fieldErrors: fieldErrors,
      retryAfter: retryAfter,
      cause: cause,
    );
  }

  static void _collectFields(
    Map<String, Object?> source,
    Map<String, List<String>> into,
  ) {
    for (final entry in source.entries) {
      final v = entry.value;
      if (v is List) {
        into[entry.key] = v.map((e) => e.toString()).toList();
      } else if (v is String) {
        into[entry.key] = [v];
      }
    }
  }
}
