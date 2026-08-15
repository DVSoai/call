import 'dart:async';
import 'dart:io';

import 'package:audio_decoder/audio_decoder.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:path_provider/path_provider.dart';
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

  // ---- Ghi audio NGƯỜI KIA đang nói (Translated Call, §8) ----
  // flutter_webrtc không expose PCM thô ra Dart (đã khảo sát native source:
  // có sẵn ở Android/iOS nhưng chưa wrap) — MediaRecorder(audioChannel:
  // OUTPUT) là API DUY NHẤT có sẵn để lấy audio người kia, nhưng ghi ra
  // .m4a (AAC, MediaCodec/MediaMuxer bên Android) chứ không phải WAV, nên
  // phải decode qua audio_decoder trước khi đưa vào sherpa_onnx (chỉ đọc
  // WAV). Ghi xoay vòng từng đoạn ngắn thay vì 1 file dài — khớp tự nhiên
  // với pipeline VAD cắt câu phía sau, không cần đọc file đang ghi dở.
  static const _remoteAudioSegmentDuration = Duration(seconds: 4);

  MediaRecorder? _remoteAudioRecorder;
  bool _remoteAudioCaptureRunning = false;
  final _remoteAudioSegmentController = StreamController<String>.broadcast();

  /// Đường dẫn 1 file WAV (16kHz mono) mỗi khi ghi xong 1 đoạn ~4s.
  Stream<String> get onRemoteAudioSegment => _remoteAudioSegmentController.stream;

  Future<void> startRemoteAudioCapture() async {
    if (_remoteAudioCaptureRunning) return;
    _remoteAudioCaptureRunning = true;
    unawaited(_remoteAudioCaptureLoop());
  }

  Future<void> _remoteAudioCaptureLoop() async {
    final dir = await getTemporaryDirectory();
    while (_remoteAudioCaptureRunning) {
      final segmentId = DateTime.now().microsecondsSinceEpoch;
      final aacPath = '${dir.path}/remote_audio_$segmentId.m4a';
      try {
        final recorder = MediaRecorder();
        _remoteAudioRecorder = recorder;
        await recorder.start(aacPath, audioChannel: RecorderAudioChannel.OUTPUT);
        await Future<void>.delayed(_remoteAudioSegmentDuration);
        await recorder.stop();
        _remoteAudioRecorder = null;
      } catch (e, st) {
        AppLogger.w('WebRtcService: ghi đoạn audio người kia lỗi, bỏ qua đoạn này', e, st);
        continue;
      }
      // Bị stopRemoteAudioCapture() gọi giữa lúc đang chờ — bỏ đoạn cuối,
      // không cần decode/emit thêm.
      if (!_remoteAudioCaptureRunning) break;

      try {
        final wavPath = '${dir.path}/remote_audio_$segmentId.wav';
        await AudioDecoder.convertToWav(aacPath, wavPath, sampleRate: 16000, channels: 1);
        unawaited(_deleteQuietly(aacPath));
        if (!_remoteAudioSegmentController.isClosed) {
          _remoteAudioSegmentController.add(wavPath);
        }
      } catch (e, st) {
        AppLogger.w('WebRtcService: decode đoạn audio người kia sang WAV lỗi, bỏ qua đoạn này', e, st);
      }
    }
  }

  /// An toàn gọi kể cả khi chưa start hoặc đã dừng rồi. Tự dừng recorder
  /// đang ghi dở ngay lập tức thay vì chờ hết đoạn hiện tại — phản hồi nhanh
  /// khi user tắt phụ đề hoặc cúp máy.
  Future<void> stopRemoteAudioCapture() async {
    _remoteAudioCaptureRunning = false;
    final recorder = _remoteAudioRecorder;
    if (recorder != null) {
      _remoteAudioRecorder = null;
      await _safeDispose(() => recorder.stop(), 'remoteAudioRecorder.stop');
    }
  }

  Future<void> _deleteQuietly(String path) async {
    try {
      await File(path).delete();
    } catch (_) {
      // File .m4a tạm đã decode xong — không xoá được cũng không sao, dọn ở
      // dispose()/lần chạy sau, không ảnh hưởng luồng chính.
    }
  }

  RTCPeerConnection _requirePeerConnection() {
    final pc = _peerConnection;
    if (pc == null) {
      throw StateError('WebRtcService: chưa gọi initPeerConnection()');
    }
    return pc;
  }

  /// Dọn dẹp theo từng bước, MỖI BƯỚC tự bắt lỗi riêng — 1 bước lỗi (vd.
  /// native throw lúc dispose 1 MediaStream nhận từ SFU) không được phép
  /// chặn các bước còn lại, và tuyệt đối không được để lỗi thoát ra ngoài
  /// hàm này: nếu throw, CallBloc._onEndRequested phía trên sẽ dừng giữa
  /// chừng, không bao giờ emit(idle) — user bấm cúp máy nhưng màn hình bị
  /// kẹt nguyên tại chỗ (bug thật đã gặp).
  Future<void> dispose() async {
    await _safeDispose(stopRemoteAudioCapture, 'remoteAudioCapture');

    final pc = _peerConnection;
    if (pc != null) {
      // Gỡ callback TRƯỚC khi đóng — pc.close() có thể tự bắn thêm 1 sự
      // kiện cuối (onConnectionState/onTrack...) cố add vào
      // StreamController sắp bị đóng ngay bên dưới, gây "Bad state: Cannot
      // add event after closing" nếu callback còn gắn.
      pc.onIceCandidate = null;
      pc.onTrack = null;
      pc.onRemoveTrack = null;
      pc.onConnectionState = null;
    }

    if (localStream != null) await _safeDispose(() => localStream!.dispose(), 'localStream');
    if (remoteStream != null) await _safeDispose(() => remoteStream!.dispose(), 'remoteStream');
    for (final stream in groupRemoteStreams.values) {
      await _safeDispose(() => stream.dispose(), 'groupRemoteStream ${stream.id}');
    }
    groupRemoteStreams.clear();

    if (pc != null) {
      await _safeDispose(() => pc.close(), 'peerConnection.close');
      await _safeDispose(() => pc.dispose(), 'peerConnection.dispose');
    }
    _peerConnection = null;
    localStream = null;
    remoteStream = null;

    await _safeDispose(() => _remoteStreamController.close(), 'remoteStreamController');
    await _safeDispose(() => _groupRemoteStreamsController.close(), 'groupRemoteStreamsController');
    await _safeDispose(() => _localIceCandidateController.close(), 'localIceCandidateController');
    await _safeDispose(() => _connectionStateController.close(), 'connectionStateController');
    await _safeDispose(() => _remoteAudioSegmentController.close(), 'remoteAudioSegmentController');
  }

  Future<void> _safeDispose(Future<void> Function() action, String label) async {
    try {
      await action();
    } catch (e, st) {
      AppLogger.w('WebRtcService: dispose() lỗi ở bước "$label" (bỏ qua, tiếp tục dọn)', e, st);
    }
  }
}
