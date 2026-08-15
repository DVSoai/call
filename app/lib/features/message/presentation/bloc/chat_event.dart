part of 'chat_bloc.dart';

@freezed
sealed class ChatEvent with _$ChatEvent {
  const factory ChatEvent.started() = ChatStarted;
  const factory ChatEvent.olderRequested() = ChatOlderRequested;
  const factory ChatEvent.sendRequested({required String text}) = ChatSendRequested;
  const factory ChatEvent.messageReceived(ChatMessageEntity message) = ChatMessageReceived;
}
