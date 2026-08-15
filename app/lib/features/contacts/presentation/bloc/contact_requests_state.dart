part of 'contact_requests_bloc.dart';

enum ContactRequestsStatus { initial, loading, success, failure }

@freezed
sealed class ContactRequestsState with _$ContactRequestsState {
  const factory ContactRequestsState({
    @Default(ContactRequestsStatus.initial) ContactRequestsStatus status,
    @Default(<ContactEntity>[]) List<ContactEntity> incoming,
    @Default(<ContactEntity>[]) List<ContactEntity> outgoing,
    String? errorMessage,
  }) = _ContactRequestsState;
}
