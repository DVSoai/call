import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../utils/app_logger.dart';
import 'auth_interceptor.dart';
import 'force_logout_interceptor.dart';

/// Factory tạo [Dio] instance dùng chung toàn app — 1 baseUrl, 1 bộ
/// interceptor (auth + force-logout + log), đăng ký qua service_locator
/// thay vì new Dio() rải rác ở từng repository.
class DioClient {
  static Dio create(AuthInterceptor authInterceptor, ForceLogoutInterceptor forceLogoutInterceptor) {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          // Tránh ngrok free tier chèn trang cảnh báo HTML thay vì forward
          // thẳng request — chỉ ảnh hưởng khi test qua tunnel, vô hại với
          // domain thật (server bỏ qua header lạ).
          'ngrok-skip-browser-warning': 'true',
        },
      ),
    );

    dio.interceptors.add(authInterceptor);
    // Đăng ký SAU authInterceptor nhưng TRƯỚC log interceptor — thứ tự
    // interceptor lỗi (onError) trong Dio chạy đúng theo thứ tự add().
    dio.interceptors.add(forceLogoutInterceptor);

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => AppLogger.d(obj),
        ),
      );
    }

    return dio;
  }
}
