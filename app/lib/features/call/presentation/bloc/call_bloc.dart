import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/bloc/abstract_bloc_with_api.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/app_logger.dart';
import '../../data/services/webrtc_service.dart';
import '../../domain/entities/ice_server.dart';
import '../../domain/entities/signaling_message.dart';
import '../../domain/entities/turn_credentials.dart';
import '../../domain/repositories/call_repository.dart';
import '../../domain/usecases/get_turn_credentials_usecase.dart';

part 'call_bloc.freezed.dart';
part 'call_event.dart';
part 'call_state.dart';

/// State machine trung tâm cho cuộc gọi 1-1 — sống suốt phiên đăng nhập
/// (đăng ký lazySingleton ở service_locator, KHÔNG tạo mới mỗi lần vào màn
/// hình gọi) để nhận được offer đến bất cứ lúc nào, ở bất cứ màn hình nào.
///
/// CallBloc điều phối 2 nguồn dữ liệu độc lập:
/// - [CallRepository] — WebSocket signaling (SDP/ICE qua Server).
/// - [WebRtcService] — PeerConnection/MediaStream cục bộ (P2P, Server
///   không chạm vào), tạo mới cho mỗi cuộc gọi qua [_startNewWebRtcSession].
class CallBloc extends BlocWithApi<CallEvent, CallState> {
  CallBloc({
    required CallRepository repository,
    required GetTurnCredentialsUseCase getTurnCredentialsUseCase,
    required TokenStorage tokenStorage,
  })  : _repository = repository,
        _getTurnCredentialsUseCase = getTurnCredentialsUseCase,
        _tokenStorage = tokenStorage,
        super(const CallState()) {
    on<CallSignalingStarted>(_onSignalingStarted);
    on<CallOutgoingRequested>(_onOutgoingCallRequested);
    on<CallAcceptRequested>(_onAcceptRequested);
    on<CallRejectRequested>(_onRejectRequested);
    on<CallEndRequested>(_onEndRequested);
    on<CallMuteToggled>(_onMuteToggled);
    on<CallCameraToggled>(_onCameraToggled);
    on<CallSwitchCameraRequested>(_onSwitchCameraRequested);
    on<CallSignalingMessageReceived>(_onSignalingMessageReceived);
    on<CallLocalIceCandidateGenerated>(_onLocalIceCandidateGenerated);
    on<CallRemoteStreamReceived>((event, emit) => emit(state.copyWith(remoteStreamTick: state.remoteStreamTick + 1)));
    on<CallPeerConnectionStateChanged>(_onPeerConnectionStateChanged);
    on<CallTicked>((event, emit) => emit(state.copyWith(elapsed: state.elapsed + const Duration(seconds: 1))));
  }

  final CallRepository _repository;
  final GetTurnCredentialsUseCase _getTurnCredentialsUseCase;
  final TokenStorage _tokenStorage;
  final _uuid = const Uuid();

  WebRtcService? _webRtcService;
  StreamSubscription<SignalingMessage>? _signalingSub;
  StreamSubscription<RTCIceCandidate>? _localIceSub;
  StreamSubscription<MediaStream>? _remoteStreamSub;
  StreamSubscription<RTCPeerConnectionState>? _connectionStateSub;
  Timer? _ticker;

  // roomId user đã bấm Accept trên màn hình cuộc gọi đến kiểu native
  // (CallKit/ConnectionService, xem core/push/push_service.dart) TRƯỚC KHI
  // offer thật sự tới qua WebSocket (app vừa mở lại sau khi bị kill) — khi
  // offer khớp 1 trong các id này, tự động accept luôn thay vì hiện lại
  // Incoming Call UI trong app (user đã accept rồi, không cần hỏi lại).
  final Set<String> _autoAcceptRoomIds = {};

  /// Gọi từ PushService khi user bấm Accept trên CallKit UI. 2 tình huống:
  /// - Offer ĐÃ tới qua WS sống rồi (app chỉ bị thu nhỏ, CallBloc đang
  ///   incomingRinging sẵn) — accept ngay lập tức.
  /// - Offer CHƯA tới (app vừa bị kill, đang mở lại, WS chưa kịp reconnect)
  ///   — đánh dấu để _handleIncomingOffer tự accept khi offer redeliver tới.
  void markAutoAccept(String roomId) {
    if (state.status == CallStatus.incomingRinging && state.roomId == roomId) {
      add(const CallEvent.acceptRequested());
    } else {
      _autoAcceptRoomIds.add(roomId);
    }
  }

  /// Gọi từ PushService khi user bấm Decline trên CallKit UI trong lúc
  /// CallBloc đang có sẵn state incomingRinging cho đúng roomId này (offer
  /// đã tới qua WS sống) — cần báo reject thật cho caller, không chỉ đóng
  /// CallKit UI. Không làm gì nếu không khớp (offer chưa tới/đã xử lý xong).
  void rejectIfMatching(String roomId) {
    if (state.status == CallStatus.incomingRinging && state.roomId == roomId) {
      add(const CallEvent.rejectRequested());
    }
  }

  // true khi Telecom (ConnectionService, xem CallkitConnection.onHold trong
  // plugin flutter_callkit_incoming) đang hold cuộc gọi này để nhường audio
  // cho 1 cuộc gọi SIM khác — tách riêng khỏi isMuted (do user tự bấm) để
  // unhold không vô tình unmute cuộc gọi mà user đã tự mute từ trước.
  bool _systemHeld = false;

  /// Gọi từ PushService khi nhận CallEventActionCallToggleHold — Android
  /// Telecom tự quyết định hold/unhold (vd. SIM call chen ngang), plugin chỉ
  /// báo lại sự kiện, mic phải tự mute/unmute ở đây (không tự động).
  Future<void> setSystemHold(bool isOnHold) async {
    _systemHeld = isOnHold;
    await _webRtcService?.setMuted(_systemHeld || state.isMuted);
  }

  MediaStream? get localStream => _webRtcService?.localStream;
  MediaStream? get remoteStream => _webRtcService?.remoteStream;

  Future<void> _onSignalingStarted(CallSignalingStarted event, Emitter<CallState> emit) async {
    if (_repository.isSignalingConnected) return;
    try {
      await _repository.connectSignaling();
      _signalingSub = _repository.signalingMessages.listen(
        (msg) => add(CallEvent.signalingMessageReceived(msg)),
      );
      emit(state.copyWith(isSignalingConnected: true));
    } catch (e, st) {
      AppLogger.e('CallBloc: connectSignaling lỗi', e, st);
    }
  }

  Future<void> _onOutgoingCallRequested(CallOutgoingRequested event, Emitter<CallState> emit) async {
    if (state.status != CallStatus.idle) {
      AppLogger.w('CallBloc: đang có cuộc gọi khác, bỏ qua outgoingCallRequested');
      return;
    }

    final roomId = _uuid.v4();
    final myId = await _tokenStorage.readUserId() ?? '';
    emit(state.copyWith(
      status: CallStatus.outgoingRinging,
      roomId: roomId,
      peerId: event.calleeId,
      callType: event.isVideo ? 'video' : 'audio',
    ));

    try {
      final service = _startNewWebRtcSession();
      await service.openLocalMedia(video: event.isVideo);
      final iceServers = await _fetchIceServers();
      await service.initPeerConnection(iceServers);
      final offer = await service.createOffer();

      _repository.sendSignaling(SignalingMessage(
        type: SignalingMessageType.offer,
        from: myId,
        to: event.calleeId,
        callId: roomId,
        sdp: offer.sdp,
        callType: state.callType,
      ));
    } catch (e, st) {
      AppLogger.e('CallBloc: outgoingCall lỗi', e, st);
      await _cleanupWebRtc();
      emit(state.copyWith(status: CallStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onAcceptRequested(CallAcceptRequested event, Emitter<CallState> emit) async {
    if (state.status != CallStatus.incomingRinging || state.pendingRemoteOfferSdp == null) return;

    final myId = await _tokenStorage.readUserId() ?? '';
    emit(state.copyWith(status: CallStatus.connecting));

    try {
      final service = _startNewWebRtcSession();
      await service.openLocalMedia(video: state.callType == 'video');
      final iceServers = await _fetchIceServers();
      await service.initPeerConnection(iceServers);
      final answer = await service.createAnswer(state.pendingRemoteOfferSdp!);

      _repository.sendSignaling(SignalingMessage(
        type: SignalingMessageType.answer,
        from: myId,
        to: state.peerId!,
        callId: state.roomId!,
        sdp: answer.sdp,
      ));
    } catch (e, st) {
      AppLogger.e('CallBloc: acceptCall lỗi', e, st);
      await _cleanupWebRtc();
      emit(state.copyWith(status: CallStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onRejectRequested(CallRejectRequested event, Emitter<CallState> emit) async {
    if (state.status != CallStatus.incomingRinging) return;
    final myId = await _tokenStorage.readUserId() ?? '';
    _repository.sendSignaling(SignalingMessage(
      type: SignalingMessageType.callReject,
      from: myId,
      to: state.peerId ?? '',
      callId: state.roomId ?? '',
    ));
    emit(state.copyWith(
      status: CallStatus.idle,
      roomId: null,
      peerId: null,
      pendingRemoteOfferSdp: null,
    ));
  }

  Future<void> _onEndRequested(CallEndRequested event, Emitter<CallState> emit) async {
    if (state.roomId != null && state.peerId != null && state.status != CallStatus.idle) {
      final myId = await _tokenStorage.readUserId() ?? '';
      _repository.sendSignaling(SignalingMessage(
        type: SignalingMessageType.callEnd,
        from: myId,
        to: state.peerId!,
        callId: state.roomId!,
      ));
    }
    await _cleanupWebRtc();
    emit(state.copyWith(
      status: CallStatus.idle,
      roomId: null,
      peerId: null,
      pendingRemoteOfferSdp: null,
      isMuted: false,
      isCameraOff: false,
      elapsed: Duration.zero,
    ));
  }

  Future<void> _onMuteToggled(CallMuteToggled event, Emitter<CallState> emit) async {
    final muted = !state.isMuted;
    // Kết hợp với _systemHeld (Telecom hold do SIM call chen ngang) — nếu
    // đang bị hold thì mic vẫn phải câm bất kể user bấm unmute, tránh lộ mic
    // trong lúc Android đang ưu tiên audio cho cuộc gọi SIM.
    await _webRtcService?.setMuted(muted || _systemHeld);
    emit(state.copyWith(isMuted: muted));
  }

  Future<void> _onCameraToggled(CallCameraToggled event, Emitter<CallState> emit) async {
    final off = !state.isCameraOff;
    await _webRtcService?.setCameraEnabled(!off);
    emit(state.copyWith(isCameraOff: off));
  }

  Future<void> _onSwitchCameraRequested(CallSwitchCameraRequested event, Emitter<CallState> emit) async {
    await _webRtcService?.switchCamera();
  }

  Future<void> _onSignalingMessageReceived(CallSignalingMessageReceived event, Emitter<CallState> emit) async {
    final msg = event.message;
    switch (msg.type) {
      case SignalingMessageType.offer:
        await _handleIncomingOffer(msg, emit);
      case SignalingMessageType.answer:
        await _handleAnswer(msg, emit);
      case SignalingMessageType.iceCandidate:
        await _handleRemoteIceCandidate(msg);
      case SignalingMessageType.callEnd:
      case SignalingMessageType.callReject:
        await _handleRemoteEnd(msg, emit);
    }
  }

  Future<void> _handleIncomingOffer(SignalingMessage msg, Emitter<CallState> emit) async {
    AppLogger.i('CallBloc: nhận offer từ ${msg.from}, callId=${msg.callId}, callType=${msg.callType}');
    if (state.status != CallStatus.idle) {
      // Đang bận cuộc gọi khác — tự động từ chối, không hiện Incoming UI.
      final myId = await _tokenStorage.readUserId() ?? '';
      _repository.sendSignaling(SignalingMessage(
        type: SignalingMessageType.callReject,
        from: myId,
        to: msg.from,
        callId: msg.callId,
      ));
      return;
    }
    emit(state.copyWith(
      status: CallStatus.incomingRinging,
      roomId: msg.callId,
      peerId: msg.from,
      callType: msg.callType ?? 'audio',
      pendingRemoteOfferSdp: msg.sdp,
    ));

    if (_autoAcceptRoomIds.remove(msg.callId)) {
      add(const CallEvent.acceptRequested());
    }
  }

  Future<void> _handleAnswer(SignalingMessage msg, Emitter<CallState> emit) async {
    if (msg.callId != state.roomId || _webRtcService == null || msg.sdp == null) return;
    emit(state.copyWith(status: CallStatus.connecting));
    try {
      await _webRtcService!.applyRemoteAnswer(msg.sdp!);
    } catch (e, st) {
      AppLogger.e('CallBloc: applyRemoteAnswer lỗi', e, st);
    }
  }

  Future<void> _handleRemoteIceCandidate(SignalingMessage msg) async {
    if (msg.callId != state.roomId || msg.candidate == null || _webRtcService == null) return;
    await _webRtcService!.addRemoteIceCandidate(msg.candidate!);
  }

  Future<void> _handleRemoteEnd(SignalingMessage msg, Emitter<CallState> emit) async {
    if (msg.callId != state.roomId) return;
    await _cleanupWebRtc();
    emit(state.copyWith(
      status: CallStatus.ended,
      errorMessage: msg.type == SignalingMessageType.callReject ? 'Cuộc gọi bị từ chối' : null,
    ));
    // Cho UI kịp hiển thị "đã kết thúc" trước khi tự quay lại idle.
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!isClosed && state.status == CallStatus.ended) {
      emit(state.copyWith(status: CallStatus.idle, roomId: null, peerId: null, pendingRemoteOfferSdp: null));
    }
  }

  Future<void> _onLocalIceCandidateGenerated(CallLocalIceCandidateGenerated event, Emitter<CallState> emit) async {
    if (state.roomId == null || state.peerId == null) return;
    final myId = await _tokenStorage.readUserId() ?? '';
    _repository.sendSignaling(SignalingMessage(
      type: SignalingMessageType.iceCandidate,
      from: myId,
      to: state.peerId!,
      callId: state.roomId!,
      candidate: event.candidate.toMap(),
    ));
  }

  Future<void> _onPeerConnectionStateChanged(CallPeerConnectionStateChanged event, Emitter<CallState> emit) async {
    switch (event.state) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        emit(state.copyWith(status: CallStatus.connected));
        _startTicker();
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
      case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        if (state.status == CallStatus.connected || state.status == CallStatus.connecting) {
          add(const CallEvent.endRequested());
        }
      default:
        break;
    }
  }

  /// Gọi qua [BlocWithApi.callApi] — đúng yêu cầu dùng chung base "gọi API"
  /// cho cả REST đơn giản lẫn bước chuẩn bị trước khi mở PeerConnection.
  Future<List<IceServer>> _fetchIceServers() async {
    List<IceServer>? servers;
    String? error;
    await callApi<TurnCredentials, NoParams>(
      useCase: _getTurnCredentialsUseCase,
      param: const NoParams(),
      useCache: true, // credential dùng được 12h (TTL server), cache trong RAM là đủ
      onSuccess: (creds) async => servers = creds.toIceServers(),
      onFailure: (message) => error = message,
    );
    if (servers == null) {
      throw StateError(error ?? 'Không lấy được TURN credentials');
    }
    return servers!;
  }

  WebRtcService _startNewWebRtcSession() {
    final service = WebRtcService();
    _webRtcService = service;
    _localIceSub = service.onLocalIceCandidate.listen((c) => add(CallEvent.localIceCandidateGenerated(c)));
    _remoteStreamSub = service.onRemoteStream.listen((s) => add(CallEvent.remoteStreamReceived(s)));
    _connectionStateSub = service.onConnectionState.listen((s) => add(CallEvent.peerConnectionStateChanged(s)));
    return service;
  }

  Future<void> _cleanupWebRtc() async {
    _ticker?.cancel();
    _ticker = null;
    await _localIceSub?.cancel();
    await _remoteStreamSub?.cancel();
    await _connectionStateSub?.cancel();
    _localIceSub = null;
    _remoteStreamSub = null;
    _connectionStateSub = null;
    await _webRtcService?.dispose();
    _webRtcService = null;
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => add(const CallEvent.tick()));
  }

  @override
  Future<void> close() async {
    await _signalingSub?.cancel();
    await _cleanupWebRtc();
    _repository.disconnectSignaling();
    return super.close();
  }
}
