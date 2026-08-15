import 'package:fpdart/fpdart.dart';

import '../../../../core/base/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class UpdatePreferredLanguageUseCase implements UseCase<UserEntity, String> {
  UpdatePreferredLanguageUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, UserEntity>> call(String language) => _repository.updatePreferredLanguage(language);
}
