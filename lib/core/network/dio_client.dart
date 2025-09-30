import 'package:app_management/core/config/app_config.dart';
import 'package:app_management/core/network/interceptors/auth_interceptor.dart';
import 'package:app_management/core/network/interceptors/retry_interceptor.dart';
import 'package:app_management/core/utils/logger.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class DioClient {
  DioClient({
    required AppConfig config,
    required AppLogger logger,
    AuthInterceptor? authInterceptor,
    RetryInterceptor? retryInterceptor,
  })  : _config = config,
        _authInterceptor = authInterceptor,
        _retryInterceptor = retryInterceptor,
        _logger = logger;

  final AppConfig _config;
  final AuthInterceptor? _authInterceptor;
  final RetryInterceptor? _retryInterceptor;
  final AppLogger _logger;

  Dio create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _config.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 10),
      ),
    );
    final interceptors = <Interceptor>[
      if (_authInterceptor != null) _authInterceptor!..attach(dio),
      if (_retryInterceptor != null) _retryInterceptor!..attach(dio),
      if (_config.enableLogging && kDebugMode) LogInterceptor(requestBody: true, responseBody: true),
    ];
    dio.interceptors.addAll(interceptors);
    dio.options.extra['dio_client'] = true;
    _logger.debug('Dio client configured for ${_config.apiBaseUrl}.');
    return dio;
  }
}
