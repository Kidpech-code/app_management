import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_management/features/example_todos/application/todos_notifier.dart';

class TodoDetailPage extends ConsumerWidget {
  const TodoDetailPage({super.key, required this.todoId});

  final String todoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todo = ref.watch(todoByIdProvider(todoId));
    if (todo == null) {
      return const Scaffold(body: Center(child: Text('Todo not found.')));
    }
    return Scaffold(
      appBar: AppBar(title: Text(todo.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Checkbox(
                  value: todo.isCompleted,
                  onChanged: (_) => ref.read(todosNotifierProvider.notifier).toggleTodo(todo.id),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    todo.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Last updated: ${todo.updatedAt.toLocal()}'),
            if (todo.createdAt != null) Text('Created: ${todo.createdAt}'),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await ref.read(todosNotifierProvider.notifier).deleteTodo(todo.id);
                result.when(
                  success: (_) => Navigator.of(context).pop(),
                  failure: (failure) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message))),
                );
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }
}
