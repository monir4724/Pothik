import 'dart:convert';

import '../../features/auth/domain/user.dart';
import '../../features/places/domain/saved_place.dart';
import '../../features/profile/domain/account_settings.dart';
import '../../features/rides/domain/ride_models.dart';
import '../storage/app_preferences.dart';
import '../storage/token_storage.dart';

/// Snapshot of one passenger's fake-backend data, keyed by phone.
final class FakeAccount {
  const FakeAccount({
    required this.user,
    required this.contacts,
    required this.savedPlaces,
    required this.history,
    this.settings = const AccountSettings(),
  });

  factory FakeAccount.fromJson(Map<String, Object?> j) => FakeAccount(
    user: User.fromJson(_obj(j['user'])),
    contacts: _list(j['contacts'])
        .map((e) => EmergencyContact.fromJson(_obj(e)))
        .toList(),
    savedPlaces: _list(j['saved_places'])
        .map((e) => SavedPlace.fromJson(_obj(e)))
        .toList(),
    history: _list(j['history'])
        .map((e) => RideSummary.fromJson(_obj(e)))
        .toList(),
    settings: j['settings'] == null
        ? AccountSettings.seed(
            (j['user'] as Map?)?['phone'] as String? ?? '',
          )
        : AccountSettings.fromJson(_obj(j['settings'])),
  );

  final User user;
  final List<EmergencyContact> contacts;
  final List<SavedPlace> savedPlaces;
  final List<RideSummary> history;
  final AccountSettings settings;

  Map<String, Object?> toJson() => {
    'user': user.toJson(),
    'contacts': contacts.map((c) => c.toJson()).toList(),
    'saved_places': savedPlaces.map((p) => p.toJson()).toList(),
    'history': history.map((h) => h.toJson()).toList(),
    'settings': settings.toJson(),
  };

  static Map<String, Object?> _obj(Object? v) =>
      Map<String, Object?>.from(v! as Map);

  static List<Object?> _list(Object? v) =>
      v == null ? const [] : List<Object?>.from(v as List);
}

abstract interface class FakeAccountStore {
  String? get lastPhone;
  Future<void> setLastPhone(String? phone);
  Future<FakeAccount?> load(String phone);
  Future<void> save(String phone, FakeAccount account);
  Future<void> delete(String phone);
}

final class PrefsFakeAccountStore implements FakeAccountStore {
  PrefsFakeAccountStore(this._prefs);

  final AppPreferences _prefs;

  @override
  String? get lastPhone => _prefs.fakeLastPhone;

  @override
  Future<void> setLastPhone(String? phone) => _prefs.setFakeLastPhone(phone);

  @override
  Future<FakeAccount?> load(String phone) async {
    final raw = _prefs.fakeAccountJson(phone);
    if (raw == null || raw.isEmpty) return null;
    try {
      return FakeAccount.fromJson(
        Map<String, Object?>.from(jsonDecode(raw) as Map),
      );
    } on Object {
      return null;
    }
  }

  @override
  Future<void> save(String phone, FakeAccount account) =>
      _prefs.setFakeAccountJson(phone, jsonEncode(account.toJson()));

  @override
  Future<void> delete(String phone) => _prefs.removeFakeAccount(phone);
}

/// In-memory store for unit tests.
final class MemoryFakeAccountStore implements FakeAccountStore {
  final Map<String, FakeAccount> accounts = {};

  @override
  String? lastPhone;

  @override
  Future<FakeAccount?> load(String phone) async => accounts[phone];

  @override
  Future<void> save(String phone, FakeAccount account) async {
    accounts[phone] = account;
  }

  @override
  Future<void> delete(String phone) async {
    accounts.remove(phone);
  }

  @override
  Future<void> setLastPhone(String? phone) async => lastPhone = phone;
}

/// SharedPreferences-backed tokens so the fake backend survives a page
/// refresh the same way a real session would.
final class FakePrefsTokenStorage implements TokenStorage {
  FakePrefsTokenStorage(this._prefs);

  final AppPreferences _prefs;
  AuthTokens? _cache;

  @override
  Future<AuthTokens?> read() async {
    if (_cache != null) return _cache;
    final raw = _prefs.fakeTokensJson;
    if (raw == null) return null;
    try {
      _cache = AuthTokens.fromJson(
        Map<String, Object?>.from(jsonDecode(raw) as Map),
      );
      return _cache;
    } on Object {
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(AuthTokens tokens) async {
    _cache = tokens;
    await _prefs.setFakeTokensJson(jsonEncode(tokens.toJson()));
  }

  @override
  Future<void> clear() async {
    _cache = null;
    await _prefs.setFakeTokensJson(null);
  }
}
