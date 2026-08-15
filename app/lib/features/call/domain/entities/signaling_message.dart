import 'package:equatable/equatable.dart';

/// Đúng 5 loại message signaling đã chốt ở backend/internal/signaling —
/// xem docs/CALL_SYSTEM.md §4.1. Đổi enum này PHẢI đổi cùng lúc với backend.
enum SignalingMessageType {
  offer,
  answer,
  iceCandidate,
  callEnd,
  callReject;

  String get wireValue => switch (this) {
        SignalingMessageType.offer => 'offer',
        SignalingMessageType.answer => 'answer',
        SignalingMessageType.iceCandidate => 'ice-candidate',
        SignalingMessageType.callEnd => 'call-end',
        SignalingMessageType.callReject => 'call-reject',
      };

  static SignalingMessageType fromWire(String value) => switch (value) {
        'offer' => SignalingMessageType.offer,
        'answer' => SignalingMessageType.answer,
        'ice-candidate' => SignalingMessageType.iceCandidate,
        'call-end' => SignalingMessageType.callEnd,
        'call-reject' => SignalingMessageType.callReject,
        _ => throw ArgumentError('SignalingMessageType không xác định: $value'),
      };
}

/// callId đóng vai trò roomId — xem backend/ARCHITECTURE.md mục
/// "room-ready". Với call 1-1, room luôn có đúng 2 người: from/to.
class SignalingMessage extends Equatable {
  final SignalingMessageType type;
  final String from;
  final String to;
  final String callId;
  final String? sdp;
  final Map<String, dynamic>? candidate;
  final String? callType; // "audio" | "video", chỉ có ý nghĩa ở offer

  // "group" cho Group Call (SFU) — null/"direct" cho call 1-1 như cũ. Field
  // mới hoàn toàn, không đổi field cũ nào (xem backend Payload.Mode).
  final String? mode;

  const SignalingMessage({
    required this.type,
    required this.from,
    required this.to,
    required this.callId,
    this.sdp,
    this.candidate,
    this.callType,
    this.mode,
  });

  bool get isGroup => mode == 'group';

  factory SignalingMessage.fromJson(Map<String, dynamic> json) {
    final payload = (json['payload'] as Map<String, dynamic>?) ?? const {};
    return SignalingMessage(
      type: SignalingMessageType.fromWire(json['type'] as String),
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
      callId: json['callId'] as String? ?? '',
      sdp: payload['sdp'] as String?,
      candidate: (payload['candidate'] as Map?)?.cast<String, dynamic>(),
      callType: payload['callType'] as String?,
      mode: payload['mode'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.wireValue,
        'from': from,
        'to': to,
        'callId': callId,
        'payload': {
          if (sdp != null) 'sdp': sdp,
          if (candidate != null) 'candidate': candidate,
          if (callType != null) 'callType': callType,
          if (mode != null) 'mode': mode,
        },
      };

  @override
  List<Object?> get props => [type, from, to, callId, sdp, candidate, callType, mode];
}
