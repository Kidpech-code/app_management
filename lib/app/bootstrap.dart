import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:app_management/app/app.dart';
import 'package:app_management/app/di/providers.dart';
import 'package:app_management/app/observers/provider_logger.dart';
import 'package:app_management/core/config/app_config.dart';
import 'package:app_management/core/storage/hive_manager.dart';
import 'package:app_management/core/utils/logger.dart';
import 'package:app_management/features/example_todos/infrastructure/models/todo_dto.dart';

Future<void> bootstrap({AppConfig? config, List<Override> overrides = const <Override>[], Widget? rootWidget}) async {
  WidgetsFlutterBinding.ensureInitialized();
  final resolvedConfig = config ?? AppConfig.fromEnvironment();
  final logger = AppLogger(config: resolvedConfig);
  final hiveManager = HiveManager(secureStorage: const FlutterSecureStorage(), logger: logger);

  await hiveManager.init();
  Hive.registerAdapter(TodoDtoAdapter());
  Hive.registerAdapter(CachedTodosAdapter());
  await hiveManager.openCoreBoxes();

  final container = ProviderContainer(
    overrides: <Override>[
      appConfigProvider.overrideWithValue(resolvedConfig),
      hiveManagerProvider.overrideWithValue(hiveManager),
      ...overrides,
    ],
    observers: <ProviderObserver>[
      if (resolvedConfig.enableLogging && kDebugMode) AppProviderObserver(logger),
    ],
  );

  FlutterError.onError = (FlutterErrorDetails details) {
    logger.error('Flutter error', error: details.exception, stackTrace: details.stack);
  };

  runZonedGuarded(
    () => runApp(UncontrolledProviderScope(container: container, child: rootWidget ?? const App())),
    (Object error, StackTrace stackTrace) => logger.error('Unhandled error', error: error, stackTrace: stackTrace),
  );
}
