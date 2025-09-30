import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_management/core/config/app_config.dart';
import 'package:app_management/core/network/dio_client.dart';
import 'package:app_management/core/network/interceptors/auth_interceptor.dart';
import 'package:app_management/core/network/interceptors/retry_interceptor.dart';
import 'package:app_management/core/storage/hive_manager.dart';
import 'package:app_management/core/utils/connectivity.dart';
import 'package:app_management/core/utils/logger.dart';
import 'package:app_management/features/auth/application/auth_notifier.dart';
import 'package:app_management/features/auth/domain/repositories/auth_repository.dart';
import 'package:app_management/features/auth/infrastructure/datasources/auth_local_datasource.dart';
import 'package:app_management/features/auth/infrastructure/datasources/auth_remote_datasource.dart';
import 'package:app_management/features/auth/infrastructure/repositories/auth_repository_impl.dart';
import 'package:app_management/features/example_todos/domain/repositories/todo_repository.dart';
import 'package:app_management/features/example_todos/infrastructure/datasources/todo_local_ds.dart';
import 'package:app_management/features/example_todos/infrastructure/datasources/todo_remote_ds.dart';
import 'package:app_management/features/example_todos/infrastructure/repositories/todo_repository_impl.dart';

final appConfigProvider = Provider<AppConfig>((ref) => throw UnimplementedError('AppConfig must be overridden.'));

final loggerProvider = Provider<AppLogger>((ref) => AppLogger(config: ref.watch(appConfigProvider)));

final hiveManagerProvider = Provider<HiveManager>((ref) => throw UnimplementedError('HiveManager must be overridden.'));

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService(Connectivity());
});

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) => AuthLocalDataSource());

final authDioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final logger = ref.watch(loggerProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  final retryInterceptor = RetryInterceptor(connectivity: connectivity, logger: logger);
  final client = DioClient(
    config: config,
    logger: logger,
    retryInterceptor: retryInterceptor,
  );
  return client.create();
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) => AuthRemoteDataSource(ref.watch(authDioProvider)));

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(remote: ref.watch(authRemoteDataSourceProvider), local: ref.watch(authLocalDataSourceProvider));
});

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final logger = ref.watch(loggerProvider);
  final authLocal = ref.watch(authLocalDataSourceProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  final authRepository = ref.watch(authRepositoryProvider);

  final authInterceptor = AuthInterceptor(
    readAccessToken: authLocal.readAccessToken,
    refreshAccessToken: () async => (await authRepository.refreshToken())?.accessToken,
    onUnauthorized: () async {
      await authLocal.clearSession();
      ref.invalidate(authNotifierProvider);
    },
    logger: logger,
  );
  final retryInterceptor = RetryInterceptor(connectivity: connectivity, logger: logger);
  final client = DioClient(
    config: config,
    logger: logger,
    authInterceptor: authInterceptor,
    retryInterceptor: retryInterceptor,
  );
  return client.create();
});

final todoLocalDataSourceProvider = Provider<TodoLocalDataSource>((ref) => TodoLocalDataSource());

final todoRemoteDataSourceProvider = Provider<TodoRemoteDataSource>((ref) => TodoRemoteDataSource(ref.watch(dioProvider)));

final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  return TodoRepositoryImpl(remote: ref.watch(todoRemoteDataSourceProvider), local: ref.watch(todoLocalDataSourceProvider));
});
