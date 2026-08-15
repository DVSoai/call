import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// Tự động đính kèm header `Authorization: Bearer <token>` cho mọi request
/// — tương ứng middleware RequireAuth() phía backend (internal/auth).
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStorage);

  final TokenStorage _tokenStorage;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokenStorage.readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
