import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_management/app/di/providers.dart';
import 'package:app_management/core/error/result.dart';
import 'package:app_management/features/example_todos/domain/entities/todo.dart';
import 'package:app_management/features/example_todos/domain/repositories/todo_repository.dart';
import 'package:app_management/features/example_todos/domain/value_objects/value_objects.dart';

class TodosNotifier extends AsyncNotifier<List<Todo>> {
  late final TodoRepository _repository = ref.read(todoRepositoryProvider);
  CancelToken? _cancelToken;
  StreamSubscription<List<Todo>>? _subscription;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  Future<List<Todo>> build() async {
    ref.onDispose(() {
      _subscription?.cancel();
      _cancelToken?.cancel('disposed');
    });
    _subscription = _repository.watchTodos().listen((todos) {
      if (state.hasValue) {
        state = AsyncData(todos);
      }
    });
    final result = await _repository.fetchTodos(page: 1, cancelToken: _cancelToken);
    return result.when(success: (data) => data, failure: (failure) => throw failure);
  }

  Future<void> refresh({bool forceNetwork = false}) async {
    state = const AsyncLoading();
    final result = await _repository.fetchTodos(page: 1, forceRefresh: forceNetwork);
    state = result.when(
      success: (data) {
        _currentPage = 1;
        _hasMore = data.isNotEmpty;
        return AsyncData(data);
      },
      failure: (failure) => AsyncError<Object>(failure, StackTrace.current),
    );
  }

  Future<void> loadMore() async {
    if (!_hasMore) {
      return;
    }
    final previous = state.value ?? <Todo>[];
    _cancelToken = CancelToken();
    final result = await _repository.fetchTodos(page: _currentPage + 1, cancelToken: _cancelToken);
    result.when(
      success: (data) {
        if (data.isEmpty) {
          _hasMore = false;
          return;
        }
        _currentPage += 1;
        state = AsyncData([...previous, ...data]);
      },
      failure: (_) {},
    );
  }

  Future<Result<Todo>> addTodo(String title) => _repository.addTodo(title: title);

  Future<Result<Todo>> toggleTodo(String id) => _repository.toggleTodo(id: id);

  Future<Result<void>> deleteTodo(String id) => _repository.deleteTodo(id: id);
}

final todosNotifierProvider = AsyncNotifierProvider<TodosNotifier, List<Todo>>(TodosNotifier.new);

final todoFilterProvider = StateProvider<TodoFilter>((ref) => TodoFilter.all);

final filteredTodosProvider = Provider<List<Todo>>((ref) {
  final filter = ref.watch(todoFilterProvider);
  final todos = ref.watch(todosNotifierProvider).maybeWhen(data: (data) => data, orElse: () => <Todo>[]);
  return todos.where((todo) => filter.apply(todo.isCompleted)).toList();
});

final todoByIdProvider = Provider.family<Todo?, String>((ref, id) {
  final todos = ref.watch(todosNotifierProvider.select((value) => value.value));
  if (todos == null) {
    return null;
  }
  for (final todo in todos) {
    if (todo.id == id) {
      return todo;
    }
  }
  return null;
});
