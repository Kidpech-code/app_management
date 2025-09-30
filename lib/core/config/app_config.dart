import 'package:flutter/foundation.dart';

enum BuildFlavor { dev, stg, prod }

enum LogLevel { none, error, warning, info, debug }

class AppConfig {
  AppConfig({
    required this.apiBaseUrl,
    required this.sentryDsn,
    required this.buildFlavor,
    required this.logLevel,
  });

  factory AppConfig.fromEnvironment() {
    const flavorString = String.fromEnvironment('BUILD_FLAVOR', defaultValue: 'dev');
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://dev.api.example.com');
    const sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: 'https://public@sentry.invalid/1');
    const logLevelString = String.fromEnvironment('LOG_LEVEL', defaultValue: kDebugMode ? 'debug' : 'warning');

    return AppConfig(
      apiBaseUrl: apiBaseUrl,
      sentryDsn: sentryDsn,
      buildFlavor: BuildFlavor.values.firstWhere(
        (flavor) => flavor.name == flavorString,
        orElse: () => BuildFlavor.dev,
      ),
      logLevel: LogLevel.values.firstWhere(
        (level) => level.name == logLevelString,
        orElse: () => kDebugMode ? LogLevel.debug : LogLevel.warning,
      ),
    );
  }

  final String apiBaseUrl;
  final String sentryDsn;
  final BuildFlavor buildFlavor;
  final LogLevel logLevel;

  bool get enableLogging => logLevel == LogLevel.debug || (logLevel == LogLevel.info && kDebugMode);
}
