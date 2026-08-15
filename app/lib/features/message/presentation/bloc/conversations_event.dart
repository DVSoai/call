part of 'conversations_bloc.dart';

@freezed
sealed class ConversationsEvent with _$ConversationsEvent {
  const factory ConversationsEvent.started() = ConversationsStarted;
  const factory ConversationsEvent.refreshed() = ConversationsRefreshed;
  const factory ConversationsEvent.loadMoreRequested() = ConversationsLoadMoreRequested;
  const factory ConversationsEvent.messageArrived(ChatMessageEntity message) = ConversationsMessageArrived;
}
