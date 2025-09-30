import 'dart:async';

import 'package:app_management/app/di/providers.dart';
import 'package:app_management/core/error/failures.dart';
import 'package:app_management/core/error/result.dart';
import 'package:app_management/features/example_todos/application/todos_notifier.dart';
import 'package:app_management/features/example_todos/domain/entities/todo.dart';
import 'package:app_management/features/example_todos/domain/repositories/todo_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart' show ProviderOverride;

class _MockTodoRepository extends Mock implements TodoRepository {}

void main() {
  late ProviderContainer container;
  late _MockTodoRepository repository;

  setUp(() {
    repository = _MockTodoRepository();
    when(repository.watchTodos).thenAnswer((_) => const Stream<List<Todo>>.empty());
    container = ProviderContainer(
      overrides: <ProviderOverride>[todoRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(container.dispose);

  test('loads todos on initialization', () async {
    final todos = <Todo>[Todo(id: '1', title: 'Test', isCompleted: false, updatedAt: DateTime.now())];
    when(() => repository.fetchTodos(page: any(named: 'page'), cancelToken: any(named: 'cancelToken')))
        .thenAnswer((_) async => Success<List<Todo>>(todos));

    final state = await container.read(todosNotifierProvider.future);

    expect(state, todos);
  });

  test('addTodo propagates failure', () async {
    when(() => repository.fetchTodos(page: any(named: 'page'), cancelToken: any(named: 'cancelToken')))
        .thenAnswer((_) async => const Success<List<Todo>>(<Todo>[]));
    when(() => repository.addTodo(title: any(named: 'title')))
        .thenAnswer((_) async => const FailureResult<Todo>(UnknownFailure('error')));

    await container.read(todosNotifierProvider.future);
    final result = await container.read(todosNotifierProvider.notifier).addTodo('new');

    expect(result, isA<FailureResult<Todo>>());
  });

  test('loadMore appends todos when available', () async {
    final firstPage = <Todo>[Todo(id: '1', title: 'A', isCompleted: false, updatedAt: DateTime.now())];
    final secondPage = <Todo>[Todo(id: '2', title: 'B', isCompleted: false, updatedAt: DateTime.now())];
    when(() => repository.fetchTodos(page: 1, cancelToken: any(named: 'cancelToken')))
        .thenAnswer((_) async => Success<List<Todo>>(firstPage));
    when(() => repository.fetchTodos(page: 2, cancelToken: any(named: 'cancelToken')))
        .thenAnswer((_) async => Success<List<Todo>>(secondPage));

    await container.read(todosNotifierProvider.future);
    await container.read(todosNotifierProvider.notifier).loadMore();

    final data = container.read(todosNotifierProvider).asData?.value;
    expect(data, [...firstPage, ...secondPage]);
  });

  test('ignores loadMore while a previous request is in flight', () async {
    final firstPage = <Todo>[Todo(id: '1', title: 'A', isCompleted: false, updatedAt: DateTime.now())];
    final completer = Completer<Result<List<Todo>>>();
    when(() => repository.fetchTodos(page: 1, cancelToken: any(named: 'cancelToken')))
        .thenAnswer((_) async => Success<List<Todo>>(firstPage));
    when(() => repository.fetchTodos(page: 2, cancelToken: any(named: 'cancelToken')))
        .thenAnswer((_) => completer.future);

    await container.read(todosNotifierProvider.future);
    final notifier = container.read(todosNotifierProvider.notifier);

    final loadFuture = notifier.loadMore();
    notifier.loadMore();

    verify(() => repository.fetchTodos(page: 2, cancelToken: any(named: 'cancelToken'))).called(1);

    completer.complete(const Success<List<Todo>>(<Todo>[]));
    await loadFuture;
  });
}
