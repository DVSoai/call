part of 'contact_requests_bloc.dart';

@freezed
sealed class ContactRequestsEvent with _$ContactRequestsEvent {
  const factory ContactRequestsEvent.started() = ContactRequestsStarted;
  const factory ContactRequestsEvent.refreshed() = ContactRequestsRefreshed;

  /// accept=true → chấp nhận lời mời đến; accept=false → từ chối.
  const factory ContactRequestsEvent.responded({
    required String contactId,
    required bool accept,
  }) = ContactRequestsResponded;

  /// Huỷ lời mời đã gửi đi (chưa được phản hồi).
  const factory ContactRequestsEvent.outgoingCancelled({required String contactId}) =
      ContactRequestsOutgoingCancelled;
}
