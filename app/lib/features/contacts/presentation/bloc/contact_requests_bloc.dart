import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/bloc/abstract_bloc_with_api.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/contact_entity.dart';
import '../../domain/usecases/list_incoming_requests_usecase.dart';
import '../../domain/usecases/list_outgoing_requests_usecase.dart';
import '../../domain/usecases/remove_contact_usecase.dart';
import '../../domain/usecases/respond_contact_request_usecase.dart';

part 'contact_requests_bloc.freezed.dart';
part 'contact_requests_event.dart';
part 'contact_requests_state.dart';

/// Màn hình "Lời mời kết bạn" — gộp cả 2 chiều (incoming/outgoing) trong 1
/// Bloc vì cùng vòng đời (1 màn hình, load cùng lúc). Backend không phân
/// trang endpoint này — giống [ContactsBloc], không dùng [ListBlocMixin].
class ContactRequestsBloc extends BlocWithApi<ContactRequestsEvent, ContactRequestsState> {
  ContactRequestsBloc({
    required ListIncomingRequestsUseCase listIncomingRequestsUseCase,
    required ListOutgoingRequestsUseCase listOutgoingRequestsUseCase,
    required RespondContactRequestUseCase respondContactRequestUseCase,
    required RemoveContactUseCase removeContactUseCase,
  })  : _listIncomingRequestsUseCase = listIncomingRequestsUseCase,
        _listOutgoingRequestsUseCase = listOutgoingRequestsUseCase,
        _respondContactRequestUseCase = respondContactRequestUseCase,
        _removeContactUseCase = removeContactUseCase,
        super(const ContactRequestsState()) {
    on<ContactRequestsStarted>(_onStarted);
    on<ContactRequestsRefreshed>(_onStarted);
    on<ContactRequestsResponded>(_onResponded);
    on<ContactRequestsOutgoingCancelled>(_onOutgoingCancelled);
  }

  final ListIncomingRequestsUseCase _listIncomingRequestsUseCase;
  final ListOutgoingRequestsUseCase _listOutgoingRequestsUseCase;
  final RespondContactRequestUseCase _respondContactRequestUseCase;
  final RemoveContactUseCase _removeContactUseCase;

  Future<void> _onStarted(ContactRequestsEvent event, Emitter<ContactRequestsState> emit) async {
    emit(state.copyWith(status: ContactRequestsStatus.loading));

    final incomingResult = await _listIncomingRequestsUseCase.call(const NoParams());
    final outgoingResult = await _listOutgoingRequestsUseCase.call(const NoParams());
    if (isClosed) return;

    final incoming = incomingResult.getOrElse((_) => const []);
    final outgoing = outgoingResult.getOrElse((_) => const []);
    final failure = incomingResult.isLeft() || outgoingResult.isLeft();

    if (failure) {
      final message = incomingResult.fold((f) => f.message, (_) => null) ??
          outgoingResult.fold((f) => f.message, (_) => null) ??
          'Có lỗi xảy ra';
      emit(state.copyWith(status: ContactRequestsStatus.failure, errorMessage: message));
      return;
    }
    emit(state.copyWith(status: ContactRequestsStatus.success, incoming: incoming, outgoing: outgoing));
  }

  Future<void> _onResponded(ContactRequestsResponded event, Emitter<ContactRequestsState> emit) async {
    await callApi<void, RespondContactRequestParams>(
      useCase: _respondContactRequestUseCase,
      param: RespondContactRequestParams(contactId: event.contactId, accept: event.accept),
      onSuccess: (_) async {
        final remaining = state.incoming.where((c) => c.id != event.contactId).toList();
        emit(state.copyWith(incoming: remaining));
      },
      onFailure: (message) => emit(state.copyWith(errorMessage: message)),
    );
  }

  Future<void> _onOutgoingCancelled(ContactRequestsOutgoingCancelled event, Emitter<ContactRequestsState> emit) async {
    await callApi<void, String>(
      useCase: _removeContactUseCase,
      param: event.contactId,
      onSuccess: (_) async {
        final remaining = state.outgoing.where((c) => c.id != event.contactId).toList();
        emit(state.copyWith(outgoing: remaining));
      },
      onFailure: (message) => emit(state.copyWith(errorMessage: message)),
    );
  }
}
