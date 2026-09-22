import 'package:shared_preferences/shared_preferences.dart';

/// Non-sensitive preferences only. Anything security-relevant goes to
/// [SecureTokenStorage].
final class AppPreferences {
  AppPreferences(this._prefs);

  static Future<AppPreferences> load() async =>
      AppPreferences(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  static const _kLocale = 'locale';
  static const _kOnboardingDone = 'onboarding_done';
  static const _kLocationRationaleShown = 'location_rationale_shown';
  static const _kLastActiveRideId = 'last_active_ride_id';
  static const _kDeviceId = 'device_id';
  static const _kFakeTokens = 'fake.tokens.v1';
  static const _kFakeLastPhone = 'fake.last_phone.v1';
  static const _kFakeAccountPrefix = 'fake.account.v1.';

  String? get localeCode => _prefs.getString(_kLocale);
  Future<void> setLocaleCode(String code) => _prefs.setString(_kLocale, code);

  bool get onboardingDone => _prefs.getBool(_kOnboardingDone) ?? false;
  Future<void> setOnboardingDone() => _prefs.setBool(_kOnboardingDone, true);

  bool get locationRationaleShown =>
      _prefs.getBool(_kLocationRationaleShown) ?? false;
  Future<void> setLocationRationaleShown() =>
      _prefs.setBool(_kLocationRationaleShown, true);

  /// Used to resume into the correct trip screen after the app is killed
  /// mid-booking. The server is still the source of truth — this is a hint.
  String? get lastActiveRideId => _prefs.getString(_kLastActiveRideId);
  Future<void> setLastActiveRideId(String? id) => id == null
      ? _prefs.remove(_kLastActiveRideId)
      : _prefs.setString(_kLastActiveRideId, id);

  String? get deviceId => _prefs.getString(_kDeviceId);
  Future<void> setDeviceId(String id) => _prefs.setString(_kDeviceId, id);

  /// Dev-only session for `USE_FAKE_BACKEND`. Real tokens stay in
  /// [SecureTokenStorage]; this is just so a Chrome refresh doesn't wipe
  /// the in-memory fake world.
  String? get fakeTokensJson => _prefs.getString(_kFakeTokens);
  Future<void> setFakeTokensJson(String? json) => json == null
      ? _prefs.remove(_kFakeTokens)
      : _prefs.setString(_kFakeTokens, json);

  String? get fakeLastPhone => _prefs.getString(_kFakeLastPhone);
  Future<void> setFakeLastPhone(String? phone) => phone == null
      ? _prefs.remove(_kFakeLastPhone)
      : _prefs.setString(_kFakeLastPhone, phone);

  String? fakeAccountJson(String phone) =>
      _prefs.getString('$_kFakeAccountPrefix$phone');
  Future<void> setFakeAccountJson(String phone, String json) =>
      _prefs.setString('$_kFakeAccountPrefix$phone', json);

  Future<void> removeFakeAccount(String phone) =>
      _prefs.remove('$_kFakeAccountPrefix$phone');

  Future<void> clearUserScoped() async {
    await _prefs.remove(_kLastActiveRideId);
  }
}
