import 'package:fpdart/fpdart.dart';

import '../../../../core/base/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/call_repository.dart';

class CreateGroupCallParams {
  const CreateGroupCallParams({required this.participantIds, required this.callType});

  final List<String> participantIds;
  final String callType;
}

class CreateGroupCallUseCase implements UseCase<String, CreateGroupCallParams> {
  CreateGroupCallUseCase(this._repository);

  final CallRepository _repository;

  @override
  Future<Either<Failure, String>> call(CreateGroupCallParams params) =>
      _repository.createGroupCall(participantIds: params.participantIds, callType: params.callType);
}
