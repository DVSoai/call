import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/bloc/abstract_bloc_with_api.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/usecases/create_conversation_usecase.dart';

part 'new_conversation_bloc.freezed.dart';
part 'new_conversation_event.dart';
part 'new_conversation_state.dart';

/// Màn hình chọn bạn bè để bắt đầu hội thoại — chọn đúng 1 người → tạo
/// (hoặc tái sử dụng) conversation type "direct"; chọn từ 2 người trở lên
/// → tạo "group" (kèm tên nhóm tuỳ chọn). Toàn bộ participantIds đưa vào
/// đều đã là contact accepted (danh sách nguồn lấy từ ContactsBloc) nên
/// luôn qua được rule "kết bạn mới nhắn tin được" ở backend.
class NewConversationBloc extends BlocWithApi<NewConversationEvent, NewConversationState> {
  NewConversationBloc({required CreateConversationUseCase createConversationUseCase})
      : _createConversationUseCase = createConversationUseCase,
        super(const NewConversationState()) {
    on<NewConversationContactToggled>(_onContactToggled);
    on<NewConversationGroupNameChanged>(_onGroupNameChanged);
    on<NewConversationSubmitted>(_onSubmitted);
  }

  final CreateConversationUseCase _createConversationUseCase;

  void _onContactToggled(NewConversationContactToggled event, Emitter<NewConversationState> emit) {
    final selected = Set<String>.from(state.selectedUserIds);
    if (!selected.add(event.userId)) selected.remove(event.userId);
    emit(state.copyWith(selectedUserIds: selected));
  }

  void _onGroupNameChanged(NewConversationGroupNameChanged event, Emitter<NewConversationState> emit) {
    emit(state.copyWith(groupName: event.name));
  }

  Future<void> _onSubmitted(NewConversationSubmitted event, Emitter<NewConversationState> emit) async {
    if (state.selectedUserIds.isEmpty) return;
    emit(state.copyWith(status: NewConversationStatus.submitting));

    final type = state.selectedUserIds.length == 1 ? ConversationType.direct : ConversationType.group;
    await callApi<ConversationEntity, CreateConversationParams>(
      useCase: _createConversationUseCase,
      param: CreateConversationParams(
        type: type,
        participantIds: state.selectedUserIds.toList(),
        name: type == ConversationType.group && state.groupName.trim().isNotEmpty ? state.groupName.trim() : null,
      ),
      onSuccess: (conv) async => emit(state.copyWith(status: NewConversationStatus.success, created: conv)),
      onFailure: (message) => emit(state.copyWith(status: NewConversationStatus.failure, errorMessage: message)),
    );
  }
}
