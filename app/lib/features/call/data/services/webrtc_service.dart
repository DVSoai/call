import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/ice_server.dart';

/// Bọc RTCPeerConnection + local/remote MediaStream — phần duy nhất trong
/// app chạm trực tiếp vào audio/video. Server KHÔNG bao giờ đi qua đây,
/// media chạy P2P thẳng giữa 2 Client (xem docs/CALL_SYSTEM.md §1).
///
/// Vòng đời: 1 instance = 1 cuộc gọi. Tạo mới cho mỗi cuộc gọi, gọi
/// [dispose] khi cuộc gọi kết thúc — không tái sử dụng instance cũ.
class WebRtcService {
  RTCPeerConnection? _peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;

  // Group Call (SFU): 1 PeerConnection duy nhất với Server nhưng nhận NHIỀU
  // track cùng lúc (1 track/participant khác) — khác 1-1 (đúng 1 remoteStream).
  // Key = MediaStream.id, SFU cố tình gán bằng userID người publish (xem
  // internal/sfu/room.go) để biết audio vừa nhận là của ai.
  bool _isGroup = false;
  final Map<String, MediaStream> groupRemoteStreams = {};

  final _remoteStreamController = StreamController<MediaStream>.broadcast();
  final _groupRemoteStreamsController = StreamController<Map<String, MediaStream>>.broadcast();
  final _localIceCandidateController = StreamController<RTCIceCandidate>.broadcast();
  final _connectionStateController = StreamController<RTCPeerConnectionState>.broadcast();

  Stream<MediaStream> get onRemoteStream => _remoteStreamController.stream;
  Stream<Map<String, MediaStream>> get onGroupRemoteStreamsChanged => _groupRemoteStreamsController.stream;
  Stream<RTCIceCandidate> get onLocalIceCandidate => _localIceCandidateController.stream;
  Stream<RTCPeerConnectionState> get onConnectionState => _connectionStateController.stream;

  /// getUserMedia() native chỉ trả `NotAllowedError` (không tự mở dialog xin
  /// quyền) — phải chủ động request quyền OS trước, nếu không camera/mic sẽ
  /// bị từ chối im lặng dù đã khai báo trong AndroidManifest.xml.
  Future<MediaStream> openLocalMedia({required bool video}) async {
    await _requestMediaPermissions(video: video);
    localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': video ? {'facingMode': 'user'} : false,
    });
    return localStream!;
  }

  Future<void> _requestMediaPermissions({required bool video}) async {
    final permissions = [Permission.microphone, if (video) Permission.camera];
    final statuses = await permissions.request();
    final denied = statuses.entries.where((e) => !e.value.isGranted);
    if (denied.isNotEmpty) {
      final names = denied.map((e) => e.key == Permission.camera ? 'camera' : 'micro').join(', ');
      throw StateError('Cần cấp quyền $names để gọi điện — vào Cài đặt > Ứng dụng để cấp quyền.');
    }
  }

  Future<void> initPeerConnection(List<IceServer> iceServers, {bool isGroup = false}) async {
    _isGroup = isGroup;
    final configuration = <String, dynamic>{
      'iceServers': iceServers.map((s) => s.toWebRtcConfig()).toList(),
      'sdpSemantics': 'unified-plan',
    };

    final pc = await createPeerConnection(configuration);
    _peerConnection = pc;

    pc.onIceCandidate = (candidate) {
      if (candidate.candidate != null) _localIceCandidateController.add(candidate);
    };
    pc.onTrack = (event) {
      if (event.streams.isEmpty) return;
      final stream = event.streams.first;
      if (_isGroup) {
        groupRemoteStreams[stream.id] = stream;
        _groupRemoteStreamsController.add(Map.unmodifiable(groupRemoteStreams));
      } else {
        remoteStream = stream;
        _remoteStreamController.add(remoteStream!);
      }
    };
    // Chỉ có ý nghĩa cho group — SFU bỏ track của 1 participant (họ rời
    // room) khiến Server renegotiate lại, track biến mất khỏi PeerConnection.
    pc.onRemoveTrack = (stream, _) {
      if (!_isGroup) return;
      groupRemoteStreams.remove(stream.id);
      _groupRemoteStreamsController.add(Map.unmodifiable(groupRemoteStreams));
    };
    pc.onConnectionState = (state) => _connectionStateController.add(state);

    final stream = localStream;
    if (stream != null) {
      for (final track in stream.getTracks()) {
        await pc.addTrack(track, stream);
      }
    }
  }

  /// Gọi ở máy A (chủ động gọi) — sinh offer SDP rồi setLocalDescription.
  Future<RTCSessionDescription> createOffer() async {
    final pc = _requirePeerConnection();
    final description = await pc.createOffer();
    await pc.setLocalDescription(description);
    return description;
  }

  /// Gọi ở máy B (nhận cuộc gọi) khi accept — set offer nhận được từ A
  /// làm remote description rồi sinh answer SDP.
  Future<RTCSessionDescription> createAnswer(String remoteOfferSdp) async {
    final pc = _requirePeerConnection();
    await pc.setRemoteDescription(RTCSessionDescription(remoteOfferSdp, 'offer'));
    final description = await pc.createAnswer();
    await pc.setLocalDescription(description);
    return description;
  }

  /// Gọi ở máy A khi nhận được answer từ B.
  Future<void> applyRemoteAnswer(String remoteAnswerSdp) async {
    final pc = _requirePeerConnection();
    await pc.setRemoteDescription(RTCSessionDescription(remoteAnswerSdp, 'answer'));
  }

  Future<void> addRemoteIceCandidate(Map<String, dynamic> candidateMap) async {
    final pc = _requirePeerConnection();
    try {
      await pc.addCandidate(RTCIceCandidate(
        candidateMap['candidate'] as String?,
        candidateMap['sdpMid'] as String?,
        candidateMap['sdpMLineIndex'] as int?,
      ));
    } catch (e, st) {
      // Candidate đến trễ sau khi peer connection đã đóng — không phải lỗi
      // nghiêm trọng, chỉ log để theo dõi.
      AppLogger.w('WebRtcService: addCandidate lỗi (có thể do đến trễ)', e, st);
    }
  }

  Future<void> setMuted(bool muted) async {
    for (final track in localStream?.getAudioTracks() ?? const []) {
      track.enabled = !muted;
    }
  }

  Future<void> setCameraEnabled(bool enabled) async {
    for (final track in localStream?.getVideoTracks() ?? const []) {
      track.enabled = enabled;
    }
  }

  Future<void> switchCamera() async {
    final videoTracks = localStream?.getVideoTracks() ?? const [];
    if (videoTracks.isNotEmpty) {
      await Helper.switchCamera(videoTracks.first);
    }
  }

  Future<void> setSpeakerphoneOn(bool enabled) => Helper.setSpeakerphoneOn(enabled);

  /// Danh sách thiết bị audio output hiện có (loa ngoài, tai nghe dây,
  /// Bluetooth...) — chỉ đầy đủ SAU khi đã getUserMedia() (xem docstring
  /// Helper.cameras, áp dụng tương tự cho audiooutputs).
  Future<List<MediaDeviceInfo>> listAudioOutputs() => Helper.audiooutputs;

  Future<void> selectAudioOutput(String deviceId) => Helper.selectAudioOutput(deviceId);

  RTCPeerConnection _requirePeerConnection() {
    final pc = _peerConnection;
    if (pc == null) {
      throw StateError('WebRtcService: chưa gọi initPeerConnection()');
    }
    return pc;
  }

  Future<void> dispose() async {
    await localStream?.dispose();
    await remoteStream?.dispose();
    for (final stream in groupRemoteStreams.values) {
      await stream.dispose();
    }
    groupRemoteStreams.clear();
    await _peerConnection?.close();
    await _peerConnection?.dispose();
    _peerConnection = null;
    localStream = null;
    remoteStream = null;
    await _remoteStreamController.close();
    await _groupRemoteStreamsController.close();
    await _localIceCandidateController.close();
    await _connectionStateController.close();
  }
}
