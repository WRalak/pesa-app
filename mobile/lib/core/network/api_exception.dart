import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException({required this.status, required this.code, required this.message, this.details});
  final int status;
  final String code;
  final String message;
  final Object? details;

  bool get isNetwork => status == 0;
  bool get isUnauthorized => status == 401;

  /// Field errors from VALIDATION_ERROR responses, keyed by path.
  Map<String, String> get fieldErrors {
    final d = details;
    if (d is! List) return const {};
    return {for (final e in d.whereType<Map<String, dynamic>>()) '${e['path']}': '${e['message']}'};
  }

  factory ApiException.fromDio(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['error'] is Map<String, dynamic>) {
      final err = data['error'] as Map<String, dynamic>;
      final fields = err['details'];
      var message = '${err['message'] ?? 'Request failed'}';
      if (err['code'] == 'VALIDATION_ERROR' && fields is List && fields.isNotEmpty && fields.first is Map) {
        message = '${(fields.first as Map)['message']}';
      }
      return ApiException(status: e.response?.statusCode ?? 0, code: '${err['code'] ?? 'ERROR'}', message: message, details: fields);
    }
    if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
      return ApiException(status: 0, code: 'NETWORK', message: 'No connection. Check your internet and try again.');
    }
    return ApiException(status: e.response?.statusCode ?? 0, code: 'ERROR', message: 'Something went wrong. Please try again.');
  }

  @override
  String toString() => message;
}
