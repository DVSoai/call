import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Interface bắt buộc State phải implement để dùng chung với [ListBlocMixin]
/// (vd. `HistoryState implements IListState<CallHistoryEntry>`).
abstract class IListState<T> {
  List<T>? get items;
  bool get hasReachedMax;
}

/// Mixin cho Bloc có danh sách hỗ trợ pull-to-refresh + load-more qua
/// [EasyRefreshController]. Bloc con chỉ cần implement fetchData() +
/// 3 hàm dựng state (loading/success/error) — không phải viết lại logic
/// phân trang/refresh mỗi lần thêm 1 màn hình danh sách mới.
///
/// ```dart
/// class HistoryBloc extends BlocWithApi<HistoryEvent, HistoryState>
///     with ListBlocMixin<CallHistoryEntry, HistoryState> {
///   HistoryBloc(this._repo) : super(const HistoryState()) {
///     on<HistoryStarted>((event, emit) => loadInitial());
///     on<HistoryRefreshed>((event, emit) => handleRefresh());
///     on<HistoryLoadMoreRequested>((event, emit) => handleLoadMore());
///   }
///   final HistoryRepository _repo;
///
///   @override
///   Future<List<CallHistoryEntry>> fetchData(int page) =>
///       _repo.getCallHistory(page: page, limit: pageSize);
/// }
/// ```
mixin ListBlocMixin<T, S extends IListState<T>> on BlocBase<S> {
  final EasyRefreshController refreshController = EasyRefreshController(
    controlFinishRefresh: true,
    controlFinishLoad: true,
  );

  int _page = 1;
  int pageSize = 20;

  int get currentPage => _page;

  /// Override để fetch 1 trang dữ liệu từ repository — throw exception
  /// (không phải trả Either) nếu lỗi, mixin tự bắt ở try/catch bên dưới.
  Future<List<T>> fetchData(int page);

  S buildLoadingState();
  S buildSuccessState(List<T> items, {bool hasReachedMax = false});
  S buildErrorState(String error);

  Future<void> loadInitial() async {
    if (isClosed) return;
    emit(buildLoadingState());
    _page = 1;
    try {
      final items = await fetchData(_page);
      if (isClosed) return;
      emit(buildSuccessState(items, hasReachedMax: items.length < pageSize));
    } catch (e) {
      if (!isClosed) emit(buildErrorState(e.toString()));
    }
  }

  Future<void> handleRefresh() async {
    if (isClosed) return;
    _page = 1;
    try {
      final items = await fetchData(_page);
      if (isClosed) return;
      final reachedMax = items.length < pageSize;
      emit(buildSuccessState(items, hasReachedMax: reachedMax));
      refreshController.finishRefresh(IndicatorResult.success);
      if (reachedMax) {
        refreshController.finishLoad(IndicatorResult.noMore);
      } else {
        refreshController.resetFooter();
      }
    } catch (e) {
      if (!isClosed) emit(buildErrorState(e.toString()));
      refreshController.finishRefresh(IndicatorResult.fail);
    }
  }

  Future<void> handleLoadMore() async {
    if (isClosed) return;
    if (state.hasReachedMax) {
      refreshController.finishLoad(IndicatorResult.noMore);
      return;
    }
    try {
      _page++;
      final newItems = await fetchData(_page);
      if (isClosed) return;
      final reachedMax = newItems.length < pageSize;
      final current = List<T>.from(state.items ?? [])..addAll(newItems);
      emit(buildSuccessState(current, hasReachedMax: reachedMax));
      refreshController.finishLoad(
        reachedMax ? IndicatorResult.noMore : IndicatorResult.success,
      );
    } catch (e) {
      _page--;
      if (!isClosed) emit(buildErrorState(e.toString()));
      refreshController.finishLoad(IndicatorResult.fail);
    }
  }

  @override
  Future<void> close() {
    refreshController.dispose();
    return super.close();
  }
}
