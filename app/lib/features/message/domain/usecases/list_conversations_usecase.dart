import 'package:fpdart/fpdart.dart';

import '../../../../core/base/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/conversation_entity.dart';
import '../repositories/message_repository.dart';

/// PageParams.page bắt đầu từ 1 (đúng quy ước [ListBlocMixin]) — usecase tự
/// quy đổi sang offset cho backend (offset = (page - 1) * limit).
class ListConversationsUseCase implements UseCase<List<ConversationEntity>, PageParams> {
  ListConversationsUseCase(this._repository);

  final MessageRepository _repository;

  @override
  Future<Either<Failure, List<ConversationEntity>>> call(PageParams params) => _repository.listConversations(
        limit: params.limit,
        offset: (params.page - 1) * params.limit,
      );
}
