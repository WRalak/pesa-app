/// Build-time environment, provided with `--dart-define` (see docs/deployment).
///
///   flutter run --dart-define=ENV=dev --dart-define=API_BASE_URL=http://10.0.2.2:4000
///
/// Nothing secret is ever compiled into the app.
enum AppEnv { dev, staging, prod }

class Env {
  static const String _env = String.fromEnvironment('ENV', defaultValue: 'dev');
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:4000');
  static const String appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');

  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');

  static AppEnv get env => switch (_env) { 'prod' => AppEnv.prod, 'staging' => AppEnv.staging, _ => AppEnv.dev };
  static bool get isProd => env == AppEnv.prod;

  /// Fails fast on a misconfigured release build instead of silently talking
  /// to a development endpoint or over cleartext.
  static void assertValid() {
    if (env == AppEnv.dev) return;
    if (!apiBaseUrl.startsWith('https://')) {
      throw StateError('API_BASE_URL must be https:// for ${env.name} builds (got "$apiBaseUrl")');
    }
  }

  /// Sandbox banner is shown everywhere outside production so test data can
  /// never be mistaken for real balances.
  static bool get showSandboxBanner => !isProd;
}
