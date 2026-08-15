import 'package:fpdart/fpdart.dart';

import '../../../../core/base/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/call_repository.dart';

class CreateGroupCallParams {
  const CreateGroupCallParams({
    required this.participantIds,
    required this.callType,
    this.conversationId,
  });

  final List<String> participantIds;
  final String callType;

  /// Truyền conversationId (group chat gốc) để Server nhận ra "group này
  /// đang có cuộc gọi sống" và JOIN LẠI thay vì tạo room mới — thiếu field
  /// này thì mỗi lần bấm "Gọi nhóm" luôn tạo 1 room mới (xem
  /// Hub.CreateGroupCall).
  final String? conversationId;
}

class CreateGroupCallUseCase implements UseCase<String, CreateGroupCallParams> {
  CreateGroupCallUseCase(this._repository);

  final CallRepository _repository;

  @override
  Future<Either<Failure, String>> call(CreateGroupCallParams params) => _repository.createGroupCall(
        participantIds: params.participantIds,
        callType: params.callType,
        conversationId: params.conversationId,
      );
}
