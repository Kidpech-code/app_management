import 'package:app_management/app/di/providers.dart';
import 'package:app_management/features/auth/application/auth_notifier.dart';
import 'package:app_management/features/auth/application/auth_state.dart';
import 'package:app_management/features/auth/domain/entities/auth_user.dart';
import 'package:app_management/features/auth/domain/entities/token_pair.dart';
import 'package:app_management/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late ProviderContainer container;
  late _MockAuthRepository repository;

  setUp(() {
    repository = _MockAuthRepository();
    container = ProviderContainer(overrides: [authRepositoryProvider.overrideWithValue(repository)]);
  });

  tearDown(() {
    container.dispose();
  });

  test('initializes with authenticated user when repository returns user', () async {
    final user = const AuthUser(id: '1', email: 'user@test.com');
    when(repository.currentUser).thenAnswer((_) async => user);
    when(() => repository.cachedAccessToken()).thenAnswer((_) async => 'token');

    final state = await container.read(authNotifierProvider.future);

    expect(state.status, AuthStatus.authenticated);
    expect(state.user, user);
  });

  test('signIn delegates to repository and updates state', () async {
    final user = const AuthUser(id: '1', email: 'user@test.com');
    when(repository.currentUser).thenAnswer((_) async => null);
    when(() => repository.signIn(email: any(named: 'email'), password: any(named: 'password'))).thenAnswer((_) async => user);
    when(() => repository.refreshToken()).thenAnswer((_) async => null);
    when(() => repository.signOut()).thenAnswer((_) async {});

    await container.read(authNotifierProvider.future);
    await container.read(authNotifierProvider.notifier).signIn(email: 'user@test.com', password: 'secret');

    final authState = container.read(authNotifierProvider);
    expect(authState.value?.status, AuthStatus.authenticated);
    expect(authState.value?.user, user);
  });

  test('refreshSession returns null when repository fails', () async {
    when(repository.currentUser).thenAnswer((_) async => null);
    when(repository.refreshToken).thenAnswer((_) async => null);
    when(repository.signOut).thenAnswer((_) async {});

    await container.read(authNotifierProvider.future);
    final result = await container.read(authNotifierProvider.notifier).refreshSession();

    expect(result, isNull);
    expect(container.read(authNotifierProvider).value?.status, AuthStatus.unauthenticated);
  });

  test('refreshSession returns new token when successful', () async {
    final user = const AuthUser(id: '1', email: 'user@test.com');
    final tokenPair = TokenPair(accessToken: 'new', refreshToken: 'refresh', expiresAt: DateTime.now().add(const Duration(hours: 1)));
    when(repository.currentUser).thenAnswer((_) async => user);
    when(repository.refreshToken).thenAnswer((_) async => tokenPair);

    await container.read(authNotifierProvider.future);
    final result = await container.read(authNotifierProvider.notifier).refreshSession();

    expect(result, tokenPair.accessToken);
    expect(container.read(authNotifierProvider).value?.status, AuthStatus.authenticated);
  });
}
