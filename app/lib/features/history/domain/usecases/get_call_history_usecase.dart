import 'package:fpdart/fpdart.dart';

import '../../../../core/base/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/call_history_entry.dart';
import '../repositories/history_repository.dart';

/// PageParams.page bắt đầu từ 1 (đúng quy ước [ListBlocMixin]) — usecase
/// tự quy đổi sang offset cho backend (offset = (page - 1) * limit).
class GetCallHistoryUseCase implements UseCase<List<CallHistoryEntry>, PageParams> {
  GetCallHistoryUseCase(this._repository);

  final HistoryRepository _repository;

  @override
  Future<Either<Failure, List<CallHistoryEntry>>> call(PageParams params) => _repository.getCallHistory(
        limit: params.limit,
        offset: (params.page - 1) * params.limit,
      );
}
