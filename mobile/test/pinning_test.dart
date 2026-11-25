import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pinned root bundle contains exactly the Amazon Trust Services roots and parses', () {
    final pem = File('assets/certs/trusted_roots.pem').readAsBytesSync();
    final count = RegExp('BEGIN CERTIFICATE').allMatches(String.fromCharCodes(pem)).length;
    expect(count, 5);
    // Throws if any certificate is malformed.
    SecurityContext(withTrustedRoots: false).setTrustedCertificatesBytes(pem);
  });

  test('a client restricted to the pinned roots rejects certificates from other CAs', () async {
    final pem = File('assets/certs/trusted_roots.pem').readAsBytesSync();
    final ctx = SecurityContext(withTrustedRoots: false)..setTrustedCertificatesBytes(pem);
    // Local TLS server with a self-signed certificate (not chained to Amazon roots).
    final dir = Directory.systemTemp.createTempSync('pin');
    final r = await Process.run('openssl', ['req', '-x509', '-newkey', 'rsa:2048', '-nodes', '-days', '1', '-subj', '/CN=localhost', '-keyout', '${dir.path}/k.pem', '-out', '${dir.path}/c.pem']);
    if (r.exitCode != 0) return markTestSkipped('openssl unavailable');
    final serverCtx = SecurityContext()..useCertificateChain('${dir.path}/c.pem')..usePrivateKey('${dir.path}/k.pem');
    final server = await HttpServer.bindSecure('127.0.0.1', 0, serverCtx);
    server.listen((req) => req.response..write('ok')..close());
    final client = HttpClient(context: ctx)..badCertificateCallback = (_, _, _) => false;
    await expectLater(() async => (await client.getUrl(Uri.parse('https://localhost:${server.port}/'))).close(), throwsA(isA<HandshakeException>()));
    await server.close(force: true);
  });
}
