import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../config/env.dart';

/// CA pinning for every dart:io connection (Dio and the Socket.IO WebSocket).
///
/// Release builds (staging/prod) trust ONLY the roots in
/// `assets/certs/trusted_roots.pem` — Amazon Trust Services Root CA 1–4 and
/// Starfield Services Root G2, the chain used by AWS Certificate Manager —
/// instead of every CA on the device. A rogue or user-installed CA (corporate
/// proxy, malware, compromised CA) can no longer intercept traffic. Pinning
/// roots rather than the leaf certificate means ACM's automatic renewals never
/// break the app.
///
/// If the API moves off ACM, update the bundle and ship an app release FIRST.
class PinnedHttpOverrides extends HttpOverrides {
  PinnedHttpOverrides(this._context);
  final SecurityContext _context;

  static const asset = 'assets/certs/trusted_roots.pem';

  static Future<void> install() async {
    if (Env.env == AppEnv.dev) return; // local http:// API
    final pem = await rootBundle.load(asset);
    final ctx = SecurityContext(withTrustedRoots: false)..setTrustedCertificatesBytes(pem.buffer.asUint8List());
    HttpOverrides.global = PinnedHttpOverrides(ctx);
    debugPrint('TLS: pinned to ${String.fromCharCodes(pem.buffer.asUint8List()).split('BEGIN CERTIFICATE').length - 1} root CAs');
  }

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(_context);
    // Never accept a certificate that failed validation against the pinned roots.
    client.badCertificateCallback = (_, _, _) => false;
    return client;
  }
}
