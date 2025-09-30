import 'package:app_management/features/auth/domain/entities/auth_user.dart';
import 'package:app_management/features/auth/domain/entities/token_pair.dart';

class AuthUserDto {
  AuthUserDto({required this.id, required this.email, this.displayName});

  final String id;
  final String email;
  final String? displayName;

  factory AuthUserDto.fromJson(Map<String, dynamic> json) => AuthUserDto(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['name'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{'id': id, 'email': email, 'name': displayName};

  AuthUser toDomain() => AuthUser(id: id, email: email, displayName: displayName);
}

class AuthTokensDto {
  AuthTokensDto({required this.accessToken, required this.refreshToken, required this.expiresAt});

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  factory AuthTokensDto.fromJson(Map<String, dynamic> json) => AuthTokensDto(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'expiresAt': expiresAt.toIso8601String(),
      };

  TokenPair toDomain() => TokenPair(accessToken: accessToken, refreshToken: refreshToken, expiresAt: expiresAt);
}

class AuthResponseDto {
  AuthResponseDto({required this.user, required this.tokens});

  final AuthUserDto user;
  final AuthTokensDto tokens;

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) => AuthResponseDto(
        user: AuthUserDto.fromJson(json['user'] as Map<String, dynamic>),
        tokens: AuthTokensDto.fromJson(json['tokens'] as Map<String, dynamic>),
      );
}
