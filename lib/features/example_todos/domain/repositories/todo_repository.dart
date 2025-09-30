import 'package:dio/dio.dart';

import 'package:app_management/core/error/result.dart';
import 'package:app_management/features/example_todos/domain/entities/todo.dart';

abstract class TodoRepository {
  Future<Result<List<Todo>>> fetchTodos({required int page, CancelToken? cancelToken, bool forceRefresh = false});
  Future<Result<Todo>> addTodo({required String title});
  Future<Result<Todo>> toggleTodo({required String id});
  Future<Result<void>> deleteTodo({required String id});
  Stream<List<Todo>> watchTodos();
}
