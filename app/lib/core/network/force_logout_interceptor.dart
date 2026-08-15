import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'session_expiry_notifier.dart';

/// Backend KHÔNG có refresh-token endpoint (JWT tĩnh 30 ngày — xem
/// backend/internal/auth/jwt.go), nên khác với app có refresh flow: nhận
/// 401/403 nghĩa là token thật sự hết hạn/không hợp lệ, không có gì để
/// retry — chỉ có thể xoá session cục bộ + báo AuthBloc điều hướng về
/// LoginPage qua [SessionExpiryNotifier].
class ForceLogoutInterceptor extends Interceptor {
  ForceLogoutInterceptor(this._tokenStorage, this._sessionExpiryNotifier);

  final TokenStorage _tokenStorage;
  final SessionExpiryNotifier _sessionExpiryNotifier;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) {
      _tokenStorage.clear();
      _sessionExpiryNotifier.notify();
    }
    handler.next(err);
  }
}
