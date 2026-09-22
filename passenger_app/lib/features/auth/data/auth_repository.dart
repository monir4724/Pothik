import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/user.dart';

abstract interface class AuthRepository {
  /// POST /auth/otp/request — server enforces 3 req / 10 min per phone.
  Future<OtpChallenge> requestOtp(String phone);

  /// POST /auth/otp/verify — stores the token pair on success.
  Future<User> verifyOtp({required String phone, required String code});

  /// GET /me — `null` when no valid session exists.
  Future<User?> currentUser();

  Future<User> updateProfile({
    String? name,
    String? email,
    String? locale,
    String? photoUrl,
    bool clearPhoto = false,
    String? username,
    Gender? gender,
    DateTime? dateOfBirth,
    bool clearDateOfBirth = false,
  });

  Future<User> changePhone({required String phone, required String code});

  Future<void> deleteAccount();

  /// Binds a push token to this device; server invalidates stale tokens.
  Future<void> registerDevice({required String pushToken});

  /// POST /auth/logout — blacklists the JWT server-side, then clears local.
  Future<void> logout();

  Future<List<EmergencyContact>> emergencyContacts();
  Future<EmergencyContact> addEmergencyContact({
    required String name,
    required String phone,
    String? relation,
  });
  Future<void> removeEmergencyContact(String id);
}

final class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository(this._api, this._tokens);

  final ApiClient _api;
  final TokenStorage _tokens;

  Map<String, Object?> _data(Response<Object?> r) {
    final body = r.data as Map<String, Object?>;
    return (body['data'] ?? body) as Map<String, Object?>;
  }

  @override
  Future<OtpChallenge> requestOtp(String phone) => guardApi(() async {
    final r = await _api.dio.post<Object?>(
      '/auth/otp/request',
      data: {'phone': phone},
      options: Options().skipAuth(),
    );
    return OtpChallenge.fromJson(phone, _data(r));
  });

  @override
  Future<User> verifyOtp({required String phone, required String code}) =>
      guardApi(() async {
        final r = await _api.dio.post<Object?>(
          '/auth/otp/verify',
          data: {'phone': phone, 'code': code},
          options: Options().skipAuth(),
        );
        final d = _data(r);
        await _tokens.write(
          AuthTokens.fromJson(d['tokens'] as Map<String, Object?>),
        );
        return User.fromJson(d['user'] as Map<String, Object?>);
      });

  @override
  Future<User?> currentUser() async {
    if (await _tokens.read() == null) return null;
    return guardApi(() async {
      final r = await _api.dio.get<Object?>('/me');
      return User.fromJson(_data(r));
    });
  }

  @override
  Future<User> updateProfile({
    String? name,
    String? email,
    String? locale,
    String? photoUrl,
    bool clearPhoto = false,
    String? username,
    Gender? gender,
    DateTime? dateOfBirth,
    bool clearDateOfBirth = false,
  }) =>
      guardApi(() async {
        final r = await _api.dio.patch<Object?>(
          '/me',
          data: {
            'name': ?name,
            'email': ?email,
            'locale': ?locale,
            if (clearPhoto)
              'photo_url': null
            else
              'photo_url': ?photoUrl,
            'username': ?username,
            'gender': ?gender?.wire,
            'date_of_birth': ?dateOfBirth?.toUtc().toIso8601String(),
          },
        );
        return User.fromJson(_data(r));
      });

  @override
  Future<User> changePhone({required String phone, required String code}) =>
      guardApi(() async {
        final r = await _api.dio.post<Object?>(
          '/me/phone',
          data: {'phone': phone, 'code': code},
        );
        return User.fromJson(_data(r));
      });

  @override
  Future<void> deleteAccount() async {
    try {
      await guardApi(() => _api.dio.delete<Object?>('/me'));
    } on Object {
      // still clear locally
    } finally {
      await _tokens.clear();
    }
  }

  @override
  Future<void> registerDevice({required String pushToken}) => guardApi(
    () =>
        _api.dio.post<Object?>('/me/devices', data: {'push_token': pushToken}),
  );

  @override
  Future<void> logout() async {
    try {
      await guardApi(() => _api.dio.post<Object?>('/auth/logout'));
    } on Object {
      // Best-effort: local session is cleared regardless so the user is
      // never stuck logged in because the network was down.
    } finally {
      await _tokens.clear();
    }
  }

  @override
  Future<List<EmergencyContact>> emergencyContacts() => guardApi(() async {
    final r = await _api.dio.get<Object?>('/me/emergency-contacts');
    final body = r.data as Map<String, Object?>;
    return (body['data'] as List)
        .map((e) => EmergencyContact.fromJson(e as Map<String, Object?>))
        .toList();
  });

  @override
  Future<EmergencyContact> addEmergencyContact({
    required String name,
    required String phone,
    String? relation,
  }) => guardApi(() async {
    final r = await _api.dio.post<Object?>(
      '/me/emergency-contacts',
      data: {'name': name, 'phone': phone, 'relation': relation},
    );
    return EmergencyContact.fromJson(_data(r));
  });

  @override
  Future<void> removeEmergencyContact(String id) =>
      guardApi(() => _api.dio.delete<Object?>('/me/emergency-contacts/$id'));
}
