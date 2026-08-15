import 'package:fpdart/fpdart.dart';

import '../../../../core/base/failure.dart';
import '../entities/call_history_entry.dart';

abstract class HistoryRepository {
  Future<Either<Failure, List<CallHistoryEntry>>> getCallHistory({
    required int limit,
    required int offset,
  });
}
