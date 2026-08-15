import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/base/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/chat_message_entity.dart';
import '../repositories/message_repository.dart';

class ListMessagesParams extends Equatable {
  final String conversationId;
  final int page;
  final int limit;

  const ListMessagesParams({required this.conversationId, required this.page, required this.limit});

  @override
  List<Object?> get props => [conversationId, page, limit];
}

/// Backend trả message MỚI NHẤT trước (ORDER BY created_at DESC) — page 1 =
/// 50 tin gần nhất, page 2 = 50 tin cũ hơn tiếp theo... khớp tự nhiên với
/// hành vi "cuộn lên để xem tin cũ hơn" ở màn hình chat.
class ListMessagesUseCase implements UseCase<List<ChatMessageEntity>, ListMessagesParams> {
  ListMessagesUseCase(this._repository);

  final MessageRepository _repository;

  @override
  Future<Either<Failure, List<ChatMessageEntity>>> call(ListMessagesParams params) => _repository.listMessages(
        conversationId: params.conversationId,
        limit: params.limit,
        offset: (params.page - 1) * params.limit,
      );
}
