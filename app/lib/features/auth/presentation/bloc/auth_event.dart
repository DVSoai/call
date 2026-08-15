part of 'auth_bloc.dart';

@freezed
sealed class AuthEvent with _$AuthEvent {
  /// Kiểm tra token đã lưu lúc app khởi động — quyết định vào thẳng Home
  /// hay ra LoginPage.
  const factory AuthEvent.sessionCheckRequested() = AuthSessionCheckRequested;

  const factory AuthEvent.loginSubmitted({required String phone}) = AuthLoginSubmitted;

  const factory AuthEvent.loggedOut() = AuthLoggedOut;
}
