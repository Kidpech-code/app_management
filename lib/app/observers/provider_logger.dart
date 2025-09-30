import 'package:app_management/core/utils/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart' show ProviderObserverContext;

final class AppProviderObserver extends ProviderObserver {
  AppProviderObserver(this._logger);

  final AppLogger _logger;

  @override
  void didUpdateProvider(ProviderObserverContext context, Object? previousValue, Object? newValue) {
    final provider = context.provider;
    _logger.debug('Provider ${provider.name ?? provider.runtimeType} updated: $newValue');
  }
}
