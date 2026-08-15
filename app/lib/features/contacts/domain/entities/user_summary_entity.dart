import 'package:equatable/equatable.dart';

/// Thông tin rút gọn của 1 user — dùng cho kết quả tìm kiếm theo số điện
/// thoại và cho "otherUser" trong [ContactEntity].
class UserSummaryEntity extends Equatable {
  final String id;
  final String phone;
  final String displayName;

  const UserSummaryEntity({
    required this.id,
    required this.phone,
    required this.displayName,
  });

  @override
  List<Object?> get props => [id, phone, displayName];
}
