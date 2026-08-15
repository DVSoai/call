import 'package:equatable/equatable.dart';

/// [apiValue] tách riêng khỏi tên enum Dart — khớp
/// backend/internal/entity/conversation.go. [label] dùng thẳng cho UI.
enum ConversationType {
  direct('direct', 'Trò chuyện'),
  group('group', 'Nhóm');

  const ConversationType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static ConversationType fromJson(String value) => ConversationType.values.firstWhere(
        (t) => t.apiValue == value,
        orElse: () => throw ArgumentError('ConversationType không hợp lệ: $value'),
      );
}

/// Cố tình KHÔNG dùng lại UserSummaryEntity của features/contacts — mỗi
/// feature giữ domain riêng, tránh phụ thuộc chéo giữa 2 feature ngang hàng
/// (Clean Architecture: feature contacts đổi entity không được kéo theo lỗi
/// build ở feature message).
class ConversationParticipantEntity extends Equatable {
  final String id;
  final String phone;
  final String displayName;

  const ConversationParticipantEntity({
    required this.id,
    required this.phone,
    required this.displayName,
  });

  @override
  List<Object?> get props => [id, phone, displayName];
}

class ConversationEntity extends Equatable {
  final String id;
  final ConversationType type;
  final String? name;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;
  final List<ConversationParticipantEntity> participants;

  const ConversationEntity({
    required this.id,
    required this.type,
    required this.createdBy,
    required this.createdAt,
    this.name,
    this.lastMessageAt,
    this.lastMessagePreview,
    this.participants = const [],
  });

  /// Tên hiển thị: group dùng [name] nếu có, direct dùng tên người còn lại
  /// (loại trừ chính mình) — fallback về phone nếu displayName rỗng.
  String displayTitle(String currentUserId) {
    if (type == ConversationType.group) {
      return (name != null && name!.isNotEmpty) ? name! : 'Nhóm chat';
    }
    final others = participants.where((p) => p.id != currentUserId);
    if (others.isEmpty) return name ?? 'Cuộc trò chuyện';
    final peer = others.first;
    return peer.displayName.isNotEmpty ? peer.displayName : peer.phone;
  }

  /// userId người còn lại — null với group (dùng [groupParticipantIdsFor]
  /// thay thế) hoặc khi participants rỗng. Dùng để hiện nút gọi 1-1 trực
  /// tiếp từ màn hình chat.
  String? peerIdFor(String currentUserId) {
    if (type == ConversationType.group) return null;
    final others = participants.where((p) => p.id != currentUserId);
    return others.isEmpty ? null : others.first.id;
  }

  /// Danh sách participantIds cho Group Call (đã loại trừ currentUserId) —
  /// rỗng nếu không phải conversation "group". Dùng để hiện nút "Gọi nhóm"
  /// từ màn hình chat.
  List<String> groupParticipantIdsFor(String currentUserId) {
    if (type != ConversationType.group) return const [];
    return participants.where((p) => p.id != currentUserId).map((p) => p.id).toList();
  }

  ConversationEntity copyWith({DateTime? lastMessageAt, String? lastMessagePreview}) => ConversationEntity(
        id: id,
        type: type,
        name: name,
        createdBy: createdBy,
        createdAt: createdAt,
        participants: participants,
        lastMessageAt: lastMessageAt ?? this.lastMessageAt,
        lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      );

  @override
  List<Object?> get props =>
      [id, type, name, createdBy, createdAt, lastMessageAt, lastMessagePreview, participants];
}
