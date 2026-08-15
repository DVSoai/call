import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/bloc/abstract_bloc_with_api.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/repositories/message_repository.dart';
import '../../domain/usecases/list_messages_usecase.dart';

part 'chat_bloc.freezed.dart';
part 'chat_event.dart';
part 'chat_state.dart';

/// 1 màn hình chat = 1 conversationId cố định suốt vòng đời Bloc (tạo mới
/// mỗi lần vào ChatPage, không phải app-lifetime singleton — xem
/// app_router.dart). Không optimistic-send: gửi xong chờ bản echo về qua
/// [MessageRepository.incomingMessages] (server luôn echo lại cho chính
/// người gửi — xem backend handlers_chat.go) rồi mới thêm vào danh sách,
/// tránh phải tự dedup giữa optimistic message và bản chính thức.
class ChatBloc extends BlocWithApi<ChatEvent, ChatState> {
  ChatBloc({
    required this.conversationId,
    required this.currentUserId,
    required ListMessagesUseCase listMessagesUseCase,
    required MessageRepository repository,
  })  : _listMessagesUseCase = listMessagesUseCase,
        _repository = repository,
        super(const ChatState()) {
    on<ChatStarted>(_onStarted);
    on<ChatOlderRequested>(_onOlderRequested);
    on<ChatSendRequested>(_onSendRequested);
    on<ChatMessageReceived>(_onMessageReceived);

    _incomingSub = repository.incomingMessages
        .where((m) => m.conversationId == conversationId)
        .listen((m) => add(ChatEvent.messageReceived(m)));
  }

  final String conversationId;
  final String currentUserId;
  final ListMessagesUseCase _listMessagesUseCase;
  final MessageRepository _repository;
  late final StreamSubscription<ChatMessageEntity> _incomingSub;

  static const _pageSize = 50;
  int _page = 1;

  Future<void> _onStarted(ChatStarted event, Emitter<ChatState> emit) async {
    emit(state.copyWith(status: ChatStatus.loading));
    _page = 1;
    await callApi<List<ChatMessageEntity>, ListMessagesParams>(
      useCase: _listMessagesUseCase,
      param: ListMessagesParams(conversationId: conversationId, page: _page, limit: _pageSize),
      onSuccess: (messages) async => emit(state.copyWith(
        status: ChatStatus.success,
        messages: messages,
        hasMoreOlder: messages.length >= _pageSize,
      )),
      onFailure: (message) => emit(state.copyWith(status: ChatStatus.failure, errorMessage: message)),
    );
  }

  Future<void> _onOlderRequested(ChatOlderRequested event, Emitter<ChatState> emit) async {
    if (!state.hasMoreOlder || state.loadingOlder) return;
    emit(state.copyWith(loadingOlder: true));
    final nextPage = _page + 1;
    await callApi<List<ChatMessageEntity>, ListMessagesParams>(
      useCase: _listMessagesUseCase,
      param: ListMessagesParams(conversationId: conversationId, page: nextPage, limit: _pageSize),
      onSuccess: (older) async {
        _page = nextPage;
        emit(state.copyWith(
          messages: [...state.messages, ...older],
          hasMoreOlder: older.length >= _pageSize,
          loadingOlder: false,
        ));
      },
      onFailure: (message) => emit(state.copyWith(loadingOlder: false, errorMessage: message)),
    );
  }

  void _onSendRequested(ChatSendRequested event, Emitter<ChatState> emit) {
    final text = event.text.trim();
    if (text.isEmpty) return;
    _repository.sendChatMessage(conversationId: conversationId, text: text);
  }

  void _onMessageReceived(ChatMessageReceived event, Emitter<ChatState> emit) {
    if (state.messages.any((m) => m.id == event.message.id)) return;
    emit(state.copyWith(messages: [event.message, ...state.messages]));
  }

  @override
  Future<void> close() {
    _incomingSub.cancel();
    return super.close();
  }
}
