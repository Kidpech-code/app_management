import 'dart:async';

import 'package:app_management/app/bootstrap.dart';
import 'package:app_management/app/di/providers.dart';
import 'package:app_management/core/error/result.dart';
import 'package:app_management/features/auth/domain/entities/auth_user.dart';
import 'package:app_management/features/auth/domain/entities/token_pair.dart';
import 'package:app_management/features/auth/domain/repositories/auth_repository.dart';
import 'package:app_management/features/example_todos/domain/entities/todo.dart';
import 'package:app_management/features/example_todos/domain/repositories/todo_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

class FakeAuthRepository implements AuthRepository {
  AuthUser? _user;
  TokenPair? _tokens;

  @override
  Future<AuthUser> signIn({required String email, required String password}) async {
    _user = AuthUser(id: '1', email: email);
    _tokens = TokenPair(accessToken: 'token', refreshToken: 'refresh', expiresAt: DateTime.now().add(const Duration(hours: 1)));
    return _user!;
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _tokens = null;
  }

  @override
  Future<TokenPair?> refreshToken() async => _tokens;

  @override
  Future<AuthUser?> currentUser() async => _user;

  @override
  Future<String?> cachedAccessToken() async => _tokens?.accessToken;
}

class FakeTodoRepository implements TodoRepository {
  FakeTodoRepository() {
    _emit();
  }

  final _todos = <Todo>[
    Todo(id: '1', title: 'Test Todo 1', isCompleted: false, updatedAt: DateTime.now()),
    Todo(id: '2', title: 'Test Todo 2', isCompleted: true, updatedAt: DateTime.now()),
  ];
  final _controller = StreamController<List<Todo>>.broadcast();

  void _emit() => _controller.add(List<Todo>.unmodifiable(_todos));

  void dispose() {
    _controller.close();
  }

  @override
  Future<Result<List<Todo>>> fetchTodos({required int page, CancelToken? cancelToken, bool forceRefresh = false}) async {
    return Success<List<Todo>>(List<Todo>.unmodifiable(_todos));
  }

  @override
  Future<Result<Todo>> addTodo({required String title}) async {
    final todo = Todo(id: DateTime.now().millisecondsSinceEpoch.toString(), title: title, isCompleted: false, updatedAt: DateTime.now());
    _todos.add(todo);
    _emit();
    return Success<Todo>(todo);
  }

  @override
  Future<Result<Todo>> toggleTodo({required String id}) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    final updated = _todos[index].copyWith(isCompleted: !_todos[index].isCompleted, updatedAt: DateTime.now());
    _todos[index] = updated;
    _emit();
    return Success<Todo>(updated);
  }

  @override
  Future<Result<void>> deleteTodo({required String id}) async {
    _todos.removeWhere((todo) => todo.id == id);
    _emit();
    return const Success<void>(null);
  }

  @override
  Stream<List<Todo>> watchTodos() => _controller.stream;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('happy path login to detail navigation and deep link', (tester) async {
    final authRepository = FakeAuthRepository();
    final todoRepository = FakeTodoRepository();
    addTearDown(todoRepository.dispose);

    await bootstrap(
      overrides: <Override>[
        authRepositoryProvider.overrideWithValue(authRepository),
        todoRepositoryProvider.overrideWithValue(todoRepository),
      ],
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'user@test.com');
    await tester.enterText(find.byType(TextFormField).last, 'password');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Todos'), findsWidgets);
    await tester.tap(find.text('Test Todo 1'));
    await tester.pumpAndSettle();
    expect(find.text('Test Todo 1'), findsWidgets);

    final context = tester.element(find.byType(NavigationBar));
    GoRouter.of(context).go('/todos/2');
    await tester.pumpAndSettle();
    expect(find.text('Test Todo 2'), findsWidgets);
  });
}
