import '../../domain/entities/call_history_entry.dart';

class CallHistoryModel extends CallHistoryEntry {
  const CallHistoryModel({
    required super.roomId,
    required super.createdBy,
    required super.callType,
    required super.status,
    required super.startedAt,
    required super.participants,
    super.endedAt,
  });

  factory CallHistoryModel.fromJson(Map<String, dynamic> json) => CallHistoryModel(
        roomId: json['roomId'] as String,
        createdBy: json['createdBy'] as String,
        callType: json['callType'] as String,
        status: CallHistoryStatus.fromJson(json['status'] as String),
        startedAt: DateTime.parse(json['startedAt'] as String),
        endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt'] as String) : null,
        participants: (json['participants'] as List).map((e) => e as String).toList(),
      );
}
