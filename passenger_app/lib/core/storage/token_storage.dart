import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Auth session as issued by the backend. Refresh tokens rotate on every
/// use; the old one is invalid once a new pair is stored.
final class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiresAt,
  });

  factory AuthTokens.fromJson(Map<String, Object?> json) => AuthTokens(
    accessToken: json['access_token'] as String,
    refreshToken: json['refresh_token'] as String,
    accessExpiresAt: DateTime.parse(json['access_expires_at'] as String),
  );

  final String accessToken;
  final String refreshToken;
  final DateTime accessExpiresAt;

  Map<String, Object?> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'access_expires_at': accessExpiresAt.toUtc().toIso8601String(),
  };

  /// Treat the token as expired 30s early to avoid racing the server clock.
  bool get isAccessExpired => DateTime.now()
      .toUtc()
      .add(const Duration(seconds: 30))
      .isAfter(accessExpiresAt.toUtc());
}

abstract interface class TokenStorage {
  Future<AuthTokens?> read();
  Future<void> write(AuthTokens tokens);
  Future<void> clear();
}

/// Keychain / Keystore-backed storage. Tokens never touch SharedPreferences.
final class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  static const _key = 'pothik.auth.tokens.v1';
  final FlutterSecureStorage _storage;
  AuthTokens? _cache;

  @override
  Future<AuthTokens?> read() async {
    if (_cache != null) return _cache;
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    try {
      _cache = AuthTokens.fromJson(jsonDecode(raw) as Map<String, Object?>);
      return _cache;
    } on Object {
      // Corrupt entry — clear rather than crash-loop on every launch.
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(AuthTokens tokens) async {
    _cache = tokens;
    await _storage.write(key: _key, value: jsonEncode(tokens.toJson()));
  }

  @override
  Future<void> clear() async {
    _cache = null;
    await _storage.delete(key: _key);
  }
}

/// In-memory implementation for tests and the fake backend.
final class InMemoryTokenStorage implements TokenStorage {
  AuthTokens? _tokens;

  @override
  Future<AuthTokens?> read() async => _tokens;

  @override
  Future<void> write(AuthTokens tokens) async => _tokens = tokens;

  @override
  Future<void> clear() async => _tokens = null;
}
