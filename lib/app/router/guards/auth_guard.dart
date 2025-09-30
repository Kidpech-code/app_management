import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_management/features/auth/application/auth_notifier.dart';
import 'package:app_management/features/auth/application/auth_state.dart';

import '../app_router.dart';

class AuthGuard {
  AuthGuard(this.ref);

  final Ref ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final auth = ref.watch(authNotifierProvider);
    final isLoggingIn = state.matchedLocation == LoginRoute.location();

    if (auth.isLoading) {
      return null;
    }
    final value = auth.valueOrNull;
    final status = value?.status ?? AuthStatus.unauthenticated;
    final isAuthenticated = status == AuthStatus.authenticated;

    if (!isAuthenticated) {
      if (isLoggingIn) {
        return null;
      }
      final from = state.uri.toString();
      return LoginRoute.location(from: from);
    }

    if (isAuthenticated && isLoggingIn) {
      final from = state.uri.queryParameters['from'];
      if (from != null && from.isNotEmpty) {
        return from;
      }
      return TodosRoute.location;
    }
    return null;
  }
}
