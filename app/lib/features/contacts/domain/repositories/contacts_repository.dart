import 'package:fpdart/fpdart.dart';

import '../../../../core/base/failure.dart';
import '../entities/contact_entity.dart';
import '../entities/user_summary_entity.dart';

abstract class ContactsRepository {
  Future<Either<Failure, UserSummaryEntity>> searchByPhone(String phone);

  // POST /contacts/requests chỉ trả về {id, status} (không đủ dữ liệu dựng
  // ContactEntity đầy đủ như otherUser/createdAt) — trả Unit, màn hình
  // "Lời mời đã gửi" sẽ tự fetch lại qua listOutgoingRequests().
  Future<Either<Failure, Unit>> sendRequest(String addresseeId);

  Future<Either<Failure, List<ContactEntity>>> listIncomingRequests();

  Future<Either<Failure, List<ContactEntity>>> listOutgoingRequests();

  Future<Either<Failure, Unit>> respondRequest({
    required String contactId,
    required bool accept,
  });

  Future<Either<Failure, List<ContactEntity>>> listContacts();

  Future<Either<Failure, Unit>> removeContact(String contactId);
}
