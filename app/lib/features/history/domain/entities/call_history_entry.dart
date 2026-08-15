import 'package:equatable/equatable.dart';

/// [apiValue] tách riêng khỏi tên enum Dart nên đổi tên case không làm vỡ
/// hợp đồng JSON với backend (backend/internal/entity/call.go). [label]
/// dùng thẳng cho UI (xem history_page.dart).
enum CallHistoryStatus {
  missed('missed', 'Cuộc gọi nhỡ'),
  rejected('rejected', 'Đã từ chối'),
  completed('completed', 'Đã kết thúc'),
  ongoing('ongoing', 'Đang diễn ra');

  const CallHistoryStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static CallHistoryStatus fromJson(String value) => CallHistoryStatus.values.firstWhere(
        (s) => s.apiValue == value,
        orElse: () => throw ArgumentError('CallHistoryStatus không hợp lệ: $value'),
      );
}

class CallHistoryEntry extends Equatable {
  final String roomId;
  final String createdBy;
  final String callType; // "audio" | "video"
  final CallHistoryStatus status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final List<String> participants;

  const CallHistoryEntry({
    required this.roomId,
    required this.createdBy,
    required this.callType,
    required this.status,
    required this.startedAt,
    required this.participants,
    this.endedAt,
  });

  @override
  List<Object?> get props => [roomId, createdBy, callType, status, startedAt, endedAt, participants];
}
