part of 'call_bloc.dart';

enum CallStatus {
  /// Không có cuộc gọi nào đang diễn ra — trạng thái mặc định.
  idle,

  /// Mình vừa gửi offer, đang chờ B trả lời (CALLING ở tài liệu gốc).
  outgoingRinging,

  /// Mình vừa nhận offer từ A, đang chờ user accept/reject (RINGING).
  incomingRinging,

  /// Đã accept/nhận answer, đang chờ ICE negotiation xong (CONNECTING).
  connecting,

  /// PeerConnection đã connected — đang gọi thật (CONNECTED).
  connected,

  /// Cuộc gọi vừa kết thúc (call-end/call-reject/lỗi) — UI hiển thị
  /// nhanh rồi tự quay lại idle.
  ended,

  failure,
}

@freezed
sealed class CallState with _$CallState {
  const factory CallState({
    @Default(CallStatus.idle) CallStatus status,
    String? roomId,
    String? peerId,
    @Default('audio') String callType,
    @Default(false) bool isMuted,
    @Default(false) bool isCameraOff,
    @Default(false) bool isSpeakerOn,
    @Default(false) bool isSignalingConnected,
    String? errorMessage,
    @Default(Duration.zero) Duration elapsed,

    /// SDP offer nhận được (chưa xử lý tới khi user bấm Accept) — không
    /// đưa MediaStream/RTCPeerConnection vào state để tránh so sánh
    /// Equatable trên object không immutable; CallBloc giữ chúng riêng
    /// (truy cập qua CallBloc.localStream/remoteStream).
    String? pendingRemoteOfferSdp,

    /// Tăng dần mỗi khi remote MediaStream mới sẵn sàng — UI dùng làm tín
    /// hiệu để đọc lại CallBloc.remoteStream và gán vào RTCVideoRenderer,
    /// vì bản thân MediaStream không nằm trong state (xem ghi chú trên).
    @Default(0) int remoteStreamTick,
  }) = _CallState;
}
