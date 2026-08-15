import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/base/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/message_repository.dart';

class AddParticipantsParams extends Equatable {
  final String conversationId;
  final List<String> userIds;

  const AddParticipantsParams({required this.conversationId, required this.userIds});

  @override
  List<Object?> get props => [conversationId, userIds];
}

class AddParticipantsUseCase implements UseCase<Unit, AddParticipantsParams> {
  AddParticipantsUseCase(this._repository);

  final MessageRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(AddParticipantsParams params) =>
      _repository.addParticipants(conversationId: params.conversationId, userIds: params.userIds);
}
