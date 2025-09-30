import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

import 'package:app_management/core/storage/hive_boxes.dart';
import 'package:app_management/features/example_todos/domain/entities/todo.dart';
import 'package:app_management/features/example_todos/infrastructure/models/todo_dto.dart';

class TodoLocalDataSource {
  TodoLocalDataSource() : _box = Hive.box<dynamic>(HiveBoxes.todosCache);

  final Box<dynamic> _box;
  static const _cacheKey = 'todos';

  Future<void> cacheTodos(List<Todo> todos) async {
    final dtos = todos.map(TodoDto.fromDomain).toList();
    final cached = CachedTodos(todos: dtos, cachedAt: DateTime.now());
    await _box.put(_cacheKey, cached);
  }

  List<Todo> getTodos() {
    final dynamic cached = _box.get(_cacheKey);
    if (cached is CachedTodos) {
      return cached.todos.map((dto) => dto.toDomain()).toList();
    }
    return <Todo>[];
  }

  bool isCacheStale() {
    final dynamic cached = _box.get(_cacheKey);
    if (cached is CachedTodos) {
      return cached.isStale;
    }
    return true;
  }

  Stream<List<Todo>> watchTodos() {
    final controller = StreamController<List<Todo>>.broadcast();
    void emit() {
      if (!controller.isClosed) {
        controller.add(getTodos());
      }
    }

    final subscription = _box.watch(key: _cacheKey).listen((_) => emit());
    controller.onListen = emit;
    controller.onCancel = () async {
      await subscription.cancel();
      await controller.close();
    };
    return controller.stream;
  }

  Future<void> clear() async => _box.delete(_cacheKey);
}
