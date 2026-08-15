import 'package:fpdart/fpdart.dart';

import '../../../../core/base/failure.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// Đăng nhập theo số điện thoại (POST /auth/dev-login), tự lưu JWT vào
  /// secure storage khi thành công — xem docs/CALL_SYSTEM.md §4.5.
  Future<Either<Failure, UserEntity>> devLogin(String phone);

  Future<String?> getSavedToken();

  /// Đọc thông tin user đã lưu cục bộ lúc login gần nhất — dùng để khôi
  /// phục UI (ProfilePage) khi mở lại app mà không cần gọi API (backend
  /// chưa có endpoint GET /me).
  Future<UserEntity?> getSavedUser();

  Future<void> logout();
}
