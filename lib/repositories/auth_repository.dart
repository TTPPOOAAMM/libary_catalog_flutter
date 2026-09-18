import 'package:dio/dio.dart';
import '../core/api_exceptions.dart';
import '../core/permissions.dart';
import '../models/auth_tokens.dart';
import '../models/user.dart';

abstract class AuthRepository {
  Future<(User, AuthTokens)> login(String username, String password);
  Future<(User, AuthTokens)> register({
    required String username,
    required String password,
    required String fullName,
    required String email,
    required String role,
  });
  Future<AuthTokens> refreshToken(String refreshToken);
  Future<User> getCurrentUser();
}

class ApiAuthRepository implements AuthRepository {
  final Dio _dio;
  ApiAuthRepository(this._dio);

  (User, AuthTokens) _parseAuthResponse(
    Map<String, dynamic> data, {
    String fallbackUsername = '',
    String fallbackFullName = '',
    String fallbackEmail = '',
    String fallbackRole = 'reader',
  }) {
    User user;
    if (data['user'] is Map<String, dynamic>) {
      user = User.fromJson(data['user'] as Map<String, dynamic>);
    } else if (data['user'] is Map) {
      user = User.fromJson(Map<String, dynamic>.from(data['user'] as Map));
    } else {
      user = User(
        id: data['id'] as int? ?? data['userId'] as int? ?? 1,
        username: data['username'] as String? ?? fallbackUsername,
        fullName: data['fullName'] as String? ??
            fallbackFullName.ifEmpty(fallbackUsername),
        email: data['email'] as String? ?? fallbackEmail,
        role: UserRole.fromString(data['role'] as String? ?? fallbackRole),
      );
    }

    Map<String, dynamic> tokenMap = data;
    if (data['tokens'] is Map) {
      tokenMap = Map<String, dynamic>.from(data['tokens'] as Map);
    }

    final tokens = AuthTokens(
      accessToken: tokenMap['accessToken'] as String? ??
          tokenMap['access_token'] as String? ??
          tokenMap['token'] as String? ??
          'mock-token-${DateTime.now().millisecondsSinceEpoch}',
      refreshToken: tokenMap['refreshToken'] as String? ??
          tokenMap['refresh_token'] as String? ??
          'mock-refresh-${DateTime.now().millisecondsSinceEpoch}',
    );

    return (user, tokens);
  }

  @override
  Future<(User, AuthTokens)> login(String username, String password) =>
      guard(() async {
        final res = await _dio.post('/auth/login', data: {
          'username': username.trim(),
          'password': password,
        });
        final rawData = res.data;
        final data = rawData is Map
            ? Map<String, dynamic>.from(rawData)
            : <String, dynamic>{};
        return _parseAuthResponse(data, fallbackUsername: username.trim());
      });

  @override
  Future<(User, AuthTokens)> register({
    required String username,
    required String password,
    required String fullName,
    required String email,
    required String role,
  }) =>
      guard(() async {
        final res = await _dio.post('/auth/register', data: {
          'username': username.trim(),
          'password': password,
          'fullName': fullName.trim(),
          'email': email.trim(),
          'role': role,
        });
        final rawData = res.data;
        final data = rawData is Map
            ? Map<String, dynamic>.from(rawData)
            : <String, dynamic>{};
        return _parseAuthResponse(
          data,
          fallbackUsername: username.trim(),
          fallbackFullName: fullName.trim(),
          fallbackEmail: email.trim(),
          fallbackRole: role,
        );
      });

  @override
  Future<AuthTokens> refreshToken(String refreshToken) => guard(() async {
        final res = await _dio.post('/auth/refresh', data: {
          'refreshToken': refreshToken,
          'refresh_token': refreshToken,
        });
        final rawData = res.data;
        final data = rawData is Map
            ? Map<String, dynamic>.from(rawData)
            : <String, dynamic>{};
        return AuthTokens(
          accessToken: data['accessToken'] as String? ??
              data['access_token'] as String? ??
              data['token'] as String? ??
              '',
          refreshToken: data['refreshToken'] as String? ??
              data['refresh_token'] as String? ??
              refreshToken,
        );
      });

  @override
  Future<User> getCurrentUser() => guard(() async {
        final res = await _dio.get('/auth/me');
        final rawData = res.data;
        final data = rawData is Map
            ? Map<String, dynamic>.from(rawData)
            : <String, dynamic>{};
        if (data['user'] is Map) {
          return User.fromJson(Map<String, dynamic>.from(data['user'] as Map));
        }
        return User.fromJson(data);
      });
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
