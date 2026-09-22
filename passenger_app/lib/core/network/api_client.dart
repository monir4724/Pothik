import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../logging/app_logger.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'error_envelope.dart';

/// Called when the refresh token is rejected — the session is gone and the
/// app must return to login.
typedef SessionExpiredHandler = FutureOr<void> Function();

/// Header for idempotent mutations (booking, cash-confirm, SOS). The server
/// stores the key per user and replays the original response on duplicates.
const String kIdempotencyKeyHeader = 'Idempotency-Key';

final class ApiClient {
  ApiClient({
    required AppConfig config,
    required TokenStorage tokenStorage,
    required SessionExpiredHandler onSessionExpired,
    required String deviceId,
    Dio? dio,
  }) : _tokens = tokenStorage,
       // ignore: prefer_initializing_formals
       _onSessionExpired = onSessionExpired,
       dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: config.apiBaseUrl,
               connectTimeout: const Duration(seconds: 10),
               receiveTimeout: const Duration(seconds: 20),
               sendTimeout: const Duration(seconds: 15),
               headers: {
                 'Accept': 'application/json',
                 'Content-Type': 'application/json',
                 'X-Client': 'pothik-passenger',
                 'X-Device-Id': deviceId,
                 'X-Platform': defaultTargetPlatform.name,
               },
               // Let interceptors decide; don't throw on 4xx before mapping.
               validateStatus: (s) => s != null && s < 400,
             ),
           ) {
    this.dio.interceptors.addAll([
      _AuthInterceptor(this),
      _ErrorMappingInterceptor(),
    ]);
  }

  static const _log = AppLogger('api');

  final Dio dio;
  final TokenStorage _tokens;
  final SessionExpiredHandler _onSessionExpired;

  /// Single-flight refresh: concurrent 401s await the same future so we
  /// never burn a rotated refresh token twice.
  Future<AuthTokens?>? _refreshing;

  Future<String?> _accessToken() async {
    final t = await _tokens.read();
    if (t == null) return null;
    if (!t.isAccessExpired) return t.accessToken;
    final refreshed = await refreshTokens();
    return refreshed?.accessToken;
  }

  /// Rotates the token pair. Returns `null` (after signalling session
  /// expiry) when the refresh token itself is rejected.
  Future<AuthTokens?> refreshTokens() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<AuthTokens?> _doRefresh() async {
    final current = await _tokens.read();
    if (current == null) return null;
    try {
      // Bare Dio so we don't recurse through the auth interceptor.
      final bare = Dio(dio.options.copyWith(headers: {...dio.options.headers}));
      final res = await bare.post<Map<String, Object?>>(
        '/auth/refresh',
        data: {'refresh_token': current.refreshToken},
      );
      final data = res.data?['data'] ?? res.data;
      final next = AuthTokens.fromJson(data! as Map<String, Object?>);
      await _tokens.write(next);
      _log.info('token refreshed');
      return next;
    } on DioException catch (e) {
      final mapped = ErrorEnvelope.fromDioException(e);
      if (mapped.code == ApiErrorCode.unauthenticated ||
          mapped.code == ApiErrorCode.forbidden ||
          mapped.code == ApiErrorCode.validation) {
        _log.warn('refresh rejected; ending session');
        await _tokens.clear();
        await _onSessionExpired();
        return null;
      }
      // Network blip: keep the existing (possibly still valid) tokens.
      rethrow;
    }
  }
}

final class _AuthInterceptor extends QueuedInterceptor {
  _AuthInterceptor(this._client);

  final ApiClient _client;
  static const _skipAuth = 'skipAuth';
  static const _retried = 'authRetried';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[_skipAuth] == true) return handler.next(options);
    try {
      final token = await _client._accessToken();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
      handler.next(options);
    } on DioException catch (e) {
      handler.reject(e);
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final opts = err.requestOptions;
    if (status != 401 || opts.extra[_retried] == true) {
      return handler.next(err);
    }
    final next = await _client.refreshTokens();
    if (next == null) return handler.next(err);
    opts.extra[_retried] = true;
    opts.headers['Authorization'] = 'Bearer ${next.accessToken}';
    try {
      final res = await _client.dio.fetch<Object?>(opts);
      handler.resolve(res);
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}

/// Converts every DioException to an [ApiException] so repositories and UI
/// never see transport-level types.
final class _ErrorMappingInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final mapped = ErrorEnvelope.fromDioException(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: mapped,
        message: mapped.toString(),
      ),
    );
  }
}

/// Unwraps [ApiException] from a Dio call. Repositories use this so callers
/// get one exception type.
Future<T> guardApi<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on DioException catch (e) {
    final mapped = e.error;
    if (mapped is ApiException) throw mapped;
    throw ErrorEnvelope.fromDioException(e);
  }
}

extension RequestOptionsX on Options {
  Options skipAuth() => copyWith(extra: {...?extra, 'skipAuth': true});
}
