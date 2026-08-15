import 'package:dio/dio.dart';

/// Exception chuẩn hoá — data layer (repository impl) bắt [DioException]
/// và convert sang [AppException] trước khi map tiếp sang [Failure] ở
/// usecase/repository boundary.
class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, {this.statusCode});

  factory AppException.fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AppException('Kết nối tới server quá thời gian chờ');
      case DioExceptionType.connectionError:
        return const AppException('Không thể kết nối tới server — kiểm tra mạng');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode != null && statusCode >= 500 && _looksLikeHtmlErrorPage(e.response)) {
          // 5xx từ reverse proxy (nginx/caddy) khi deploy thật thường trả
          // trang lỗi HTML thay vì JSON — hiện thông báo thân thiện thay
          // vì dump nguyên đoạn HTML lên UI.
          return const AppException('Hệ thống tạm thời không khả dụng, thử lại sau');
        }
        final data = e.response?.data;
        final serverMessage = (data is Map && data['error'] is String) ? data['error'] as String : null;
        return AppException(
          serverMessage ?? 'Server trả về lỗi ($statusCode)',
          statusCode: statusCode,
        );
      case DioExceptionType.cancel:
        return const AppException('Request đã bị huỷ');
      default:
        return AppException(e.message ?? 'Lỗi mạng không xác định');
    }
  }

  @override
  String toString() => message;
}

bool _looksLikeHtmlErrorPage(Response? response) {
  final contentType = response?.headers.value('content-type') ?? '';
  if (contentType.contains('text/html')) return true;
  final data = response?.data;
  if (data is String) {
    return RegExp(r'^\s*<(!DOCTYPE|html)', caseSensitive: false).hasMatch(data);
  }
  return false;
}
