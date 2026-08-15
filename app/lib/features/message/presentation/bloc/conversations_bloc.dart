import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/base/list_fetch_exception.dart';
import '../../../../core/bloc/abstract_bloc_with_api.dart';
import '../../../../core/bloc/list_bloc_mixin.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/repositories/message_repository.dart';
import '../../domain/usecases/list_conversations_usecase.dart';

part 'conversations_bloc.freezed.dart';
part 'conversations_event.dart';
part 'conversations_state.dart';

/// Danh sách hội thoại (tab "Tin nhắn") — backend /conversations có phân
/// trang thật (khác /contacts) nên dùng [ListBlocMixin] như HistoryBloc.
/// Ngoài ra tự lắng nghe [MessageRepository.incomingMessages] để cập nhật
/// preview + đẩy hội thoại vừa có tin nhắn mới lên đầu danh sách real-time,
/// không cần user tự kéo-refresh.
class ConversationsBloc extends BlocWithApi<ConversationsEvent, ConversationsState>
    with ListBlocMixin<ConversationEntity, ConversationsState> {
  ConversationsBloc({
    required ListConversationsUseCase listConversationsUseCase,
    required MessageRepository repository,
  })  : _listConversationsUseCase = listConversationsUseCase,
        super(const ConversationsState()) {
    on<ConversationsStarted>((event, emit) => loadInitial());
    on<ConversationsRefreshed>((event, emit) => handleRefresh());
    on<ConversationsLoadMoreRequested>((event, emit) => handleLoadMore());
    on<ConversationsMessageArrived>(_onMessageArrived);

    _incomingSub = repository.incomingMessages.listen((m) => add(ConversationsEvent.messageArrived(m)));
  }

  final ListConversationsUseCase _listConversationsUseCase;
  late final StreamSubscription<ChatMessageEntity> _incomingSub;

  @override
  Future<List<ConversationEntity>> fetchData(int page) async {
    final result = await _listConversationsUseCase.call(PageParams(page: page, limit: pageSize));
    return result.fold(
      (failure) => throw ListFetchException(failure.message),
      (items) => items,
    );
  }

  void _onMessageArrived(ConversationsMessageArrived event, Emitter<ConversationsState> emit) {
    final items = state.items ?? const <ConversationEntity>[];
    final index = items.indexWhere((c) => c.id == event.message.conversationId);
    if (index == -1) return; // hội thoại mới do người khác tạo — sẽ thấy khi refresh

    final updated = items[index].copyWith(
      lastMessageAt: event.message.createdAt,
      lastMessagePreview: event.message.content,
    );
    final reordered = [updated, ...items.where((c) => c.id != updated.id)];
    emit(state.copyWith(items: reordered));
  }

  @override
  ConversationsState buildLoadingState() => state.copyWith(status: ConversationsStatus.loading);

  @override
  ConversationsState buildSuccessState(List<ConversationEntity> items, {bool hasReachedMax = false}) =>
      state.copyWith(status: ConversationsStatus.success, items: items, hasReachedMax: hasReachedMax);

  @override
  ConversationsState buildErrorState(String error) =>
      state.copyWith(status: ConversationsStatus.failure, errorMessage: error);

  @override
  Future<void> close() {
    _incomingSub.cancel();
    return super.close();
  }
}
