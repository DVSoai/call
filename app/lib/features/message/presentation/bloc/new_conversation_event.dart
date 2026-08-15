part of 'new_conversation_bloc.dart';

@freezed
sealed class NewConversationEvent with _$NewConversationEvent {
  const factory NewConversationEvent.contactToggled(String userId) = NewConversationContactToggled;
  const factory NewConversationEvent.groupNameChanged(String name) = NewConversationGroupNameChanged;
  const factory NewConversationEvent.submitted() = NewConversationSubmitted;
}
