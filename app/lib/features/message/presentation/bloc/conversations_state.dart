part of 'conversations_bloc.dart';

enum ConversationsStatus { initial, loading, success, failure }

@freezed
sealed class ConversationsState with _$ConversationsState implements IListState<ConversationEntity> {
  const factory ConversationsState({
    @Default(ConversationsStatus.initial) ConversationsStatus status,
    @Default(<ConversationEntity>[]) List<ConversationEntity>? items,
    @Default(false) bool hasReachedMax,
    String? errorMessage,
  }) = _ConversationsState;
}
