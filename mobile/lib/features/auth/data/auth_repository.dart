import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import '../../../core/config/env.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_store.dart';
import 'auth_models.dart';

sealed class LoginResult {}
class LoggedIn extends LoginResult { LoggedIn(this.user); final AppUser user; }
class NeedsOtp extends LoginResult { NeedsOtp(this.pending); final PendingOtp pending; }

class AuthRepository {
  AuthRepository(this._api, this._store);
  final ApiClient _api;
  final SecureStore _store;

  Future<Map<String, dynamic>> deviceInfo() async {
    final id = await _store.deviceId();
    var name = 'Phone';
    var model = 'unknown';
    var os = '';
    var platform = 'unknown';
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final a = await info.androidInfo;
        name = '${a.manufacturer} ${a.model}';
        model = a.model;
        os = 'Android ${a.version.release}';
        platform = 'android';
      } else if (Platform.isIOS) {
        final i = await info.iosInfo;
        name = i.name;
        model = i.utsname.machine;
        os = 'iOS ${i.systemVersion}';
        platform = 'ios';
      }
    } catch (_) {/* tests / unsupported platforms */}
    return {'deviceId': id, 'name': name, 'platform': platform, 'model': model, 'osVersion': os, 'appVersion': Env.appVersion};
  }

  Future<LoginResult> _handleSession(Json res, String phone) async {
    if (res['tokens'] != null) {
      final t = AuthTokens.fromJson(res['tokens'] as Json);
      await _store.saveTokens(t.accessToken, t.refreshToken);
      await _store.setLastPhone(phone);
      return LoggedIn(AppUser.fromJson(res['user'] as Json));
    }
    final next = res['next'];
    return NeedsOtp(PendingOtp(
      phone: '${res['phone'] ?? phone}',
      purpose: next == 'VERIFY_DEVICE' ? OtpPurpose.deviceVerify : OtpPurpose.phoneVerify,
      challengeId: res['challengeId'] as String?,
    ));
  }

  Future<PendingOtp> register({required String phone, required String password, required String firstName, required String lastName, String? email, String? referralCode, required bool marketingConsent, required String locale}) async {
    final res = await _api.post('/v1/auth/register', auth: false, body: {
      'phone': phone, 'password': password, 'firstName': firstName, 'lastName': lastName,
      if (email != null && email.isNotEmpty) 'email': email,
      if (referralCode != null && referralCode.isNotEmpty) 'referralCode': referralCode,
      'acceptTerms': true, 'marketingConsent': marketingConsent, 'locale': locale,
    });
    return PendingOtp(phone: '${res!['phone']}', purpose: OtpPurpose.phoneVerify, expiresAt: DateTime.tryParse('${res['otpExpiresAt']}'));
  }

  Future<LoginResult> login(String phone, String password) async {
    final res = await _api.post('/v1/auth/login', auth: false, body: {'phone': phone, 'password': password, 'device': await deviceInfo()});
    return _handleSession(res!, phone);
  }

  Future<LoginResult> verifyOtp(PendingOtp p, String code) async {
    final res = p.purpose == OtpPurpose.deviceVerify
        ? await _api.post('/v1/auth/verify-device', auth: false, body: {'challengeId': p.challengeId, 'code': code})
        : await _api.post('/v1/auth/verify-phone', auth: false, body: {'phone': p.phone, 'code': code, 'device': await deviceInfo()});
    return _handleSession(res!, p.phone);
  }

  Future<void> resendOtp(PendingOtp p) => _api.post('/v1/auth/resend-otp', auth: false, body: {'phone': p.phone, 'purpose': p.purpose == OtpPurpose.deviceVerify ? 'DEVICE_VERIFY' : 'PHONE_VERIFY'});
  Future<void> forgotPassword(String phone) => _api.post('/v1/auth/password/forgot', auth: false, body: {'phone': phone});
  Future<void> resetPassword(String phone, String code, String newPassword) => _api.post('/v1/auth/password/reset', auth: false, body: {'phone': phone, 'code': code, 'newPassword': newPassword});
  Future<void> startRecovery(String email) => _api.post('/v1/auth/recovery/start', auth: false, body: {'email': email});
  Future<String> completeRecovery(String email, String code, String newPhone, String? details) async =>
      '${(await _api.post('/v1/auth/recovery/complete', auth: false, body: {'email': email, 'code': code, 'newPhone': newPhone, 'details': ?details}))!['ticketReference']}';

  Future<(AppUser, Profile?)> me() async {
    final res = await _api.get('/v1/me');
    return (AppUser.fromJson(res['user'] as Json), res['profile'] == null ? null : Profile.fromJson(res['profile'] as Json));
  }

  Future<void> createPin(String pin) => _api.post('/v1/auth/pin', body: {'pin': pin});
  Future<void> verifyPin(String pin) => _api.post('/v1/auth/pin/verify', body: {'pin': pin});
  Future<void> changePin(String current, String next) => _api.post('/v1/auth/pin/change', body: {'currentPin': current, 'newPin': next});
  Future<void> requestPinReset() => _api.post('/v1/auth/pin/reset/request');
  Future<void> resetPin(String code, String password, String newPin) => _api.post('/v1/auth/pin/reset', body: {'code': code, 'password': password, 'newPin': newPin});
  Future<void> changePassword(String current, String next) => _api.post('/v1/auth/password/change', body: {'currentPassword': current, 'newPassword': next});
  Future<void> requestEmailCode(String email) => _api.post('/v1/auth/email/request', body: {'email': email});
  Future<void> verifyEmail(String code) => _api.post('/v1/auth/email/verify', body: {'code': code});

  Future<void> logout({bool everywhere = false}) async {
    try {
      await _api.post(everywhere ? '/v1/auth/logout-all' : '/v1/auth/logout');
    } catch (_) {/* best effort: local session is cleared regardless */}
    await _store.clearSession();
  }
}
