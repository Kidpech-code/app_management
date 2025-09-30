import 'package:dio/dio.dart';

import 'package:app_management/core/network/interceptors/auth_interceptor.dart';
import 'package:app_management/features/auth/infrastructure/models/auth_dto.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<AuthResponseDto> signIn({required String email, required String password}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: <String, dynamic>{'email': email, 'password': password},
      options: Options(extra: const {skipAuthKey: true}),
    );
    return AuthResponseDto.fromJson(response.data ?? <String, dynamic>{});
  }

  Future<AuthTokensDto> refreshToken({required String refreshToken}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: <String, dynamic>{'refreshToken': refreshToken},
      options: Options(extra: const {skipAuthKey: true}),
    );
    return AuthTokensDto.fromJson(response.data ?? <String, dynamic>{});
  }

  Future<void> revokeToken({required String refreshToken}) async {
    await _dio.post<void>(
      '/auth/logout',
      data: <String, dynamic>{'refreshToken': refreshToken},
      options: Options(extra: const {skipAuthKey: true}),
    );
  }
}
