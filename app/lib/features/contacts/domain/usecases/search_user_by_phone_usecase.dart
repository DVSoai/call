import 'package:fpdart/fpdart.dart';

import '../../../../core/base/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_summary_entity.dart';
import '../repositories/contacts_repository.dart';

class SearchUserByPhoneUseCase implements UseCase<UserSummaryEntity, String> {
  SearchUserByPhoneUseCase(this._repository);

  final ContactsRepository _repository;

  @override
  Future<Either<Failure, UserSummaryEntity>> call(String phone) => _repository.searchByPhone(phone);
}
