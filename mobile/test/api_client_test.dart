import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:pesa/core/network/api_client.dart';
import 'package:pesa/core/network/api_exception.dart';
import 'package:pesa/core/storage/secure_store.dart';

class MemoryStorage implements FlutterSecureStorage {
  final Map<String, String> data = {};
  @override
  Future<String?> read({required String key, AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async => data[key];
  @override
  Future<void> write({required String key, required String? value, AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async => value == null ? data.remove(key) : data[key] = value;
  @override
  Future<void> delete({required String key, AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async => data.remove(key);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MemoryStorage storage;
  late SecureStore store;
  late Dio dio;
  late DioAdapter adapter;
  late ApiClient api;

  setUp(() {
    storage = MemoryStorage();
    store = SecureStore(storage);
    dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
    adapter = DioAdapter(dio: dio);
    api = ApiClient(store, dio: dio);
  });

  test('attaches bearer token and device headers', () async {
    await store.saveTokens('access-1', 'refresh-1');
    adapter.onGet('/v1/me', (s) => s.reply(200, {'ok': true}), headers: {'Authorization': 'Bearer access-1'});
    final res = await api.get('/v1/me');
    expect(res['ok'], true);
  });

  test('maps API error envelopes to ApiException with field errors', () async {
    adapter.onPost('/v1/auth/register', (s) => s.reply(422, {
          'error': {'code': 'VALIDATION_ERROR', 'message': 'Request validation failed', 'details': [{'path': 'phone', 'message': 'Invalid phone number'}]},
        }), data: Matchers.any);
    try {
      await api.post('/v1/auth/register', body: {'phone': 'x'}, auth: false);
      fail('expected exception');
    } on ApiException catch (e) {
      expect(e.status, 422);
      expect(e.code, 'VALIDATION_ERROR');
      expect(e.message, 'Invalid phone number');
      expect(e.fieldErrors['phone'], 'Invalid phone number');
    }
  });

  test('sends Idempotency-Key on payment requests', () async {
    adapter.onPost('/v1/payments', (s) => s.reply(202, {'transaction': {}}), data: Matchers.any, headers: {'Idempotency-Key': 'key-123'});
    final r = await api.post('/v1/payments', body: {'type': 'AIRTIME'}, idempotencyKey: 'key-123');
    expect(r, isNotNull);
  });

  test('clears the session and notifies on revoked sessions', () async {
    await store.saveTokens('access-1', 'refresh-1');
    var expired = false;
    api.onSessionExpired = () => expired = true;
    adapter.onGet('/v1/me', (s) => s.reply(401, {'error': {'code': 'SESSION_REVOKED', 'message': 'Session has been revoked'}}));
    await expectLater(api.get('/v1/me'), throwsA(isA<ApiException>()));
    expect(expired, true);
    expect(await store.accessToken, isNull);
  });

  test('device id is stable across calls', () async {
    final a = await store.deviceId();
    final b = await store.deviceId();
    expect(a, b);
    expect(a.length, greaterThan(20));
  });
}
