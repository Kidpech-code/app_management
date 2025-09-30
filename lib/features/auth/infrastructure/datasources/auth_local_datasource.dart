import 'package:app_management/core/storage/hive_boxes.dart';
import 'package:app_management/features/auth/domain/entities/auth_user.dart';
import 'package:app_management/features/auth/domain/entities/token_pair.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AuthLocalDataSource {
  AuthLocalDataSource()
      : _secureBox = Hive.box<dynamic>(HiveBoxes.secureTokens),
        _prefsBox = Hive.box<dynamic>(HiveBoxes.appPrefs);

  final Box<dynamic> _secureBox;
  final Box<dynamic> _prefsBox;

  static const _tokenKey = 'token_pair';
  static const _userKey = 'user_profile';

  Future<void> cacheSession({required TokenPair tokens, required AuthUser user}) async {
    await cacheTokens(tokens);
    await cacheUser(user);
  }

  Future<void> cacheTokens(TokenPair tokens) async {
    await _secureBox.put(_tokenKey, tokens.toJson());
  }

  Future<void> cacheUser(AuthUser user) async {
    await _prefsBox.put(_userKey, user.toJson());
  }

  TokenPair? readTokens() {
    final dynamic json = _secureBox.get(_tokenKey);
    if (json is Map) {
      return TokenPair.fromJson(Map<String, dynamic>.from(json));
    }
    return null;
  }

  AuthUser? readUser() {
    final dynamic json = _prefsBox.get(_userKey);
    if (json is Map) {
      return AuthUser.fromJson(Map<String, dynamic>.from(json));
    }
    return null;
  }

  Future<void> clearSession() async {
    await Future.wait<void>([
      _secureBox.delete(_tokenKey),
      _prefsBox.delete(_userKey),
    ]);
  }

  Future<String?> readAccessToken() async => readTokens()?.accessToken;
}
