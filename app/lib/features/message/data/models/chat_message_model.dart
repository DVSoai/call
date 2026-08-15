import '../../domain/entities/chat_message_entity.dart';

class ChatMessageModel extends ChatMessageEntity {
  const ChatMessageModel({
    required super.id,
    required super.conversationId,
    required super.senderId,
    required super.messageType,
    required super.content,
    required super.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) => ChatMessageModel(
        id: json['id'] as String,
        conversationId: json['conversationId'] as String,
        senderId: json['senderId'] as String,
        messageType: ChatMessageType.fromJson(json['messageType'] as String),
        content: json['content'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  /// Parse frame thô nhận từ WebSocket (type "chat-message", xem
  /// backend/internal/signaling/message.go) — khác cấu trúc JSON của REST
  /// (messageResponse) nên cần factory riêng: field tên "text" thay vì
  /// "content", nằm trong "payload", "senderId" là "from" ở cấp message.
  factory ChatMessageModel.fromSocketFrame(Map<String, dynamic> json) {
    final payload = (json['payload'] as Map<String, dynamic>?) ?? const {};
    return ChatMessageModel(
      id: payload['messageId'] as String? ?? '',
      conversationId: json['conversationId'] as String? ?? '',
      senderId: json['from'] as String? ?? '',
      messageType: ChatMessageType.text,
      content: payload['text'] as String? ?? '',
      createdAt: DateTime.tryParse(payload['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
