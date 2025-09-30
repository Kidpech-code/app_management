import 'package:flutter/material.dart';

import 'package:app_management/features/example_todos/domain/entities/todo.dart';

class TodoListItem extends StatelessWidget {
  const TodoListItem({super.key, required this.todo, required this.onToggle, required this.onDelete, required this.onTap});

  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Checkbox(value: todo.isCompleted, onChanged: (_) => onToggle()),
        title: Text(todo.title, style: TextStyle(decoration: todo.isCompleted ? TextDecoration.lineThrough : null)),
        subtitle: Text('Updated ${todo.updatedAt.toLocal()}'),
        trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: onDelete),
      ),
    );
  }
}
