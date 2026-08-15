import 'package:fpdart/fpdart.dart';

import '../../../../core/base/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/contact_entity.dart';
import '../repositories/contacts_repository.dart';

/// Backend GET /contacts KHÔNG hỗ trợ phân trang (trả toàn bộ danh sách bạn
/// bè đã accepted 1 lần — khác với call history/messages) — usecase dùng
/// [NoParams], không dùng [ListBlocMixin] ở tầng Bloc cho danh sách này.
class ListContactsUseCase implements UseCase<List<ContactEntity>, NoParams> {
  ListContactsUseCase(this._repository);

  final ContactsRepository _repository;

  @override
  Future<Either<Failure, List<ContactEntity>>> call(NoParams params) => _repository.listContacts();
}
