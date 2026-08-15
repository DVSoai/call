part of 'contact_search_bloc.dart';

@freezed
sealed class ContactSearchEvent with _$ContactSearchEvent {
  const factory ContactSearchEvent.submitted({required String phone}) = ContactSearchSubmitted;
  const factory ContactSearchEvent.requestSendRequested() = ContactSearchRequestSendRequested;
}
