import 'package:fpdart/fpdart.dart';

import '../../../../core/base/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/message_repository.dart';

class LeaveConversationUseCase implements UseCase<Unit, String> {
  LeaveConversationUseCase(this._repository);

  final MessageRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String conversationId) => _repository.leaveConversation(conversationId);
}
