part of 'call_bloc.dart';

@freezed
sealed class CallEvent with _$CallEvent {
  /// Mở WebSocket + subscribe message — gọi 1 lần ngay sau khi đăng nhập
  /// thành công (xem app.dart), không phải mỗi lần vào màn hình gọi.
  const factory CallEvent.signalingStarted() = CallSignalingStarted;

  const factory CallEvent.outgoingCallRequested({
    required String calleeId,
    required bool isVideo,
  }) = CallOutgoingRequested;

  const factory CallEvent.acceptRequested() = CallAcceptRequested;

  const factory CallEvent.rejectRequested() = CallRejectRequested;

  /// Dùng cho cả 2 trường hợp: đang gọi (outgoingRinging) bấm huỷ, hoặc
  /// đang connected bấm cúp máy.
  const factory CallEvent.endRequested() = CallEndRequested;

  const factory CallEvent.muteToggled() = CallMuteToggled;

  const factory CallEvent.cameraToggled() = CallCameraToggled;

  const factory CallEvent.switchCameraRequested() = CallSwitchCameraRequested;

  const factory CallEvent.speakerToggled() = CallSpeakerToggled;

  /// User chọn 1 thiết bị audio output cụ thể (loa ngoài/tai nghe dây/
  /// Bluetooth...) từ danh sách trả về bởi [CallBloc.listAudioOutputs] —
  /// khác speakerToggled (chỉ bật/tắt loa nhị phân).
  const factory CallEvent.audioOutputSelected({
    required String deviceId,
    required bool isSpeaker,
  }) = CallAudioOutputSelected;

  /// Internal — Timer 30s tự bắn khi outgoingRinging/incomingRinging quá
  /// lâu không ai bắt máy (xem CallBloc._startRingTimer). Không phải action
  /// user, tương tự signalingMessageReceived.
  const factory CallEvent.ringTimedOut(String roomId) = CallRingTimedOut;

  /// Internal — dispatch từ các stream subscription (signaling message,
  /// ICE candidate cục bộ, connection state của PeerConnection).
  const factory CallEvent.signalingMessageReceived(SignalingMessage message) =
      CallSignalingMessageReceived;

  const factory CallEvent.localIceCandidateGenerated(RTCIceCandidate candidate) =
      CallLocalIceCandidateGenerated;

  const factory CallEvent.remoteStreamReceived(MediaStream stream) = CallRemoteStreamReceived;

  const factory CallEvent.peerConnectionStateChanged(RTCPeerConnectionState state) =
      CallPeerConnectionStateChanged;

  const factory CallEvent.tick() = CallTicked;
}
