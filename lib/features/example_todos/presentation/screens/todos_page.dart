import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_management/app/router/app_router.dart';
import 'package:app_management/features/example_todos/application/todos_notifier.dart';
import 'package:app_management/features/example_todos/domain/value_objects/value_objects.dart';
import 'package:app_management/features/example_todos/presentation/widgets/todo_list_item.dart';

class TodosPage extends ConsumerStatefulWidget {
  const TodosPage({super.key});

  @override
  ConsumerState<TodosPage> createState() => _TodosPageState();
}

class _TodosPageState extends ConsumerState<TodosPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todosAsync = ref.watch(todosNotifierProvider);
    final filter = ref.watch(todoFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todos'),
        actions: <Widget>[
          PopupMenuButton<TodoFilter>(
            initialValue: filter,
            onSelected: (value) => ref.read(todoFilterProvider.notifier).state = value,
            itemBuilder: (context) => TodoFilter.values
                .map(
                  (filter) => PopupMenuItem<TodoFilter>(
                    value: filter,
                    child: Text(filter.name.toUpperCase()),
                  ),
                )
                .toList(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(todosNotifierProvider.notifier).refresh(forceNetwork: true),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
      body: todosAsync.when(
        data: (_) {
          final filtered = ref.watch(filteredTodosProvider);
          if (filtered.isEmpty) {
            return const Center(child: Text('No todos yet. Add your first one!'));
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(todosNotifierProvider.notifier).refresh(forceNetwork: true),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final todo = filtered[index];
                return TodoListItem(
                  todo: todo,
                  onToggle: () async {
                    final result = await ref.read(todosNotifierProvider.notifier).toggleTodo(todo.id);
                    result.when(
                      success: (_) {},
                      failure: (failure) => _showError(context, failure.message),
                    );
                  },
                  onDelete: () async {
                    final result = await ref.read(todosNotifierProvider.notifier).deleteTodo(todo.id);
                    result.when(
                      success: (_) {},
                      failure: (failure) => _showError(context, failure.message),
                    );
                  },
                  onTap: () => TodoDetailsRoute.push(context, todo.id),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Failed to load todos: $error'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.read(todosNotifierProvider.notifier).refresh(forceNetwork: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 300) {
      ref.read(todosNotifierProvider.notifier).loadMore();
    }
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Todo'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Add')),
          ],
        );
      },
    );
    if (result != null && result.isNotEmpty) {
      final response = await ref.read(todosNotifierProvider.notifier).addTodo(result);
      response.when(
        success: (_) {},
        failure: (failure) => _showError(context, failure.message),
      );
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
