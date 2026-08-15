import 'package:dio/dio.dart';

import '../models/user_model.dart';

class DevLoginResult {
  const DevLoginResult({required this.token, required this.user});

  final String token;
  final UserModel user;
}

/// Gọi trực tiếp REST endpoint /auth/dev-login của callserver — không xử
/// lý lỗi ở đây, để nguyên DioException cho repository impl bắt và map
/// sang Failure.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<DevLoginResult> devLogin(String phone) async {
    final res = await _dio.post('/auth/dev-login', data: {'phone': phone});
    final data = res.data as Map<String, dynamic>;
    return DevLoginResult(
      token: data['token'] as String,
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  /// PUT /users/preferred-language — trả 204 No Content, không có body để
  /// parse (xem backend/internal/api/handlers_users.go).
  Future<void> updatePreferredLanguage(String language) async {
    await _dio.put('/users/preferred-language', data: {'language': language});
  }
}
