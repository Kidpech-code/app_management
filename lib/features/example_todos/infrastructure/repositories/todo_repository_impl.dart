import 'package:dio/dio.dart';

import 'package:app_management/core/error/failures.dart';
import 'package:app_management/core/error/result.dart';
import 'package:app_management/features/example_todos/domain/entities/todo.dart';
import 'package:app_management/features/example_todos/domain/repositories/todo_repository.dart';
import 'package:app_management/features/example_todos/infrastructure/datasources/todo_local_ds.dart';
import 'package:app_management/features/example_todos/infrastructure/datasources/todo_remote_ds.dart';
import 'package:app_management/features/example_todos/infrastructure/models/todo_dto.dart';

class TodoRepositoryImpl implements TodoRepository {
  TodoRepositoryImpl({required TodoRemoteDataSource remote, required TodoLocalDataSource local})
      : _remote = remote,
        _local = local;

  final TodoRemoteDataSource _remote;
  final TodoLocalDataSource _local;

  @override
  Future<Result<List<Todo>>> fetchTodos({required int page, CancelToken? cancelToken, bool forceRefresh = false}) async {
    if (!forceRefresh && page == 1 && !_local.isCacheStale()) {
      final cached = _local.getTodos();
      if (cached.isNotEmpty) {
        return Success<List<Todo>>(cached);
      }
    }
    try {
      final remoteTodos = await _remote.fetchTodos(page: page, cancelToken: cancelToken);
      final todos = remoteTodos.map((TodoDto dto) => dto.toDomain()).toList();
      if (page == 1) {
        await _local.cacheTodos(todos);
      }
      return Success<List<Todo>>(todos);
    } on DioException catch (error) {
      if (page == 1) {
        final cached = _local.getTodos();
        if (cached.isNotEmpty) {
          return Success<List<Todo>>(cached);
        }
      }
      return FailureResult<List<Todo>>(_mapError(error));
    }
  }

  @override
  Future<Result<Todo>> addTodo({required String title}) async {
    final optimistic = <Todo>[..._local.getTodos()];
    final tempTodo = Todo(
      id: 'temp-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      isCompleted: false,
      updatedAt: DateTime.now(),
    );
    optimistic.add(tempTodo);
    await _local.cacheTodos(optimistic);
    try {
      final created = await _remote.addTodo(title: title);
      final todos = optimistic
        ..removeWhere((todo) => todo.id == tempTodo.id)
        ..add(created.toDomain());
      await _local.cacheTodos(todos);
      return Success<Todo>(created.toDomain());
    } on DioException catch (error) {
      await _local.cacheTodos(_local.getTodos()..removeWhere((todo) => todo.id == tempTodo.id));
      return FailureResult<Todo>(_mapError(error));
    }
  }

  @override
  Future<Result<Todo>> toggleTodo({required String id}) async {
    final current = _local.getTodos();
    final index = current.indexWhere((todo) => todo.id == id);
    if (index == -1) {
      return const FailureResult<Todo>(UnknownFailure('Todo not found locally'));
    }
    final toggled = current[index].copyWith(isCompleted: !current[index].isCompleted, updatedAt: DateTime.now());
    final optimistic = [...current]..[index] = toggled;
    await _local.cacheTodos(optimistic);
    try {
      final updated = await _remote.toggleTodo(id: id);
      optimistic[index] = updated.toDomain();
      await _local.cacheTodos(optimistic);
      return Success<Todo>(updated.toDomain());
    } on DioException catch (error) {
      await _local.cacheTodos(current);
      return FailureResult<Todo>(_mapError(error));
    }
  }

  @override
  Future<Result<void>> deleteTodo({required String id}) async {
    final current = _local.getTodos();
    final updated = [...current]..removeWhere((todo) => todo.id == id);
    await _local.cacheTodos(updated);
    try {
      await _remote.deleteTodo(id: id);
      return const Success<void>(null);
    } on DioException catch (error) {
      await _local.cacheTodos(current);
      return FailureResult<void>(_mapError(error));
    }
  }

  @override
  Stream<List<Todo>> watchTodos() => _local.watchTodos();

  Failure _mapError(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 401) {
      return const UnauthorizedFailure('Session expired. Please sign in again.');
    }
    if (statusCode != null) {
      return NetworkFailure('Request failed with status $statusCode', statusCode: statusCode);
    }
    if (error.type == DioExceptionType.connectionTimeout || error.type == DioExceptionType.receiveTimeout) {
      return const NetworkFailure('Network timeout. Check your connection.');
    }
    return const UnknownFailure('Unexpected error');
  }
}
