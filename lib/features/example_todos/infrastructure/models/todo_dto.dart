import 'package:hive_flutter/hive_flutter.dart';

import 'package:app_management/features/example_todos/domain/entities/todo.dart';

class TodoDto {
  TodoDto({required this.id, required this.title, required this.isCompleted, required this.updatedAt, this.createdAt});

  final String id;
  final String title;
  final bool isCompleted;
  final DateTime updatedAt;
  final DateTime? createdAt;

  factory TodoDto.fromJson(Map<String, dynamic> json) => TodoDto(
        id: json['id'] as String,
        title: json['title'] as String,
        isCompleted: json['isCompleted'] as bool,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
        'updatedAt': updatedAt.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
      };

  Todo toDomain() => Todo(id: id, title: title, isCompleted: isCompleted, updatedAt: updatedAt, createdAt: createdAt);

  static TodoDto fromDomain(Todo todo) => TodoDto(
        id: todo.id,
        title: todo.title,
        isCompleted: todo.isCompleted,
        updatedAt: todo.updatedAt,
        createdAt: todo.createdAt,
      );
}

class CachedTodos {
  CachedTodos({required this.todos, required this.cachedAt});

  final List<TodoDto> todos;
  final DateTime cachedAt;

  bool get isStale => DateTime.now().difference(cachedAt) > const Duration(minutes: 5);
}

class TodoDtoAdapter extends TypeAdapter<TodoDto> {
  @override
  final int typeId = 1;

  @override
  TodoDto read(BinaryReader reader) {
    final id = reader.readString();
    final title = reader.readString();
    final isCompleted = reader.readBool();
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final hasCreated = reader.readBool();
    final createdAt = hasCreated ? DateTime.fromMillisecondsSinceEpoch(reader.readInt()) : null;
    return TodoDto(id: id, title: title, isCompleted: isCompleted, updatedAt: updatedAt, createdAt: createdAt);
  }

  @override
  void write(BinaryWriter writer, TodoDto obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.title)
      ..writeBool(obj.isCompleted)
      ..writeInt(obj.updatedAt.millisecondsSinceEpoch)
      ..writeBool(obj.createdAt != null);
    if (obj.createdAt != null) {
      writer.writeInt(obj.createdAt!.millisecondsSinceEpoch);
    }
  }
}

class CachedTodosAdapter extends TypeAdapter<CachedTodos> {
  @override
  final int typeId = 2;

  @override
  CachedTodos read(BinaryReader reader) {
    final count = reader.readInt();
    final todos = <TodoDto>[];
    final adapter = TodoDtoAdapter();
    for (var i = 0; i < count; i++) {
      todos.add(adapter.read(reader));
    }
    final cachedAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    return CachedTodos(todos: todos, cachedAt: cachedAt);
  }

  @override
  void write(BinaryWriter writer, CachedTodos obj) {
    writer..writeInt(obj.todos.length);
    final adapter = TodoDtoAdapter();
    for (final todo in obj.todos) {
      adapter.write(writer, todo);
    }
    writer.writeInt(obj.cachedAt.millisecondsSinceEpoch);
  }
}
