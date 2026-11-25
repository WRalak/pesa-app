import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/auth_controller.dart';
import '../providers.dart';

/// Firebase Cloud Messaging. Firebase config files (google-services.json /
/// GoogleService-Info.plist) are environment-specific and not committed; if
/// they are absent the app runs normally with in-app notifications only.
class PushService {
  PushService(this._ref);
  final Ref _ref;
  bool _ready = false;
  void Function(String route)? onOpenRoute;

  Future<void> init() async {
    try {
      await Firebase.initializeApp();
      _ready = true;
    } catch (e) {
      debugPrint('Push disabled: Firebase not configured for this build.');
      return;
    }
    FirebaseMessaging.onMessageOpenedApp.listen(_open);
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _open(initial);
    // The backend sends via FCM HTTP v1 registration tokens. firebase_messaging
    // 17 introduces register()/onRegistered (installation IDs); migrate both
    // sides together once the server sender supports that target type.
    // ignore: deprecated_member_use
    FirebaseMessaging.instance.onTokenRefresh.listen(_register);
  }

  void _open(RemoteMessage m) {
    final route = m.data['route'];
    if (route is String && route.startsWith('/')) onOpenRoute?.call(route);
  }

  /// Requests permission and registers this device's token after sign-in.
  Future<void> registerDevice() async {
    if (!_ready) return;
    final settings = await FirebaseMessaging.instance.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;
    // ignore: deprecated_member_use
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _register(token);
  }

  Future<void> _register(String token) async {
    try {
      await _ref.read(apiClientProvider).patch('/v1/me/devices/current', body: {'pushToken': token});
    } catch (_) {/* retried on next launch */}
  }
}

final pushServiceProvider = Provider<PushService>((ref) {
  final svc = PushService(ref);
  ref.listen(authControllerProvider, (prev, next) {
    if (next is Authenticated && prev is! Authenticated) svc.registerDevice();
  });
  return svc;
});
