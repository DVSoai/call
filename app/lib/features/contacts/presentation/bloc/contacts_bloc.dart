import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/bloc/abstract_bloc_with_api.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/contact_entity.dart';
import '../../domain/usecases/list_contacts_usecase.dart';
import '../../domain/usecases/remove_contact_usecase.dart';

part 'contacts_bloc.freezed.dart';
part 'contacts_event.dart';
part 'contacts_state.dart';

/// Danh sách bạn bè đã accepted (tab chính "Danh bạ"). Backend GET /contacts
/// không phân trang (xem [ListContactsUseCase]) nên KHÔNG dùng
/// [ListBlocMixin] ở đây — chỉ load-toàn-bộ + pull-to-refresh.
class ContactsBloc extends BlocWithApi<ContactsEvent, ContactsState> {
  ContactsBloc({
    required ListContactsUseCase listContactsUseCase,
    required RemoveContactUseCase removeContactUseCase,
  })  : _listContactsUseCase = listContactsUseCase,
        _removeContactUseCase = removeContactUseCase,
        super(const ContactsState()) {
    on<ContactsStarted>(_onStarted);
    on<ContactsRefreshed>(_onStarted);
    on<ContactsRemoved>(_onRemoved);
  }

  final ListContactsUseCase _listContactsUseCase;
  final RemoveContactUseCase _removeContactUseCase;

  Future<void> _onStarted(ContactsEvent event, Emitter<ContactsState> emit) async {
    emit(state.copyWith(status: ContactsStatus.loading));
    await callApi<List<ContactEntity>, NoParams>(
      useCase: _listContactsUseCase,
      param: const NoParams(),
      onSuccess: (items) async => emit(state.copyWith(status: ContactsStatus.success, items: items)),
      onFailure: (message) => emit(state.copyWith(status: ContactsStatus.failure, errorMessage: message)),
    );
  }

  Future<void> _onRemoved(ContactsRemoved event, Emitter<ContactsState> emit) async {
    await callApi<void, String>(
      useCase: _removeContactUseCase,
      param: event.contactId,
      onSuccess: (_) async {
        final remaining = state.items.where((c) => c.id != event.contactId).toList();
        emit(state.copyWith(items: remaining));
      },
      onFailure: (message) => emit(state.copyWith(errorMessage: message)),
    );
  }
}
