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

    // "direct" (1-1, mặc định) | "group" — cùng convention với
    // Conversation.type. peerId (số ít) chỉ có ý nghĩa cho direct, giữ
    // nguyên không đổi cho toàn bộ luồng 1-1 cũ. participantIds chỉ dùng
    // cho group.
    @Default('direct') String callMode,
    @Default(<String>[]) List<String> participantIds,
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

    /// Translated Call (docs/CALL_SYSTEM.md §8) — user tự bật, chỉ áp dụng
    /// cho call 1-1 đã connected (v1). subtitleText là dòng dịch MỚI NHẤT,
    /// null nếu tắt phụ đề hoặc chưa có câu nào được dịch xong.
    @Default(false) bool subtitlesEnabled,
    String? subtitleText,

    /// Ngôn ngữ NGƯỜI KIA đang nói — Server tự điền vào offer/answer (xem
    /// SignalingMessage.preferredLanguage), dùng để ép cứng ASR thay vì để
    /// Whisper tự đoán. null nếu chưa nhận được offer/answer nào có field
    /// này (vd. đang outgoingRinging, chưa có answer).
    String? peerPreferredLanguage,
  }) = _CallState;
}
