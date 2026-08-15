import 'package:fpdart/fpdart.dart';

import '../../../../core/base/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/call_repository.dart';

class JoinGroupCallUseCase implements UseCase<void, String> {
  JoinGroupCallUseCase(this._repository);

  final CallRepository _repository;

  @override
  Future<Either<Failure, void>> call(String roomId) => _repository.joinGroupCall(roomId);
}
