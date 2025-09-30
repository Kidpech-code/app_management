// ignore_for_file: use_setters_to_change_properties

import 'dart:async';

import 'package:app_management/core/utils/logger.dart';
import 'package:dio/dio.dart';

const skipAuthKey = 'skip_auth';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Future<String?> Function() readAccessToken,
    required Future<String?> Function() refreshAccessToken,
    required Future<void> Function() onUnauthorized,
    required AppLogger logger,
  })  : _readAccessToken = readAccessToken,
        _refreshAccessToken = refreshAccessToken,
        _onUnauthorized = onUnauthorized,
        _logger = logger;

  final Future<String?> Function() _readAccessToken;
  final Future<String?> Function() _refreshAccessToken;
  final Future<void> Function() _onUnauthorized;
  final AppLogger _logger;

  Dio? _dio;
  Completer<void>? _refreshCompleter;

  void attach(Dio dio) {
    _dio = dio;
  }

  bool _shouldSkip(RequestOptions options) => options.extra[skipAuthKey] == true;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (_shouldSkip(options)) {
      handler.next(options);
      return;
    }
    final token = await _readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    if (_dio == null || _shouldSkip(err.requestOptions) || response?.statusCode != 401) {
      handler.next(err);
      return;
    }
    if (err.requestOptions.extra['__retried'] == true) {
      handler.next(err);
      return;
    }
    await _refreshToken();
    final accessToken = await _readAccessToken();
    if (accessToken == null) {
      await _onUnauthorized();
      handler.next(err);
      return;
    }
    final updatedHeaders = Map<String, dynamic>.from(err.requestOptions.headers);
    updatedHeaders['Authorization'] = 'Bearer $accessToken';
    final retriedOptions = err.requestOptions.copyWith(
      headers: updatedHeaders,
      extra: {
        ...err.requestOptions.extra,
        '__retried': true,
      },
    );
    try {
      final result = await _dio!.fetch<dynamic>(retriedOptions);
      handler.resolve(result);
    } on DioException catch (dioError) {
      handler.next(dioError);
    }
  }

  Future<void> _refreshToken() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }
    _refreshCompleter = Completer<void>();
    try {
      final newToken = await _refreshAccessToken();
      if (newToken == null) {
        await _onUnauthorized();
      }
      _refreshCompleter!.complete();
    } catch (error, stackTrace) {
      _logger.error('Refresh token failed', error: error, stackTrace: stackTrace);
      await _onUnauthorized();
      _refreshCompleter!.completeError(error, stackTrace);
    } finally {
      _refreshCompleter = null;
    }
  }
}
