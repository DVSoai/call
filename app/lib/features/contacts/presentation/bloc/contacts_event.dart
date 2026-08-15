part of 'contacts_bloc.dart';

@freezed
sealed class ContactsEvent with _$ContactsEvent {
  const factory ContactsEvent.started() = ContactsStarted;
  const factory ContactsEvent.refreshed() = ContactsRefreshed;
  const factory ContactsEvent.removed({required String contactId}) = ContactsRemoved;
}
