import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/user.dart';

sealed class AuthState {
  const AuthState();
}

/// Not yet restored from storage — router shows splash.
final class AuthUnknown extends AuthState {
  const AuthUnknown();
}

final class Unauthenticated extends AuthState {
  const Unauthenticated({this.sessionExpired = false});

  /// True when we got here because a refresh was rejected, so the login
  /// screen can explain why.
  final bool sessionExpired;
}

final class Authenticated extends AuthState {
  const Authenticated(this.user);

  final User user;
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

final class AuthController extends Notifier<AuthState> {
  static const _log = AppLogger('auth');

  @override
  AuthState build() => const AuthUnknown();

  User? get currentUser => switch (state) {
    Authenticated(:final user) => user,
    _ => null,
  };

  /// Called once at startup. Network failure keeps a cached-token user
  /// logged in optimistically; a definitive 401 logs them out.
  Future<void> restore() async {
    try {
      final user = await ref.read(authRepositoryProvider).currentUser();
      state = user == null ? const Unauthenticated() : Authenticated(user);
      _log.info('session restored', {'authenticated': user != null});
    } on Object catch (e, st) {
      _log.warn('restore failed; treating as unauthenticated', {'e': '$e'});
      // If tokens exist but /me failed for network reasons we still can't
      // render authenticated screens safely without a user object.
      state = const Unauthenticated();
      _log.error('restore', error: e, stackTrace: st);
    }
  }

  Future<OtpChallenge> requestOtp(String phone) {
    _log.info('otp requested', {'phone': phone});
    return ref.read(authRepositoryProvider).requestOtp(phone);
  }

  Future<User> verifyOtp({required String phone, required String code}) async {
    final user = await ref
        .read(authRepositoryProvider)
        .verifyOtp(phone: phone, code: code);
    state = Authenticated(user);
    _log.info('login success', {'user': user.id});
    return user;
  }

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
  }) async {
    final user = await ref
        .read(authRepositoryProvider)
        .updateProfile(
          name: name,
          email: email,
          locale: locale,
          photoUrl: photoUrl,
          clearPhoto: clearPhoto,
          username: username,
          gender: gender,
          dateOfBirth: dateOfBirth,
          clearDateOfBirth: clearDateOfBirth,
        );
    state = Authenticated(user);
    return user;
  }

  Future<User> changePhone({
    required String phone,
    required String code,
  }) async {
    final user = await ref
        .read(authRepositoryProvider)
        .changePhone(phone: phone, code: code);
    state = Authenticated(user);
    return user;
  }

  Future<void> deleteAccount() async {
    await ref.read(authRepositoryProvider).deleteAccount();
    await ref.read(appPreferencesProvider).clearUserScoped();
    state = const Unauthenticated();
  }

  Future<void> logout() async {
    _log.info('logout');
    await ref.read(authRepositoryProvider).logout();
    await ref.read(appPreferencesProvider).clearUserScoped();
    state = const Unauthenticated();
  }

  /// Invoked by the API client when refresh-token rotation is rejected.
  Future<void> onSessionExpired() async {
    if (state is Unauthenticated) return;
    _log.warn('session expired');
    await ref.read(appPreferencesProvider).clearUserScoped();
    state = const Unauthenticated(sessionExpired: true);
  }
}
