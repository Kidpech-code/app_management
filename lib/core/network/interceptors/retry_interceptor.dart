import 'dart:async';
import 'dart:math';

import 'package:app_management/core/utils/connectivity.dart';
import 'package:app_management/core/utils/logger.dart';
import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required ConnectivityService connectivity,
    required AppLogger logger,
    this.maxRetries = 3,
    this.baseDelay = const Duration(milliseconds: 350),
  })  : _connectivity = connectivity,
        _logger = logger;

  final ConnectivityService _connectivity;
  final AppLogger _logger;
  final int maxRetries;
  final Duration baseDelay;
  Dio? _dio;

  // ignore: use_setters_to_change_properties
  void attach(Dio dio) => _dio = dio;

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (!_shouldRetry(err)) {
      handler.next(err);
      return;
    }

    for (var attempt = 1; attempt <= maxRetries; attempt++) {
      final hasConnection = await _connectivity.hasConnection;
      if (!hasConnection) {
        await Future<void>.delayed(const Duration(seconds: 1));
        continue;
      }
      final delay = _delayForAttempt(attempt);
      _logger.debug('Retrying request ${err.requestOptions.uri} in ${delay.inMilliseconds}ms (attempt $attempt/$maxRetries)');
      await Future<void>.delayed(delay);
      try {
        final response = await _dio!.fetch<dynamic>(err.requestOptions);
        handler.resolve(response);
        return;
      } on DioException catch (e) {
        if (attempt == maxRetries) {
          handler.next(e);
          return;
        }
      }
    }
  }

  bool _shouldRetry(DioException err) {
    if (_dio == null) {
      return false;
    }
    if (err.requestOptions.extra['__retried'] == true) {
      return false;
    }
    if (err.type == DioExceptionType.cancel || err.type == DioExceptionType.badCertificate) {
      return false;
    }
    if (err.response != null && err.response!.statusCode != null) {
      final statusCode = err.response!.statusCode!;
      if (statusCode < 500 || statusCode == 501) {
        return false;
      }
    }
    return true;
  }

  Duration _delayForAttempt(int attempt) {
    final jitter = Random().nextInt(200);
    final multiplier = 1 << (attempt - 1);
    return Duration(milliseconds: baseDelay.inMilliseconds * multiplier + jitter);
  }
}
