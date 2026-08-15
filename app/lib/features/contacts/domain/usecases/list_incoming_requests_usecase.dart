import 'package:fpdart/fpdart.dart';

import '../../../../core/base/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/contact_entity.dart';
import '../repositories/contacts_repository.dart';

class ListIncomingRequestsUseCase implements UseCase<List<ContactEntity>, NoParams> {
  ListIncomingRequestsUseCase(this._repository);

  final ContactsRepository _repository;

  @override
  Future<Either<Failure, List<ContactEntity>>> call(NoParams params) => _repository.listIncomingRequests();
}
