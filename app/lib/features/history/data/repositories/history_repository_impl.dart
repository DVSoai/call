import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/base/failure.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../domain/entities/call_history_entry.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/history_remote_data_source.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  HistoryRepositoryImpl(this._remote);

  final HistoryRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<CallHistoryEntry>>> getCallHistory({
    required int limit,
    required int offset,
  }) async {
    try {
      final models = await _remote.getCallHistory(limit: limit, offset: offset);
      return Right(models);
    } on DioException catch (e) {
      return Left(Failure(AppException.fromDioException(e).message));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}
