import 'package:equatable/equatable.dart';

/// Chỉ có "text" ở bản hiện tại — ảnh/file dành cho giai đoạn sau (xem
/// backend/internal/entity/conversation.go: MessageTypeText). Vẫn dùng enum
/// (thay vì String) để mở rộng sau này không phải sửa lại kiểu dữ liệu.
enum ChatMessageType {
  text('text', 'Văn bản');

  const ChatMessageType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static ChatMessageType fromJson(String value) => ChatMessageType.values.firstWhere(
        (t) => t.apiValue == value,
        orElse: () => throw ArgumentError('ChatMessageType không hợp lệ: $value'),
      );
}

class ChatMessageEntity extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final ChatMessageType messageType;
  final String content;
  final DateTime createdAt;

  const ChatMessageEntity({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.messageType,
    required this.content,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, conversationId, senderId, messageType, content, createdAt];
}
