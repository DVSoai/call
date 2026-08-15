import 'package:dio/dio.dart';

import '../../domain/entities/conversation_entity.dart';
import '../models/chat_message_model.dart';
import '../models/conversation_model.dart';

class MessageRemoteDataSource {
  MessageRemoteDataSource(this._dio);

  final Dio _dio;

  Future<ConversationModel> createConversation({
    required ConversationType type,
    required List<String> participantIds,
    String? name,
  }) async {
    final res = await _dio.post('/conversations', data: {
      'type': type.apiValue,
      'participantIds': participantIds,
      if (name != null) 'name': name,
    });
    return ConversationModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<ConversationModel>> listConversations({required int limit, required int offset}) async {
    final res = await _dio.get('/conversations', queryParameters: {'limit': limit, 'offset': offset});
    final data = res.data as Map<String, dynamic>;
    final conversations = data['conversations'] as List;
    return conversations.map((e) => ConversationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ChatMessageModel>> listMessages({
    required String conversationId,
    required int limit,
    required int offset,
  }) async {
    final res = await _dio.get(
      '/conversations/$conversationId/messages',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    final data = res.data as Map<String, dynamic>;
    final messages = data['messages'] as List;
    return messages.map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> addParticipants({required String conversationId, required List<String> userIds}) async {
    await _dio.post('/conversations/$conversationId/participants', data: {'userIds': userIds});
  }

  Future<void> leaveConversation(String conversationId) async {
    await _dio.delete('/conversations/$conversationId/participants/me');
  }
}
