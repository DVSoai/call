part of 'chat_bloc.dart';

enum ChatStatus { initial, loading, success, failure }

@freezed
sealed class ChatState with _$ChatState {
  const factory ChatState({
    @Default(ChatStatus.initial) ChatStatus status,
    // Mới nhất trước (index 0 = tin mới nhất) — khớp thứ tự backend trả về,
    // render bằng ListView(reverse: true) ở ChatPage.
    @Default(<ChatMessageEntity>[]) List<ChatMessageEntity> messages,
    @Default(false) bool hasMoreOlder,
    @Default(false) bool loadingOlder,
    String? errorMessage,
  }) = _ChatState;
}
