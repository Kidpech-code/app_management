import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_management/app/di/providers.dart';
import 'package:app_management/app/router/app_shell.dart';
import 'package:app_management/app/router/guards/auth_guard.dart';
import 'package:app_management/features/auth/application/auth_notifier.dart';
import 'package:app_management/features/auth/presentation/screens/login_page.dart';
import 'package:app_management/features/example_todos/presentation/screens/todo_detail_page.dart';
import 'package:app_management/features/example_todos/presentation/screens/todos_page.dart';
import 'package:app_management/features/settings/presentation/screens/settings_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final guard = AuthGuard(ref);
  final notifier = ref.read(authNotifierProvider.notifier);
  final refreshListenable = StreamRouterRefreshListenable(notifier.stream);
  final router = GoRouter(
    initialLocation: TodosRoute.location,
    routes: <RouteBase>[
      GoRoute(
        path: LoginRoute.path,
        name: LoginRoute.name,
        builder: (context, state) => LoginPage(redirectTo: state.uri.queryParameters['from']),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child, location: state.matchedLocation),
        routes: <RouteBase>[
          GoRoute(
            path: TodosRoute.path,
            name: TodosRoute.name,
            builder: (context, state) => const TodosPage(),
            routes: <RouteBase>[
              GoRoute(
                path: TodoDetailsRoute.path,
                name: TodoDetailsRoute.name,
                builder: (context, state) => TodoDetailPage(todoId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: SettingsRoute.path,
            name: SettingsRoute.name,
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
    redirect: guard.redirect,
    debugLogDiagnostics: ref.read(appConfigProvider).enableLogging,
    refreshListenable: refreshListenable,
  );
  ref.onDispose(() {
    refreshListenable.dispose();
    router.dispose();
  });
  return router;
});

class LoginRoute {
  static const path = '/login';
  static const name = 'login';

  static String location({String? from}) {
    final params = <String, String>{if (from != null) 'from': from};
    final uri = Uri(path: path, queryParameters: params.isEmpty ? null : params);
    return uri.toString();
  }

  static void go(BuildContext context, {String? from}) => context.go(location(from: from));
}

class TodosRoute {
  static const path = '/todos';
  static const name = 'todos';
  static const location = path;

  static void go(BuildContext context) => context.go(location);
  static Future<void> push(BuildContext context) => context.push(location);
}

class TodoDetailsRoute {
  static const path = ':id';
  static const name = 'todo-detail';

  static String location(String id) => '/todos/$id';
  static Future<void> push(BuildContext context, String id) => context.push(location(id));
}

class SettingsRoute {
  static const path = '/settings';
  static const name = 'settings';
  static const location = path;

  static void go(BuildContext context) => context.go(location);
}

class StreamRouterRefreshListenable extends ChangeNotifier {
  StreamRouterRefreshListenable(Stream<dynamic> stream)
      : _subscription = stream.listen((_) => notifyListeners());

  final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
