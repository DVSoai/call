import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/base/failure.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/network/signaling_service.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/repositories/message_repository.dart';
import '../datasources/message_remote_data_source.dart';
import '../models/chat_message_model.dart';

class MessageRepositoryImpl implements MessageRepository {
  MessageRepositoryImpl(this._remote, this._signaling);

  final MessageRemoteDataSource _remote;
  final SignalingService _signaling;

  @override
  Future<Either<Failure, ConversationEntity>> createConversation({
    required ConversationType type,
    required List<String> participantIds,
    String? name,
  }) async {
    try {
      final model = await _remote.createConversation(type: type, participantIds: participantIds, name: name);
      return Right(model);
    } on DioException catch (e) {
      return Left(Failure(AppException.fromDioException(e).message));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ConversationEntity>>> listConversations({
    required int limit,
    required int offset,
  }) async {
    try {
      return Right(await _remote.listConversations(limit: limit, offset: offset));
    } on DioException catch (e) {
      return Left(Failure(AppException.fromDioException(e).message));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ChatMessageEntity>>> listMessages({
    required String conversationId,
    required int limit,
    required int offset,
  }) async {
    try {
      return Right(await _remote.listMessages(conversationId: conversationId, limit: limit, offset: offset));
    } on DioException catch (e) {
      return Left(Failure(AppException.fromDioException(e).message));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> addParticipants({
    required String conversationId,
    required List<String> userIds,
  }) async {
    try {
      await _remote.addParticipants(conversationId: conversationId, userIds: userIds);
      return const Right(unit);
    } on DioException catch (e) {
      return Left(Failure(AppException.fromDioException(e).message));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> leaveConversation(String conversationId) async {
    try {
      await _remote.leaveConversation(conversationId);
      return const Right(unit);
    } on DioException catch (e) {
      return Left(Failure(AppException.fromDioException(e).message));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  void sendChatMessage({required String conversationId, required String text}) {
    _signaling.sendRaw({
      'type': 'chat-message',
      'conversationId': conversationId,
      'payload': {'text': text},
    });
  }

  @override
  Stream<ChatMessageEntity> get incomingMessages =>
      _signaling.chatMessages.map((json) => ChatMessageModel.fromSocketFrame(json));
}
