import 'package:fpdart/fpdart.dart';

import '../../../../core/base/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/contact_entity.dart';
import '../repositories/contacts_repository.dart';

class ListOutgoingRequestsUseCase implements UseCase<List<ContactEntity>, NoParams> {
  ListOutgoingRequestsUseCase(this._repository);

  final ContactsRepository _repository;

  @override
  Future<Either<Failure, List<ContactEntity>>> call(NoParams params) => _repository.listOutgoingRequests();
}
