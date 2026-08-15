import 'package:equatable/equatable.dart';

import 'user_summary_entity.dart';

/// Các giá trị hợp lệ của [ContactEntity.status] — [apiValue] tách riêng
/// khỏi tên enum Dart nên đổi tên case không làm vỡ hợp đồng JSON với
/// backend (backend/internal/entity/contact.go). [label] dùng thẳng cho
/// UI, khỏi viết lại switch ở từng nơi hiển thị.
enum ContactStatus {
  pending('pending', 'Đang chờ'),
  accepted('accepted', 'Bạn bè'),
  rejected('rejected', 'Đã từ chối'),
  blocked('blocked', 'Đã chặn');

  const ContactStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static ContactStatus fromJson(String value) => ContactStatus.values.firstWhere(
        (s) => s.apiValue == value,
        orElse: () => throw ArgumentError('ContactStatus không hợp lệ: $value'),
      );
}

/// 1 quan hệ kết bạn (lời mời hoặc đã accepted) — [otherUser] luôn là
/// "người kia" trong quan hệ (không phải mình), đã được backend resolve
/// sẵn qua JOIN nên Client không cần tự tra cứu thêm.
class ContactEntity extends Equatable {
  final String id;
  final ContactStatus status;
  final String requesterId;
  final DateTime createdAt;
  final UserSummaryEntity otherUser;

  const ContactEntity({
    required this.id,
    required this.status,
    required this.requesterId,
    required this.createdAt,
    required this.otherUser,
  });

  @override
  List<Object?> get props => [id, status, requesterId, createdAt, otherUser];
}
