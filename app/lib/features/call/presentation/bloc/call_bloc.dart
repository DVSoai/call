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
import '../../domain/usecases/create_group_call_usecase.dart';
import '../../domain/usecases/get_turn_credentials_usecase.dart';
import '../../domain/usecases/join_group_call_usecase.dart';

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
    required CreateGroupCallUseCase createGroupCallUseCase,
    required JoinGroupCallUseCase joinGroupCallUseCase,
    required TokenStorage tokenStorage,
  })  : _repository = repository,
        _getTurnCredentialsUseCase = getTurnCredentialsUseCase,
        _createGroupCallUseCase = createGroupCallUseCase,
        _joinGroupCallUseCase = joinGroupCallUseCase,
        _tokenStorage = tokenStorage,
        super(const CallState()) {
    on<CallSignalingStarted>(_onSignalingStarted);
    on<CallOutgoingRequested>(_onOutgoingCallRequested);
    on<CallGroupRequested>(_onGroupCallRequested);
    on<CallAcceptRequested>(_onAcceptRequested);
    on<CallRejectRequested>(_onRejectRequested);
    on<CallEndRequested>(_onEndRequested);
    on<CallMuteToggled>(_onMuteToggled);
    on<CallCameraToggled>(_onCameraToggled);
    on<CallSwitchCameraRequested>(_onSwitchCameraRequested);
    on<CallSpeakerToggled>(_onSpeakerToggled);
    on<CallAudioOutputSelected>(_onAudioOutputSelected);
    on<CallRingTimedOut>(_onRingTimedOut);
    on<CallSignalingMessageReceived>(_onSignalingMessageReceived);
    on<CallLocalIceCandidateGenerated>(_onLocalIceCandidateGenerated);
    on<CallRemoteStreamReceived>((event, emit) => emit(state.copyWith(remoteStreamTick: state.remoteStreamTick + 1)));
    on<CallGroupRemoteStreamsChanged>(
        (event, emit) => emit(state.copyWith(remoteStreamTick: state.remoteStreamTick + 1)));
    on<CallPeerConnectionStateChanged>(_onPeerConnectionStateChanged);
    on<CallTicked>((event, emit) => emit(state.copyWith(elapsed: state.elapsed + const Duration(seconds: 1))));
  }

  // Khớp ringingTTL (30s) phía backend — Zalo/Messenger đều tự huỷ cuộc gọi
  // không ai bắt máy sau một khoảng cố định thay vì đổ chuông vô thời hạn.
  static const _ringTimeout = Duration(seconds: 30);

  final CallRepository _repository;
  final GetTurnCredentialsUseCase _getTurnCredentialsUseCase;
  final CreateGroupCallUseCase _createGroupCallUseCase;
  final JoinGroupCallUseCase _joinGroupCallUseCase;
  final TokenStorage _tokenStorage;
  final _uuid = const Uuid();

  WebRtcService? _webRtcService;
  StreamSubscription<SignalingMessage>? _signalingSub;
  StreamSubscription<RTCIceCandidate>? _localIceSub;
  StreamSubscription<MediaStream>? _remoteStreamSub;
  StreamSubscription<Map<String, MediaStream>>? _groupRemoteStreamsSub;
  StreamSubscription<RTCPeerConnectionState>? _connectionStateSub;
  Timer? _ticker;
  Timer? _ringTimer;

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

  /// Group — key = userID người publish (SFU gán MediaStream.id = userID,
  /// xem internal/sfu/room.go). UI đọc lại mỗi khi remoteStreamTick đổi,
  /// giống cách remoteStream (1-1) đang được đọc lại — xem call_page.dart.
  Map<String, MediaStream> get groupRemoteStreams => _webRtcService?.groupRemoteStreams ?? const {};

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
    _startRingTimer(roomId);

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
    if (state.status != CallStatus.incomingRinging) return;
    _cancelRingTimer();

    if (state.callMode == 'group') {
      // Group: chưa có SDP peer-to-peer nào để answer — phải join SFU
      // trước (POST /calls/:roomId/join), Server sẽ tự gửi offer xuống qua
      // WS sau đó (xem _handleGroupOffer).
      emit(state.copyWith(status: CallStatus.connecting));
      try {
        final service = _startNewWebRtcSession();
        await service.openLocalMedia(video: false); // v1 chỉ audio
        final iceServers = await _fetchIceServers();
        await service.initPeerConnection(iceServers, isGroup: true);
        await _joinGroupCall(state.roomId!);
      } catch (e, st) {
        AppLogger.e('CallBloc: join group call lỗi', e, st);
        await _cleanupWebRtc();
        emit(state.copyWith(status: CallStatus.failure, errorMessage: e.toString()));
      }
      return;
    }

    if (state.pendingRemoteOfferSdp == null) return;
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

  /// Bắt đầu 1 Group Call (SFU, audio-only v1) — tạo room qua REST rồi tự
  /// join luôn (người tạo cũng phải join SFU như mọi participant khác,
  /// không có gì đặc biệt hơn). Không có khái niệm "outgoingRinging chờ 1
  /// người trả lời" như 1-1 — người tạo vào thẳng connecting, người được
  /// mời tham gia dần dần qua incomingRinging riêng của từng người (xem
  /// _handleGroupOffer).
  Future<void> _onGroupCallRequested(CallGroupRequested event, Emitter<CallState> emit) async {
    if (state.status != CallStatus.idle) {
      AppLogger.w('CallBloc: đang có cuộc gọi khác, bỏ qua groupCallRequested');
      return;
    }

    emit(state.copyWith(
      status: CallStatus.connecting,
      callMode: 'group',
      participantIds: event.participantIds,
      callType: 'audio',
    ));

    try {
      final roomId = await _createGroupCallRoom(event.participantIds, event.conversationId);
      emit(state.copyWith(roomId: roomId));

      final service = _startNewWebRtcSession();
      await service.openLocalMedia(video: false);
      final iceServers = await _fetchIceServers();
      await service.initPeerConnection(iceServers, isGroup: true);
      await _joinGroupCall(roomId);
    } catch (e, st) {
      AppLogger.e('CallBloc: groupCallRequested lỗi', e, st);
      await _cleanupWebRtc();
      emit(state.copyWith(status: CallStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onRejectRequested(CallRejectRequested event, Emitter<CallState> emit) async {
    if (state.status != CallStatus.incomingRinging) return;
    _cancelRingTimer();
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
      callMode: 'direct',
      participantIds: const [],
    ));
  }

  Future<void> _onEndRequested(CallEndRequested event, Emitter<CallState> emit) async {
    _cancelRingTimer();
    // Bọc try/catch quanh TOÀN BỘ phần gửi tín hiệu + dọn WebRTC — nếu bất
    // kỳ bước nào throw (vd. WebRtcService.dispose() lỗi native lúc đang
    // dọn stream nhận từ SFU) mà không bắt lại, emit(idle) bên dưới sẽ
    // KHÔNG BAO GIỜ chạy tới → user bấm cúp máy nhưng màn hình bị kẹt
    // nguyên tại chỗ. Cúp máy phải LUÔN thoát ra được dù dọn dẹp có lỗi.
    try {
      // Group: peerId có thể null (người tạo room không có "1 peer" cụ thể)
      // — backend chỉ cần callId+from để biết ai rời SFU room nào, "to"
      // không quan trọng (khác 1-1, luôn có peerId nên hành vi cũ không đổi).
      if (state.roomId != null && state.status != CallStatus.idle) {
        final myId = await _tokenStorage.readUserId() ?? '';
        _repository.sendSignaling(SignalingMessage(
          type: SignalingMessageType.callEnd,
          from: myId,
          to: state.peerId ?? 'server',
          callId: state.roomId!,
          mode: state.callMode == 'group' ? 'group' : null,
        ));
      }
      await _cleanupWebRtc();
    } catch (e, st) {
      AppLogger.e('CallBloc: endRequested dọn dẹp lỗi (vẫn thoát về idle)', e, st);
    }
    emit(state.copyWith(
      status: CallStatus.idle,
      roomId: null,
      peerId: null,
      pendingRemoteOfferSdp: null,
      isMuted: false,
      isCameraOff: false,
      isSpeakerOn: false,
      callMode: 'direct',
      participantIds: const [],
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

  Future<void> _onSpeakerToggled(CallSpeakerToggled event, Emitter<CallState> emit) async {
    final on = !state.isSpeakerOn;
    await _webRtcService?.setSpeakerphoneOn(on);
    emit(state.copyWith(isSpeakerOn: on));
  }

  /// Danh sách thiết bị audio output hiện có (loa ngoài, tai nghe dây,
  /// Bluetooth...) để UI hiện bottom sheet cho user chọn đúng thiết bị —
  /// xem call_page.dart. Trả rỗng nếu chưa có cuộc gọi nào (WebRtcService
  /// chưa khởi tạo).
  Future<List<MediaDeviceInfo>> listAudioOutputs() async => _webRtcService?.listAudioOutputs() ?? [];

  Future<void> _onAudioOutputSelected(CallAudioOutputSelected event, Emitter<CallState> emit) async {
    await _webRtcService?.selectAudioOutput(event.deviceId);
    emit(state.copyWith(isSpeakerOn: event.isSpeaker));
  }

  /// 30s không ai bắt máy — tự huỷ giống Zalo/Messenger thay vì đổ chuông
  /// vô thời hạn (roomId trong event để bỏ qua timer cũ nếu cuộc gọi đã đổi
  /// — vd. reject xong gọi lại ngay, timer trước đó có thể còn đang chờ).
  Future<void> _onRingTimedOut(CallRingTimedOut event, Emitter<CallState> emit) async {
    if (state.roomId != event.roomId) return;

    if (state.status == CallStatus.outgoingRinging) {
      // Phía gọi tự huỷ — backend ghi nhận "missed" vì room vẫn đang RINGING
      // (xem Hub.finalizeRoom), không phải "completed".
      final myId = await _tokenStorage.readUserId() ?? '';
      _repository.sendSignaling(SignalingMessage(
        type: SignalingMessageType.callEnd,
        from: myId,
        to: state.peerId ?? '',
        callId: state.roomId ?? '',
      ));
      await _cleanupWebRtc();
      emit(state.copyWith(status: CallStatus.ended, errorMessage: 'Không có phản hồi'));
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!isClosed && state.status == CallStatus.ended) {
        emit(state.copyWith(status: CallStatus.idle, roomId: null, peerId: null, pendingRemoteOfferSdp: null));
      }
    } else if (state.status == CallStatus.incomingRinging) {
      // Phía nhận tự dọn màn hình cục bộ — không cần gửi gì thêm, caller đã
      // tự có timer riêng ở trên lo việc báo "missed" về backend.
      await _cleanupWebRtc();
      emit(state.copyWith(
        status: CallStatus.idle,
        roomId: null,
        peerId: null,
        pendingRemoteOfferSdp: null,
      ));
    }
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
    if (msg.isGroup) {
      await _handleGroupOffer(msg, emit);
      return;
    }

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
    _startRingTimer(msg.callId);

    if (_autoAcceptRoomIds.remove(msg.callId)) {
      add(const CallEvent.acceptRequested());
    }
  }

  /// offer với Payload.mode="group" có 2 dạng hoàn toàn khác nhau, phân
  /// biệt bằng việc có SDP hay không:
  /// - Chưa có SDP: lời mời ban đầu (POST /calls/group vừa tạo room) — chỉ
  ///   hiện Incoming UI, KHÔNG gán pendingRemoteOfferSdp (không có gì để
  ///   answer trực tiếp, phải join SFU trước — xem _onAcceptRequested).
  /// - Có SDP: offer thật từ SFU (đầu tiên sau khi join, hoặc renegotiate
  ///   giữa cuộc gọi vì có người mới join/rời) — PeerConnection phải đã tồn
  ///   tại từ trước (tạo lúc _onAcceptRequested/_onGroupCallRequested).
  Future<void> _handleGroupOffer(SignalingMessage msg, Emitter<CallState> emit) async {
    if (msg.sdp == null || msg.sdp!.isEmpty) {
      if (state.status != CallStatus.idle) return; // đang bận việc khác
      AppLogger.i('CallBloc: nhận lời mời group call từ ${msg.from}, callId=${msg.callId}');
      emit(state.copyWith(
        status: CallStatus.incomingRinging,
        roomId: msg.callId,
        peerId: msg.from,
        callType: msg.callType ?? 'audio',
        callMode: 'group',
      ));
      _startRingTimer(msg.callId);
      if (_autoAcceptRoomIds.remove(msg.callId)) {
        add(const CallEvent.acceptRequested());
      }
      return;
    }

    // Offer thật từ SFU — có thể là offer đầu tiên (status == connecting)
    // hoặc renegotiate giữa cuộc gọi đang connected (có người mới join) —
    // xử lý y hệt nhau, chỉ khác là KHÔNG được đổi CallStatus ở nhánh sau.
    if (msg.callId != state.roomId || _webRtcService == null) return;
    try {
      final service = _webRtcService!;
      final answer = await service.createAnswer(msg.sdp!);
      final myId = await _tokenStorage.readUserId() ?? '';
      _repository.sendSignaling(SignalingMessage(
        type: SignalingMessageType.answer,
        from: myId,
        to: 'server',
        callId: state.roomId!,
        sdp: answer.sdp,
        mode: 'group',
      ));
    } catch (e, st) {
      AppLogger.e('CallBloc: group createAnswer lỗi', e, st);
    }
  }

  Future<void> _handleAnswer(SignalingMessage msg, Emitter<CallState> emit) async {
    if (msg.callId != state.roomId || _webRtcService == null || msg.sdp == null) return;
    _cancelRingTimer();
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
    _cancelRingTimer();
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
    // Group: peerId có thể null (người tạo room không có "1 peer" cụ thể
    // nào) — backend route theo callId+room.Mode, không cần "to" đúng thật,
    // nhưng vẫn phải gửi "to" hợp lệ theo schema (khác 1-1, không đổi).
    if (state.roomId == null) return;
    final myId = await _tokenStorage.readUserId() ?? '';
    _repository.sendSignaling(SignalingMessage(
      type: SignalingMessageType.iceCandidate,
      from: myId,
      to: state.peerId ?? 'server',
      callId: state.roomId!,
      candidate: event.candidate.toMap(),
      mode: state.callMode == 'group' ? 'group' : null,
    ));
  }

  Future<void> _onPeerConnectionStateChanged(CallPeerConnectionStateChanged event, Emitter<CallState> emit) async {
    switch (event.state) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        // Video: mặc định bật loa (đang nhìn màn hình, không áp tai) — audio
        // giữ mặc định tai nghe/loa trong (isSpeakerOn: false) như cuộc gọi
        // thường.
        final speakerOn = state.callType == 'video';
        await _webRtcService?.setSpeakerphoneOn(speakerOn);
        emit(state.copyWith(status: CallStatus.connected, isSpeakerOn: speakerOn));
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

  /// Tạo room Group Call qua POST /calls/group — dùng chung [callApi] như
  /// _fetchIceServers, giữ đúng convention gọi REST của cả file này.
  /// conversationId (nếu có) giúp Server trả về room ĐANG SỐNG thay vì tạo
  /// mới, khi group đó đã có cuộc gọi diễn ra (join lại).
  Future<String> _createGroupCallRoom(List<String> participantIds, String? conversationId) async {
    String? roomId;
    String? error;
    await callApi<String, CreateGroupCallParams>(
      useCase: _createGroupCallUseCase,
      param: CreateGroupCallParams(
        participantIds: participantIds,
        callType: 'audio',
        conversationId: conversationId,
      ),
      onSuccess: (id) async => roomId = id,
      onFailure: (message) => error = message,
    );
    if (roomId == null) {
      throw StateError(error ?? 'Không tạo được group call');
    }
    return roomId!;
  }

  /// POST /calls/:roomId/join — Server sẽ tự gửi offer xuống qua WS sau khi
  /// gọi xong (xem _handleGroupOffer).
  Future<void> _joinGroupCall(String roomId) async {
    bool ok = false;
    String? error;
    await callApi<void, String>(
      useCase: _joinGroupCallUseCase,
      param: roomId,
      onSuccess: (_) async => ok = true,
      onFailure: (message) => error = message,
    );
    if (!ok) {
      throw StateError(error ?? 'Không tham gia được group call');
    }
  }

  WebRtcService _startNewWebRtcSession() {
    final service = WebRtcService();
    _webRtcService = service;
    _localIceSub = service.onLocalIceCandidate.listen((c) => add(CallEvent.localIceCandidateGenerated(c)));
    _remoteStreamSub = service.onRemoteStream.listen((s) => add(CallEvent.remoteStreamReceived(s)));
    // Group: nhiều remoteStream cùng lúc (1/participant) — dùng chung
    // remoteStreamTick làm tín hiệu "có gì đổi, đọc lại groupRemoteStreams"
    // (giống hệt cơ chế remoteStream đã dùng cho 1-1, không cần thêm field
    // state riêng).
    _groupRemoteStreamsSub =
        service.onGroupRemoteStreamsChanged.listen((_) => add(const CallEvent.groupRemoteStreamsChanged()));
    _connectionStateSub = service.onConnectionState.listen((s) => add(CallEvent.peerConnectionStateChanged(s)));
    return service;
  }

  Future<void> _cleanupWebRtc() async {
    _ticker?.cancel();
    _ticker = null;
    await _localIceSub?.cancel();
    await _remoteStreamSub?.cancel();
    await _groupRemoteStreamsSub?.cancel();
    await _connectionStateSub?.cancel();
    _localIceSub = null;
    _remoteStreamSub = null;
    _groupRemoteStreamsSub = null;
    _connectionStateSub = null;
    await _webRtcService?.dispose();
    _webRtcService = null;
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => add(const CallEvent.tick()));
  }

  /// Bắt đầu đếm ngược 30s cho 1 roomId đang ringing (outgoing hoặc
  /// incoming) — bắn CallEvent.ringTimedOut nếu hết giờ mà vẫn chưa
  /// accept/reject/answer. KHÔNG gọi emit() trực tiếp trong callback Timer
  /// (chạy ngoài vòng đời handler) — phải add() event để đi qua handler
  /// đăng ký đàng hoàng, đúng nguyên tắc Bloc.
  void _startRingTimer(String roomId) {
    _ringTimer?.cancel();
    _ringTimer = Timer(_ringTimeout, () => add(CallEvent.ringTimedOut(roomId)));
  }

  void _cancelRingTimer() {
    _ringTimer?.cancel();
    _ringTimer = null;
  }

  @override
  Future<void> close() async {
    await _signalingSub?.cancel();
    await _cleanupWebRtc();
    _repository.disconnectSignaling();
    return super.close();
  }
}
