import '../entities/auth_user.dart';
import '../entities/token_pair.dart';

abstract class AuthRepository {
  Future<AuthUser> signIn({required String email, required String password});
  Future<void> signOut();
  Future<TokenPair?> refreshToken();
  Future<AuthUser?> currentUser();
  Future<String?> cachedAccessToken();
}
