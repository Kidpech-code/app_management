import 'package:app_management/features/auth/domain/entities/auth_user.dart';
import 'package:app_management/features/auth/domain/entities/token_pair.dart';
import 'package:app_management/features/auth/domain/repositories/auth_repository.dart';
import 'package:app_management/features/auth/infrastructure/datasources/auth_local_datasource.dart';
import 'package:app_management/features/auth/infrastructure/datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required AuthRemoteDataSource remote, required AuthLocalDataSource local})
      : _remote = remote,
        _local = local;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  @override
  Future<AuthUser> signIn({required String email, required String password}) async {
    final response = await _remote.signIn(email: email, password: password);
    final user = response.user.toDomain();
    final tokens = response.tokens.toDomain();
    await _local.cacheSession(tokens: tokens, user: user);
    return user;
  }

  @override
  Future<void> signOut() async {
    final tokens = _local.readTokens();
    if (tokens != null) {
      try {
        await _remote.revokeToken(refreshToken: tokens.refreshToken);
      } catch (_) {
        // Ignore remote errors during sign out.
      }
    }
    await _local.clearSession();
  }

  @override
  Future<TokenPair?> refreshToken() async {
    final cached = _local.readTokens();
    if (cached == null) {
      await _local.clearSession();
      return null;
    }
    if (!cached.isExpired) {
      return cached;
    }
    final refreshed = await _remote.refreshToken(refreshToken: cached.refreshToken);
    final newPair = refreshed.toDomain();
    final user = _local.readUser();
    if (user != null) {
      await _local.cacheSession(tokens: newPair, user: user);
    } else {
      await _local.cacheTokens(newPair);
    }
    return newPair;
  }

  @override
  Future<AuthUser?> currentUser() async => _local.readUser();

  @override
  Future<String?> cachedAccessToken() => _local.readAccessToken();
}
