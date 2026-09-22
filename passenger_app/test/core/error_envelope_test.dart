import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pothik_passenger/core/network/api_exception.dart';
import 'package:pothik_passenger/core/network/error_envelope.dart';

Response<Object?> _res(
  int status,
  Object? body, {
  Map<String, String>? headers,
}) => Response<Object?>(
  requestOptions: RequestOptions(path: '/x'),
  statusCode: status,
  data: body,
  headers: Headers.fromMap({
    for (final e in (headers ?? {}).entries) e.key: [e.value],
  }),
);

void main() {
  test('parses standard envelope with business code', () {
    final e = ErrorEnvelope.fromResponse(
      _res(409, {
        'error': {'code': 'ACTIVE_RIDE_EXISTS', 'message': 'nope'},
      }),
    );
    expect(e.code, ApiErrorCode.conflict);
    expect(e.serverCode, ServerErrorCodes.activeRideExists);
    expect(e.serverMessage, 'nope');
    expect(e.isRetryable, isFalse);
  });

  test('parses Laravel default 422 shape into fieldErrors', () {
    final e = ErrorEnvelope.fromResponse(
      _res(422, {
        'message': 'The given data was invalid.',
        'errors': {
          'phone': ['The phone field is required.'],
        },
      }),
    );
    expect(e.code, ApiErrorCode.validation);
    expect(e.fieldErrors['phone'], ['The phone field is required.']);
  });

  test('429 carries Retry-After', () {
    final e = ErrorEnvelope.fromResponse(
      _res(
        429,
        {
          'error': {'code': 'THROTTLED'},
        },
        headers: {'retry-after': '120'},
      ),
    );
    expect(e.code, ApiErrorCode.rateLimited);
    expect(e.retryAfter, const Duration(seconds: 120));
  });

  test('5xx is retryable, 401 is unauthenticated', () {
    expect(ErrorEnvelope.fromResponse(_res(503, null)).isRetryable, isTrue);
    expect(
      ErrorEnvelope.fromResponse(_res(401, null)).code,
      ApiErrorCode.unauthenticated,
    );
  });

  test('transport errors map to network/timeout', () {
    final timeout = DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.receiveTimeout,
    );
    expect(ErrorEnvelope.fromDioException(timeout).code, ApiErrorCode.timeout);

    final conn = DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.connectionError,
    );
    expect(ErrorEnvelope.fromDioException(conn).code, ApiErrorCode.network);
  });
}
