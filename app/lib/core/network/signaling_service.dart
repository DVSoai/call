import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../features/call/domain/entities/signaling_message.dart';
import '../constants/app_constants.dart';
import '../utils/app_logger.dart';

/// Bọc [WebSocketChannel] kết nối GET /ws — 1 kết nối persistent cho cả
/// phiên đăng nhập, tương ứng Signaling Hub phía backend
/// (backend/internal/signaling/hub.go).
///
/// Đặt ở core (không phải features/call) vì kết nối này dùng CHUNG cho cả
/// call signaling lẫn chat (message type "chat-message") — xem
/// backend/internal/signaling/handlers_chat.go, không tách chat-server
/// riêng. [messages] chỉ phát 5 loại call-signaling gốc (offer/answer/
/// ice-candidate/call-end/call-reject); [chatMessages] phát riêng frame
/// "chat-message" dạng JSON thô — features/message tự parse thành entity
/// của nó, core không cần biết cấu trúc chat.
///
/// Tự động reconnect khi mất kết nối ngoài ý muốn (rớt mạng, server
/// restart...) — quan trọng với app gọi điện vì mất signaling đồng nghĩa
/// không nhận được cuộc gọi đến. Backoff tăng dần, KHÔNG giới hạn số lần
/// thử (bỏ cuộc reconnect là không chấp nhận được với 1 app gọi điện,
/// khác các use-case như chat). Pattern tham khảo từ `WebSocketManager`
/// của package tendoo_websocket (retry backoff + connection-stability
/// timer để reset backoff sau khi kết nối ổn định trở lại).
class SignalingService {
  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;
  StreamController<SignalingMessage>? _controller;
  StreamController<Map<String, dynamic>>? _chatController;

  String? _token;
  bool _isConnecting = false;
  bool _isDisposing = false;

  int _retryCount = 0;
  static const _maxRetryDelaySeconds = 30;

  Timer? _reconnectTimer;
  Timer? _stabilityTimer;

  bool get isConnected => _channel != null;

  /// Gọi 1 lần sau khi đăng nhập (CallBloc._onSignalingStarted) — không
  /// cần gọi lại khi mất mạng tạm thời, service tự reconnect nền.
  Future<void> connect(String token) async {
    _token = token;
    _isDisposing = false;
    _controller ??= StreamController<SignalingMessage>.broadcast();
    _chatController ??= StreamController<Map<String, dynamic>>.broadcast();
    await _openChannel();
  }

  Stream<SignalingMessage> get messages => _controller?.stream ?? const Stream.empty();

  /// Frame thô (JSON đã decode) cho type "chat-message" — features/message
  /// tự parse thành ChatMessageEntity, core không phụ thuộc ngược vào
  /// domain của feature khác.
  Stream<Map<String, dynamic>> get chatMessages => _chatController?.stream ?? const Stream.empty();

  void send(SignalingMessage message) => sendRaw(message.toJson());

  void sendRaw(Map<String, dynamic> json) {
    final channel = _channel;
    if (channel == null) {
      AppLogger.w('SignalingService: send khi chưa connect — bỏ qua message ${json['type']}');
      return;
    }
    channel.sink.add(jsonEncode(json));
  }

  /// Ngắt hẳn — gọi khi logout/app teardown. Khác với mất mạng ngoài ý
  /// muốn, lần này service KHÔNG tự reconnect nữa.
  Future<void> disconnect() async {
    _isDisposing = true;
    _reconnectTimer?.cancel();
    _stabilityTimer?.cancel();
    _retryCount = 0;
    _token = null;
    await _teardownChannel();
    await _controller?.close();
    _controller = null;
    await _chatController?.close();
    _chatController = null;
  }

  Future<void> _openChannel() async {
    if (_isConnecting || isConnected) return;
    final token = _token;
    if (token == null) return;

    _isConnecting = true;
    try {
      final uri = Uri.parse('${AppConstants.wsBaseUrl}/ws').replace(queryParameters: {'token': token});
      final channel = WebSocketChannel.connect(uri);
      await channel.ready; // throws nếu handshake thất bại (vd. token sai)

      _channel = channel;
      _channelSubscription = channel.stream.listen(
        _onRawMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: true,
      );
      _isConnecting = false;
      AppLogger.i('SignalingService: WS connected');

      // Reset backoff sau 5s giữ kết nối ổn định — tránh 1 lần rớt mạng
      // thoáng qua làm delay lần reconnect tiếp theo bị kéo dài vô lý.
      _stabilityTimer?.cancel();
      _stabilityTimer = Timer(const Duration(seconds: 5), () => _retryCount = 0);
    } catch (e, st) {
      _isConnecting = false;
      AppLogger.e('SignalingService: connect lỗi', e, st);
      _scheduleReconnect();
    }
  }

  void _onRawMessage(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      if (json['type'] == 'chat-message') {
        _chatController?.add(json);
        return;
      }
      _controller?.add(SignalingMessage.fromJson(json));
    } catch (e, st) {
      AppLogger.e('SignalingService: parse message lỗi', e, st);
    }
  }

  void _onError(Object error, StackTrace st) {
    AppLogger.e('SignalingService: WS error', error, st);
    _handleUnexpectedDrop();
  }

  void _onDone() {
    if (_isDisposing) return;
    AppLogger.w('SignalingService: WS đóng ngoài ý muốn');
    _handleUnexpectedDrop();
  }

  Future<void> _handleUnexpectedDrop() async {
    await _teardownChannel();
    if (!_isDisposing) _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_isDisposing) return;
    _retryCount++;
    final delaySeconds = min(_retryCount * 3, _maxRetryDelaySeconds);
    AppLogger.w('SignalingService: reconnect sau ${delaySeconds}s (lần thử $_retryCount)');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), _openChannel);
  }

  Future<void> _teardownChannel() async {
    await _channelSubscription?.cancel();
    await _channel?.sink.close();
    _channelSubscription = null;
    _channel = null;
  }
}
