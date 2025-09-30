import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/logger.dart';

class AppProviderObserver extends ProviderObserver {
  AppProviderObserver(this._logger);

  final AppLogger _logger;

  @override
  void didUpdateProvider(ProviderBase<Object?> provider, Object? previousValue, Object? newValue, ProviderContainer container) {
    _logger.debug('Provider ${provider.name ?? provider.runtimeType} updated: $newValue');
  }
}
