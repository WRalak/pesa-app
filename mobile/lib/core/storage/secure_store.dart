import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Credentials live only in the platform keystore (Android Keystore /
/// iOS Keychain). Nothing sensitive is written to shared preferences or logs.
class SecureStore {
  SecureStore([FlutterSecureStorage? storage])
      : _s = storage ?? const FlutterSecureStorage(iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device));
  final FlutterSecureStorage _s;

  static const _access = 'auth.access';
  static const _refresh = 'auth.refresh';
  static const _device = 'device.id';
  static const _biometric = 'security.biometric';
  static const _onboarded = 'app.onboarded';
  static const _lastPhone = 'auth.lastPhone';
  static const _themeMode = 'app.themeMode';
  static const _locale = 'app.locale';

  Future<String?> get accessToken => _s.read(key: _access);
  Future<String?> get refreshToken => _s.read(key: _refresh);
  Future<void> saveTokens(String access, String refresh) async {
    await _s.write(key: _access, value: access);
    await _s.write(key: _refresh, value: refresh);
  }

  Future<void> clearSession() async {
    await _s.delete(key: _access);
    await _s.delete(key: _refresh);
  }

  /// Stable per-install identifier used for device binding (not a hardware ID).
  Future<String> deviceId() async {
    final existing = await _s.read(key: _device);
    if (existing != null) return existing;
    final id = const Uuid().v4();
    await _s.write(key: _device, value: id);
    return id;
  }

  Future<bool> get biometricEnabled async => (await _s.read(key: _biometric)) == 'true';
  Future<void> setBiometricEnabled(bool v) => _s.write(key: _biometric, value: v.toString());
  Future<bool> get onboarded async => (await _s.read(key: _onboarded)) == 'true';
  Future<void> setOnboarded() => _s.write(key: _onboarded, value: 'true');
  Future<String?> get lastPhone => _s.read(key: _lastPhone);
  Future<void> setLastPhone(String p) => _s.write(key: _lastPhone, value: p);
  Future<String?> get themeMode => _s.read(key: _themeMode);
  Future<void> setThemeMode(String m) => _s.write(key: _themeMode, value: m);
  Future<String?> get locale => _s.read(key: _locale);
  Future<void> setLocale(String l) => _s.write(key: _locale, value: l);
}
