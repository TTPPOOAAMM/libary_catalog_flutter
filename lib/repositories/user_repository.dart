import 'package:dio/dio.dart';
import '../core/api_exceptions.dart';
import '../core/permissions.dart';
import '../models/user.dart';

abstract class UserRepository {
  Future<List<User>> find();
  Future<User> updateRole(int userId, UserRole newRole);
  Future<void> delete(int userId);
}

class ApiUserRepository implements UserRepository {
  final Dio _dio;
  ApiUserRepository(this._dio);

  @override
  Future<List<User>> find() => guard(() async {
        final res = await _dio.get('/users');
        final data = res.data;
        final list = (data is Map && data['items'] is List)
            ? data['items'] as List
            : (data is List ? data : const []);
        return list
            .whereType<Map<String, dynamic>>()
            .map(User.fromJson)
            .toList();
      });

  @override
  Future<User> updateRole(int userId, UserRole newRole) => guard(() async {
        final res = await _dio.put('/users/$userId/role', data: {
          'role': newRole.code,
        });
        return User.fromJson(res.data as Map<String, dynamic>);
      });

  @override
  Future<void> delete(int userId) => guard(() => _dio.delete('/users/$userId'));
}
