import 'package:fpdart/fpdart.dart';

import '../../../../core/base/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/contacts_repository.dart';

/// Params = contactId — dùng để unfriend (status accepted) hoặc huỷ lời
/// mời đã gửi (status pending).
class RemoveContactUseCase implements UseCase<Unit, String> {
  RemoveContactUseCase(this._repository);

  final ContactsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String contactId) => _repository.removeContact(contactId);
}
