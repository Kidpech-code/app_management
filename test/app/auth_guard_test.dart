import 'package:app_management/app/di/providers.dart';
import 'package:app_management/app/router/guards/auth_guard.dart';
import 'package:app_management/features/auth/application/auth_notifier.dart';
import 'package:app_management/features/auth/application/auth_state.dart';
import 'package:app_management/features/auth/domain/entities/auth_user.dart';
import 'package:app_management/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockGoRouterState extends Mock implements GoRouterState {}

class _FakeBuildContext extends Fake implements BuildContext {}

final _guardProvider = Provider<AuthGuard>((ref) => AuthGuard(ref));

void main() {
  setUpAll(() {
    registerFallbackValue(const AuthUser(id: '1', email: 'test@test.com'));
  });

  test('redirects to login when unauthenticated and accessing protected route', () async {
    final repository = _MockAuthRepository();
    when(repository.currentUser).thenAnswer((_) async => null);
    final container = ProviderContainer(overrides: [authRepositoryProvider.overrideWithValue(repository)]);
    addTearDown(container.dispose);
    await container.read(authNotifierProvider.future);

    final guard = container.read(_guardProvider);
    final state = _MockGoRouterState();
    when(() => state.matchedLocation).thenReturn('/todos');
    when(() => state.uri).thenReturn(Uri.parse('/todos'));

    final redirect = guard.redirect(_FakeBuildContext(), state);

    expect(redirect, contains('/login'));
  });

  test('redirects authenticated user away from login', () async {
    final repository = _MockAuthRepository();
    final user = const AuthUser(id: '1', email: 'test@test.com');
    when(repository.currentUser).thenAnswer((_) async => user);
    final container = ProviderContainer(overrides: [authRepositoryProvider.overrideWithValue(repository)]);
    addTearDown(container.dispose);
    await container.read(authNotifierProvider.future);
    container.read(authNotifierProvider.notifier).state = AsyncData(AuthState(status: AuthStatus.authenticated, user: user));

    final guard = container.read(_guardProvider);
    final state = _MockGoRouterState();
    when(() => state.matchedLocation).thenReturn('/login');
    when(() => state.uri).thenReturn(Uri.parse('/login'));
    when(() => state.queryParameters).thenReturn(<String, String>{});

    final redirect = guard.redirect(_FakeBuildContext(), state);

    expect(redirect, isNotNull);
    expect(redirect, isNot(contains('/login')));
  });
}
