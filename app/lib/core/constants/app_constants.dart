import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Cấu hình trỏ tới callserver (Golang) — đọc từ file `.env` ở root app
/// (copy từ `.env.example`, xem app/README hoặc file đó để biết cách sửa
/// khi chạy Android emulator/thiết bị thật). `dotenv.load()` phải chạy
/// trước (xem main.dart) nên các field ở đây KHÔNG còn là `const`.
abstract class AppConstants {
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080';
  static String get wsBaseUrl => dotenv.env['WS_BASE_URL'] ?? 'ws://localhost:8080';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}
