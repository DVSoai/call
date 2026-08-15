part of 'contacts_bloc.dart';

enum ContactsStatus { initial, loading, success, failure }

@freezed
sealed class ContactsState with _$ContactsState {
  const factory ContactsState({
    @Default(ContactsStatus.initial) ContactsStatus status,
    @Default(<ContactEntity>[]) List<ContactEntity> items,
    String? errorMessage,
  }) = _ContactsState;
}
