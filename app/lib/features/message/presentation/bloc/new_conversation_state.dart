part of 'new_conversation_bloc.dart';

enum NewConversationStatus { idle, submitting, success, failure }

@freezed
sealed class NewConversationState with _$NewConversationState {
  const factory NewConversationState({
    @Default(NewConversationStatus.idle) NewConversationStatus status,
    @Default(<String>{}) Set<String> selectedUserIds,
    @Default('') String groupName,
    ConversationEntity? created,
    String? errorMessage,
  }) = _NewConversationState;
}
