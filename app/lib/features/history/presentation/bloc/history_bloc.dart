import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/base/list_fetch_exception.dart';
import '../../../../core/bloc/abstract_bloc_with_api.dart';
import '../../../../core/bloc/list_bloc_mixin.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/call_history_entry.dart';
import '../../domain/usecases/get_call_history_usecase.dart';

part 'history_bloc.freezed.dart';
part 'history_event.dart';
part 'history_state.dart';

/// Kết hợp cả 2 base bắt buộc của app: [BlocWithApi] (gọi usecase qua
/// `Either<Failure,T>`) và [ListBlocMixin] (refresh/load-more) — usecase
/// trả Either đúng chuẩn Clean Architecture, [fetchData] unwrap Either rồi
/// throw để tương thích contract try/catch của ListBlocMixin.
class HistoryBloc extends BlocWithApi<HistoryEvent, HistoryState>
    with ListBlocMixin<CallHistoryEntry, HistoryState> {
  HistoryBloc({required GetCallHistoryUseCase getCallHistoryUseCase})
      : _getCallHistoryUseCase = getCallHistoryUseCase,
        super(const HistoryState()) {
    on<HistoryStarted>((event, emit) => loadInitial());
    on<HistoryRefreshed>((event, emit) => handleRefresh());
    on<HistoryLoadMoreRequested>((event, emit) => handleLoadMore());
  }

  final GetCallHistoryUseCase _getCallHistoryUseCase;

  @override
  Future<List<CallHistoryEntry>> fetchData(int page) async {
    final result = await _getCallHistoryUseCase.call(PageParams(page: page, limit: pageSize));
    return result.fold(
      (failure) => throw ListFetchException(failure.message),
      (items) => items,
    );
  }

  @override
  HistoryState buildLoadingState() => state.copyWith(status: HistoryStatus.loading);

  @override
  HistoryState buildSuccessState(List<CallHistoryEntry> items, {bool hasReachedMax = false}) =>
      state.copyWith(status: HistoryStatus.success, items: items, hasReachedMax: hasReachedMax);

  @override
  HistoryState buildErrorState(String error) => state.copyWith(status: HistoryStatus.failure, errorMessage: error);
}
