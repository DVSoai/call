import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
// Tên CallEvent trùng với CallEvent (freezed union) trong call_bloc.dart —
// dùng prefix "callkit" để phân biệt.
import 'package:flutter_callkit_incoming/entities/entities.dart' as callkit;
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

import '../../features/call/presentation/bloc/call_bloc.dart';
import '../utils/app_logger.dart';

/// Background handler PHẢI là top-level function (không phải method trong
/// class) — đây là yêu cầu của firebase_messaging vì nó chạy trên 1 isolate
/// riêng, tách biệt hoàn toàn khỏi state của app (kể cả khi app đã bị kill).
///
/// showCallkitIncoming() gọi native UI (ConnectionService-style trên
/// Android/CallKit trên iOS) — sống độc lập với isolate này, không cần chờ
/// user tương tác trước khi isolate bị OS thu hồi.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.i('PushService: nhận background/killed message ${message.data}');
  if (message.data['type'] == 'call_invite') {
    await _showIncomingCallUI(message.data);
  }
}

Future<void> _showIncomingCallUI(Map<String, dynamic> data) async {
  final roomId = data['roomId'] as String?;
  if (roomId == null) return;

  // Dùng roomId làm luôn CallKit id — không cần bảng map riêng, endCall()
  // sau này chỉ cần gọi lại đúng roomId.
  final params = callkit.CallKitParams(
    id: roomId,
    nameCaller: data['callerName'] as String? ?? 'Người dùng',
    appName: 'call_video',
    type: (data['callType'] as String?) == 'video' ? 1 : 0,
    // Khớp ringingTTL backend (30s) + ring-timeout phía CallBloc — quá hạn
    // mà không tương tác thì plugin tự bắn actionCallTimeout, không đổ
    // chuông vô thời hạn.
    duration: 30000,
    extra: <String, dynamic>{
      'roomId': roomId,
      'callerId': data['callerId'],
      'callType': data['callType'],
    },
    android: const callkit.AndroidParams(
      isCustomNotification: true,
      isShowLogo: false,
      backgroundColor: '#0955fa',
      isShowCallID: false,
    ),
  );
  await FlutterCallkitIncoming.showCallkitIncoming(params);
}

/// Đăng ký FCM token của thiết bị lên server (POST /devices/register-push-token)
/// để server có thể đánh thức app qua push khi không còn WebSocket sống —
/// xem docs/CALL_SYSTEM.md §4.3. Đồng thời cầu nối sự kiện Accept/Decline
/// từ màn hình cuộc gọi đến kiểu native (CallKit/ConnectionService) sang
/// CallBloc — xem docs/CALL_SYSTEM.md §5.2.
class PushService {
  PushService(this._dio);

  final Dio _dio;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<callkit.CallEvent?>? _callKitEventSub;
  StreamSubscription<CallState>? _callBlocSub;

  Future<void> registerToken() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(alert: true, badge: true, sound: true);
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      AppLogger.w('PushService: user từ chối quyền notification — không thể nhận push khi app đóng');
      return;
    }

    final token = await messaging.getToken();
    if (token != null) await _sendTokenToServer(token);

    // Token FCM có thể đổi (reinstall app, xoá data...) — phải re-register
    // mỗi lần đổi, không chỉ lúc app khởi động.
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = messaging.onTokenRefresh.listen(_sendTokenToServer);
  }

  Future<void> _sendTokenToServer(String token) async {
    try {
      await _dio.post('/devices/register-push-token', data: {
        'platform': Platform.isIOS ? 'ios' : 'android',
        'pushToken': token,
      });
      AppLogger.i('PushService: đã đăng ký push token với server');
    } catch (e, st) {
      AppLogger.e('PushService: đăng ký push token lỗi', e, st);
    }
  }

  /// Gọi 1 lần lúc app khởi động (app.dart initState) — bắt cả 2 trường hợp:
  /// (1) app đang chạy sẵn, user bấm Accept/Decline trên CallKit UI trong
  /// lúc app ở background — bắt qua onEvent trực tiếp.
  /// (2) app bị kill, user bấm Accept khiến app cold-start lại — onEvent có
  /// thể miss sự kiện lúc listener chưa kịp gắn, nên check thêm activeCalls()
  /// (theo gợi ý cộng đồng Flutter Vietnam) để không bỏ sót.
  Future<void> wireCallBloc(CallBloc callBloc) async {
    await _callKitEventSub?.cancel();
    _callKitEventSub = FlutterCallkitIncoming.onEvent.listen((event) => _handleCallKitEvent(event, callBloc));

    // endAllCalls() dọn dẹp active call bên native khi CallBloc quay lại
    // idle (đã accept & kết nối xong qua đường bình thường, hoặc đã reject/
    // end) — tránh CallKit UI/activeCalls state bị "treo".
    //
    // incomingRinging + app KHÔNG ở foreground: đây là trường hợp app chỉ bị
    // thu nhỏ (không kill), WebSocket vẫn sống nên offer đến thẳng qua WS
    // bình thường — không đi qua nhánh Push/FCM ở trên (backend chỉ gửi push
    // khi WS thật sự chết). Nếu không xử lý riêng, app sẽ nhận offer, đổi
    // state, nhưng vì UI không ở foreground nên user không thấy/nghe gì cả.
    await _callBlocSub?.cancel();
    _callBlocSub = callBloc.stream.listen((state) {
      if (state.status == CallStatus.idle) {
        FlutterCallkitIncoming.endAllCalls();
      } else if (state.status == CallStatus.incomingRinging && !_isAppInForeground) {
        _showIncomingCallUIFromLiveState(state);
      }
    });

    final activeCalls = await FlutterCallkitIncoming.activeCalls();
    if (activeCalls.isNotEmpty) {
      final roomId = activeCalls.first.extra?['roomId'] as String?;
      if (roomId != null) {
        AppLogger.i('PushService: phát hiện active CallKit call roomId=$roomId lúc khởi động — auto-accept');
        callBloc.markAutoAccept(roomId);
      }
    }
  }

  void _handleCallKitEvent(callkit.CallEvent? event, CallBloc callBloc) {
    switch (event) {
      case callkit.CallEventActionCallAccept(:final callKitParams):
        final roomId = callKitParams.extra?['roomId'] as String?;
        AppLogger.i('PushService: user accept CallKit, roomId=$roomId');
        if (roomId != null) callBloc.markAutoAccept(roomId);
      case callkit.CallEventActionCallDecline(:final callKitParams):
        final roomId = callKitParams.extra?['roomId'] as String?;
        AppLogger.i('PushService: user decline CallKit, roomId=$roomId');
        FlutterCallkitIncoming.endCall(callKitParams.id);
        // Trường hợp offer đã tới qua WS sống (app chỉ bị thu nhỏ, không
        // kill) — CallBloc đang có sẵn state incomingRinging, cần báo reject
        // thật cho caller qua WS. Trường hợp app bị kill/đánh thức qua push,
        // CallBloc chưa có state gì để reject — chỉ cần đóng CallKit UI.
        if (roomId != null) callBloc.rejectIfMatching(roomId);
      case callkit.CallEventActionCallTimeout(:final id):
        AppLogger.i('PushService: CallKit timeout, id=$id');
        FlutterCallkitIncoming.endCall(id);
      case callkit.CallEventActionCallToggleHold(:final isOnHold):
        // Android Telecom tự hold cuộc gọi này khi có cuộc gọi SIM chen
        // ngang (xem CallkitConnection.onHold trong plugin) — chỉ báo lại
        // sự kiện, phải tự mute/unmute mic ở đây.
        AppLogger.i('PushService: CallKit toggle hold, isOnHold=$isOnHold');
        callBloc.setSystemHold(isOnHold);
      default:
        break;
    }
  }

  bool get _isAppInForeground => WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  Future<void> _showIncomingCallUIFromLiveState(CallState state) async {
    final roomId = state.roomId;
    if (roomId == null) return;
    final params = callkit.CallKitParams(
      id: roomId,
      nameCaller: state.peerId ?? 'Người dùng',
      appName: 'call_video',
      type: state.callType == 'video' ? 1 : 0,
      duration: 30000,
      extra: <String, dynamic>{'roomId': roomId},
      android: const callkit.AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        backgroundColor: '#0955fa',
        isShowCallID: false,
      ),
    );
    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }
}
