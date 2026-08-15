part of 'history_bloc.dart';

@freezed
sealed class HistoryEvent with _$HistoryEvent {
  const factory HistoryEvent.started() = HistoryStarted;
  const factory HistoryEvent.refreshed() = HistoryRefreshed;
  const factory HistoryEvent.loadMoreRequested() = HistoryLoadMoreRequested;
}
