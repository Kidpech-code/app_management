import 'package:app_management/features/auth/domain/entities/auth_user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({required this.status, this.user});

  final AuthStatus status;
  final AuthUser? user;

  AuthState copyWith({AuthStatus? status, AuthUser? user}) => AuthState(status: status ?? this.status, user: user ?? this.user);

  static const AuthState unauthenticated = AuthState(status: AuthStatus.unauthenticated);
  static const AuthState unknown = AuthState(status: AuthStatus.unknown);
}
