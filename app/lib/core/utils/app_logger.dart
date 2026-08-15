import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Logger tập trung — chỉ in ra console ở debug mode. Không dùng
/// print()/debugPrint() rải rác trong code để dễ bật/tắt hoặc đổi sink
/// (Sentry, Crashlytics...) sau này ở đúng 1 chỗ.
abstract class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(methodCount: 1, errorMethodCount: 8, colors: true),
  );

  static void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) _logger.d(message, error: error, stackTrace: stackTrace);
  }

  static void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) _logger.i(message, error: error, stackTrace: stackTrace);
  }

  static void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) _logger.w(message, error: error, stackTrace: stackTrace);
  }

  static void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
