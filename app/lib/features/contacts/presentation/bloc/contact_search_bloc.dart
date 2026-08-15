import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/bloc/abstract_bloc_with_api.dart';
import '../../domain/entities/user_summary_entity.dart';
import '../../domain/usecases/search_user_by_phone_usecase.dart';
import '../../domain/usecases/send_contact_request_usecase.dart';

part 'contact_search_bloc.freezed.dart';
part 'contact_search_event.dart';
part 'contact_search_state.dart';

/// Màn hình tìm bạn theo số điện thoại + gửi lời mời — 2 usecase độc lập,
/// tách biệt trạng thái tìm kiếm (found) và trạng thái gửi lời mời
/// (requestSent) để UI biết chính xác giai đoạn nào đang loading.
class ContactSearchBloc extends BlocWithApi<ContactSearchEvent, ContactSearchState> {
  ContactSearchBloc({
    required SearchUserByPhoneUseCase searchUserByPhoneUseCase,
    required SendContactRequestUseCase sendContactRequestUseCase,
  })  : _searchUserByPhoneUseCase = searchUserByPhoneUseCase,
        _sendContactRequestUseCase = sendContactRequestUseCase,
        super(const ContactSearchState()) {
    on<ContactSearchSubmitted>(_onSearchSubmitted);
    on<ContactSearchRequestSendRequested>(_onSendRequested);
  }

  final SearchUserByPhoneUseCase _searchUserByPhoneUseCase;
  final SendContactRequestUseCase _sendContactRequestUseCase;

  Future<void> _onSearchSubmitted(ContactSearchSubmitted event, Emitter<ContactSearchState> emit) async {
    emit(state.copyWith(status: ContactSearchStatus.searching, result: null, requestSent: false));
    await callApi<UserSummaryEntity, String>(
      useCase: _searchUserByPhoneUseCase,
      param: event.phone,
      onSuccess: (user) async => emit(state.copyWith(status: ContactSearchStatus.found, result: user)),
      onFailure: (message) => emit(state.copyWith(status: ContactSearchStatus.notFound, errorMessage: message)),
    );
  }

  Future<void> _onSendRequested(ContactSearchRequestSendRequested event, Emitter<ContactSearchState> emit) async {
    final target = state.result;
    if (target == null) return;
    emit(state.copyWith(sending: true));
    await callApi<void, String>(
      useCase: _sendContactRequestUseCase,
      param: target.id,
      onSuccess: (_) async => emit(state.copyWith(sending: false, requestSent: true)),
      onFailure: (message) => emit(state.copyWith(sending: false, errorMessage: message)),
    );
  }
}
