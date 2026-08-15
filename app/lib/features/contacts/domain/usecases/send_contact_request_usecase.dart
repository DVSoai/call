import 'package:fpdart/fpdart.dart';

import '../../../../core/base/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/contacts_repository.dart';

/// Params = addresseeId của user muốn kết bạn (lấy từ kết quả
/// [SearchUserByPhoneUseCase]).
class SendContactRequestUseCase implements UseCase<Unit, String> {
  SendContactRequestUseCase(this._repository);

  final ContactsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String addresseeId) => _repository.sendRequest(addresseeId);
}
