import 'package:app_management/app/di/providers.dart';
import 'package:app_management/features/auth/application/auth_state.dart';
import 'package:app_management/features/auth/domain/entities/auth_user.dart';
import 'package:app_management/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthNotifier extends AsyncNotifier<AuthState> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  Future<AuthState> build() async {
    final user = await _repository.currentUser();
    if (user != null) {
      return AuthState(status: AuthStatus.authenticated, user: user);
    }
    return AuthState.unauthenticated;
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = await _repository.signIn(email: email, password: password);
      return AuthState(status: AuthStatus.authenticated, user: user);
    });
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AsyncData(AuthState.unauthenticated);
  }

  Future<String?> refreshSession() async {
    final tokens = await _repository.refreshToken();
    if (tokens == null) {
      await _repository.signOut();
      state = const AsyncData(AuthState.unauthenticated);
      return null;
    }
    final user = await _repository.currentUser();
    if (user != null) {
      state = AsyncData(AuthState(status: AuthStatus.authenticated, user: user));
    }
    return tokens.accessToken;
  }

  Future<void> forceLogout() async {
    await _repository.signOut();
    state = const AsyncData(AuthState.unauthenticated);
  }

  AuthUser? get currentUser => state.value?.user;
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
