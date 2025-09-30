import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../utils/logger.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/retry_interceptor.dart';

class DioClient {
  DioClient({
    required AppConfig config,
    required AuthInterceptor authInterceptor,
    required RetryInterceptor retryInterceptor,
    required AppLogger logger,
  })  : _config = config,
        _authInterceptor = authInterceptor,
        _retryInterceptor = retryInterceptor,
        _logger = logger;

  final AppConfig _config;
  final AuthInterceptor _authInterceptor;
  final RetryInterceptor _retryInterceptor;
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
    dio.interceptors.addAll([
      _authInterceptor..attach(dio),
      _retryInterceptor..attach(dio),
      if (_config.enableLogging && kDebugMode) LogInterceptor(requestBody: true, responseBody: true),
    ]);
    dio.options.extra['dio_client'] = true;
    _logger.debug('Dio client configured for ${_config.apiBaseUrl}.');
    return dio;
  }
}
