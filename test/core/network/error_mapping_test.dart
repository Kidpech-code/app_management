import 'package:app_management/core/error/failures.dart';
import 'package:app_management/core/error/result.dart';
import 'package:app_management/features/example_todos/domain/entities/todo.dart';
import 'package:app_management/features/example_todos/infrastructure/datasources/todo_local_ds.dart';
import 'package:app_management/features/example_todos/infrastructure/datasources/todo_remote_ds.dart';
import 'package:app_management/features/example_todos/infrastructure/repositories/todo_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTodoRemoteDataSource extends Mock implements TodoRemoteDataSource {}

class _MockTodoLocalDataSource extends Mock implements TodoLocalDataSource {}

void main() {
  test('maps DioException to NetworkFailure with status code', () async {
    final remote = _MockTodoRemoteDataSource();
    final local = _MockTodoLocalDataSource();
    final repository = TodoRepositoryImpl(remote: remote, local: local);

    when(local.isCacheStale).thenReturn(true);
    when(local.getTodos).thenReturn(<Todo>[]);
    when(() => remote.fetchTodos(page: any(named: 'page'), cancelToken: any(named: 'cancelToken'))).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/todos'),
        response: Response<dynamic>(requestOptions: RequestOptions(path: '/todos'), statusCode: 503),
      ),
    );

    final result = await repository.fetchTodos(page: 1);

    expect(result, isA<FailureResult<List<Todo>>>());
    final failure = (result as FailureResult<List<Todo>>).failure;
    expect(failure, isA<NetworkFailure>());
    expect((failure as NetworkFailure).statusCode, 503);
  });
}
