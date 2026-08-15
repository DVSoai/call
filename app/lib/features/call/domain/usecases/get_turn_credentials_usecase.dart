import 'package:fpdart/fpdart.dart';

import '../../../../core/base/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/turn_credentials.dart';
import '../repositories/call_repository.dart';

class GetTurnCredentialsUseCase implements UseCase<TurnCredentials, NoParams> {
  GetTurnCredentialsUseCase(this._repository);

  final CallRepository _repository;

  @override
  Future<Either<Failure, TurnCredentials>> call(NoParams params) => _repository.getTurnCredentials();
}
