import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/base/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/conversation_entity.dart';
import '../repositories/message_repository.dart';

class CreateConversationParams extends Equatable {
  final ConversationType type;
  final List<String> participantIds;
  final String? name;

  const CreateConversationParams({
    required this.type,
    required this.participantIds,
    this.name,
  });

  @override
  List<Object?> get props => [type, participantIds, name];
}

class CreateConversationUseCase implements UseCase<ConversationEntity, CreateConversationParams> {
  CreateConversationUseCase(this._repository);

  final MessageRepository _repository;

  @override
  Future<Either<Failure, ConversationEntity>> call(CreateConversationParams params) => _repository.createConversation(
        type: params.type,
        participantIds: params.participantIds,
        name: params.name,
      );
}
