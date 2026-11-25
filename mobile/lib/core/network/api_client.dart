import 'dart:async';
import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import '../config/env.dart';
import '../storage/secure_store.dart';
import 'api_exception.dart';

typedef Json = Map<String, dynamic>;

/// HTTP client for the Pesa API.
///  - attaches the short-lived access token and device headers
///  - on TOKEN_EXPIRED performs ONE refresh (rotating refresh token) shared by
///    all concurrent requests, then retries
///  - if refresh fails the session is cleared and [onSessionExpired] fires
class ApiClient {
  ApiClient(this._store, {Dio? dio, String? baseUrl, this.locale = 'en-KE'})
      : dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl ?? Env.apiBaseUrl, connectTimeout: const Duration(seconds: 15), receiveTimeout: const Duration(seconds: 30))) {
    this.dio.interceptors.add(QueuedInterceptorsWrapper(onRequest: _onRequest, onError: _onError));
  }

  final SecureStore _store;
  final Dio dio;
  String locale;
  void Function()? onSessionExpired;
  Future<bool>? _refreshing;

  Future<void> _onRequest(RequestOptions o, RequestInterceptorHandler h) async {
    o.headers['X-Device-Id'] = await _store.deviceId();
    o.headers['X-App-Version'] = Env.appVersion;
    o.headers['X-Platform'] = _platform;
    o.headers['Accept-Language'] = locale;
    if (o.extra['auth'] != false) {
      final token = await _store.accessToken;
      if (token != null) o.headers['Authorization'] = 'Bearer $token';
    }
    h.next(o);
  }

  Future<void> _onError(DioException e, ErrorInterceptorHandler h) async {
    final body = e.response?.data;
    final err = body is Map ? body['error'] : null;
    final code = err is Map ? err['code'] : null;
    final retried = e.requestOptions.extra['retried'] == true;
    if (e.response?.statusCode == 401 && code == 'TOKEN_EXPIRED' && !retried) {
      final ok = await refreshSession();
      if (ok) {
        final o = e.requestOptions..extra['retried'] = true;
        o.headers['Authorization'] = 'Bearer ${await _store.accessToken}';
        try {
          return h.resolve(await dio.fetch<dynamic>(o));
        } on DioException catch (err) {
          return h.next(err);
        }
      }
    }
    if (e.response?.statusCode == 401 && e.requestOptions.extra['auth'] != false && code != 'INVALID_CREDENTIALS') {
      await _store.clearSession();
      onSessionExpired?.call();
    }
    h.next(e);
  }

  /// Single-flight refresh: concurrent 401s share one rotation request so the
  /// server never sees the same refresh token twice (which it treats as theft).
  Future<bool> refreshSession() {
    return _refreshing ??= () async {
      try {
        final rt = await _store.refreshToken;
        if (rt == null) return false;
        final res = await Dio(BaseOptions(baseUrl: dio.options.baseUrl)).post<Json>('/v1/auth/refresh', data: {'refreshToken': rt, 'deviceId': await _store.deviceId()});
        await _store.saveTokens(res.data!['accessToken'] as String, res.data!['refreshToken'] as String);
        return true;
      } catch (_) {
        return false;
      }
    }().whenComplete(() => _refreshing = null);
  }

  static String get _platform {
    try {
      return Platform.isIOS ? 'ios' : Platform.isAndroid ? 'android' : 'unknown';
    } catch (_) {
      return 'unknown';
    }
  }

  Future<T> _wrap<T>(Future<Response<dynamic>> Function() call) async {
    try {
      final res = await call();
      return res.data as T;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Json> get(String path, {Map<String, dynamic>? query}) =>
      _wrap<Json>(() => dio.get<dynamic>(path, queryParameters: query?..removeWhere((_, v) => v == null || v == '')));
  Future<Json?> post(String path, {Object? body, bool auth = true, String? idempotencyKey}) => _wrap<Json?>(() => dio.post<dynamic>(path,
      data: body, options: Options(extra: {'auth': auth}, headers: idempotencyKey != null ? {'Idempotency-Key': idempotencyKey} : null)));
  Future<Json> patch(String path, {Object? body}) => _wrap<Json>(() => dio.patch<dynamic>(path, data: body));
  Future<Json> put(String path, {Object? body}) => _wrap<Json>(() => dio.put<dynamic>(path, data: body));
  Future<void> delete(String path) => _wrap<dynamic>(() => dio.delete<dynamic>(path));

  /// Downloads a binary (e.g. a PDF statement) to [savePath].
  Future<void> download(String path, String savePath, {Map<String, dynamic>? query}) async {
    try {
      await dio.download(path, savePath, queryParameters: query);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
