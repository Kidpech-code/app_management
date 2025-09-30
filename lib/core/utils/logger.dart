import 'dart:developer' as developer;

import 'package:app_management/core/config/app_config.dart';
import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger({required AppConfig config}) : _enabled = config.enableLogging;

  final bool _enabled;

  void debug(String message) {
    if (_enabled && kDebugMode) {
      developer.log(message, name: 'DEBUG');
    }
  }

  void info(String message) {
    if (_enabled) {
      developer.log(message, name: 'INFO');
    }
  }

  void error(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(message, name: 'ERROR', error: error, stackTrace: stackTrace);
  }
}
