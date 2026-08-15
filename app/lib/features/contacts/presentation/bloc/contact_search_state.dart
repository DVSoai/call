part of 'contact_search_bloc.dart';

enum ContactSearchStatus { idle, searching, found, notFound }

@freezed
sealed class ContactSearchState with _$ContactSearchState {
  const factory ContactSearchState({
    @Default(ContactSearchStatus.idle) ContactSearchStatus status,
    UserSummaryEntity? result,
    @Default(false) bool sending,
    @Default(false) bool requestSent,
    String? errorMessage,
  }) = _ContactSearchState;
}
