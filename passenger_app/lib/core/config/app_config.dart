/// Build-time configuration, injected via `--dart-define` /
/// `--dart-define-from-file=env/<env>.json`.
///
/// Nothing here is a secret that must stay private (the API base URL and the
/// Reverb public key ship inside the binary regardless) — but real values must
/// never be committed. See `env/dev.example.json`.
enum AppEnvironment { dev, staging, prod }

final class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.reverbHost,
    required this.reverbPort,
    required this.reverbAppKey,
    required this.reverbUseTls,
    required this.sentryDsn,
    required this.useFakeBackend,
    required this.guardianWebBaseUrl,
    required this.mapsApiKey,
  });

  factory AppConfig.fromEnvironment() {
    const envName = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
    final environment = AppEnvironment.values.firstWhere(
      (e) => e.name == envName,
      orElse: () => AppEnvironment.dev,
    );
    return AppConfig(
      environment: environment,
      apiBaseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://10.0.2.2:8000/api/v1',
      ),
      reverbHost: const String.fromEnvironment(
        'REVERB_HOST',
        defaultValue: '10.0.2.2',
      ),
      reverbPort: const int.fromEnvironment('REVERB_PORT', defaultValue: 8080),
      reverbAppKey: const String.fromEnvironment(
        'REVERB_APP_KEY',
        defaultValue: 'local-key',
      ),
      reverbUseTls: const bool.fromEnvironment('REVERB_TLS'),
      sentryDsn: const String.fromEnvironment('SENTRY_DSN'),
      // Fake backend lets the app run end-to-end without a Laravel instance.
      // Defaults ON in dev so `flutter run` works out of the box; must be OFF
      // for staging/prod builds — enforced in [validate].
      useFakeBackend: const bool.fromEnvironment(
        'USE_FAKE_BACKEND',
        defaultValue: true,
      ),
      guardianWebBaseUrl: const String.fromEnvironment(
        'GUARDIAN_WEB_BASE_URL',
        defaultValue: 'https://track.pothik.app',
      ),
      mapsApiKey: const String.fromEnvironment('MAPS_API_KEY'),
    );
  }

  final AppEnvironment environment;
  final String apiBaseUrl;
  final String reverbHost;
  final int reverbPort;
  final String reverbAppKey;
  final bool reverbUseTls;
  final String sentryDsn;
  final bool useFakeBackend;
  final String guardianWebBaseUrl;
  final String mapsApiKey;

  bool get isProd => environment == AppEnvironment.prod;
  bool get isDev => environment == AppEnvironment.dev;
  bool get crashReportingEnabled => sentryDsn.isNotEmpty;

  Uri get reverbUri => Uri(
    scheme: reverbUseTls ? 'wss' : 'ws',
    host: reverbHost,
    port: reverbPort,
    path: '/app/$reverbAppKey',
    queryParameters: const {
      'protocol': '7',
      'client': 'pothik-flutter',
      'version': '1.0',
    },
  );

  /// Fails fast on misconfiguration that would otherwise ship silently.
  void validate() {
    if (!isDev) {
      if (useFakeBackend) {
        throw StateError('USE_FAKE_BACKEND must be false outside dev.');
      }
      if (!apiBaseUrl.startsWith('https://')) {
        throw StateError('API_BASE_URL must use HTTPS outside dev.');
      }
      if (!reverbUseTls) {
        throw StateError('REVERB_TLS must be true outside dev.');
      }
      if (reverbAppKey == 'local-key') {
        throw StateError('REVERB_APP_KEY is still the placeholder value.');
      }
    }
  }
}
