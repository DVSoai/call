import 'package:fpdart/fpdart.dart';

import '../../../../core/base/failure.dart';
import '../entities/chat_message_entity.dart';
import '../entities/conversation_entity.dart';

abstract class MessageRepository {
  Future<Either<Failure, ConversationEntity>> createConversation({
    required ConversationType type,
    required List<String> participantIds,
    String? name,
  });

  Future<Either<Failure, List<ConversationEntity>>> listConversations({
    required int limit,
    required int offset,
  });

  Future<Either<Failure, List<ChatMessageEntity>>> listMessages({
    required String conversationId,
    required int limit,
    required int offset,
  });

  Future<Either<Failure, Unit>> addParticipants({
    required String conversationId,
    required List<String> userIds,
  });

  Future<Either<Failure, Unit>> leaveConversation(String conversationId);

  /// Gửi qua CHUNG 1 kết nối WebSocket với call signaling (xem
  /// core/network/signaling_service.dart) — fire-and-forget, không có
  /// Either/Failure vì không phải REST request. Bản chính thức (kèm id +
  /// createdAt do Server sinh) sẽ về qua [incomingMessages], kể cả cho
  /// chính người gửi (server echo — xem backend handlers_chat.go) nên
  /// Client không cần tự dựng optimistic message.
  void sendChatMessage({required String conversationId, required String text});

  Stream<ChatMessageEntity> get incomingMessages;
}
