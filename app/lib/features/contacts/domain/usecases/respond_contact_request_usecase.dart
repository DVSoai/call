import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/base/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/contacts_repository.dart';

class RespondContactRequestParams extends Equatable {
  final String contactId;
  final bool accept;

  const RespondContactRequestParams({required this.contactId, required this.accept});

  @override
  List<Object?> get props => [contactId, accept];
}

class RespondContactRequestUseCase implements UseCase<Unit, RespondContactRequestParams> {
  RespondContactRequestUseCase(this._repository);

  final ContactsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(RespondContactRequestParams params) =>
      _repository.respondRequest(contactId: params.contactId, accept: params.accept);
}
