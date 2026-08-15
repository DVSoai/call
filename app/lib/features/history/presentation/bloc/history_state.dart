part of 'history_bloc.dart';

enum HistoryStatus { initial, loading, success, failure }

@freezed
sealed class HistoryState with _$HistoryState implements IListState<CallHistoryEntry> {
  const factory HistoryState({
    @Default(HistoryStatus.initial) HistoryStatus status,
    @Default(<CallHistoryEntry>[]) List<CallHistoryEntry>? items,
    @Default(false) bool hasReachedMax,
    String? errorMessage,
  }) = _HistoryState;
}
