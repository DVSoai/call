import '../../domain/entities/conversation_entity.dart';

class ConversationParticipantModel extends ConversationParticipantEntity {
  const ConversationParticipantModel({
    required super.id,
    required super.phone,
    required super.displayName,
  });

  factory ConversationParticipantModel.fromJson(Map<String, dynamic> json) => ConversationParticipantModel(
        id: json['id'] as String,
        phone: json['phone'] as String,
        displayName: json['displayName'] as String,
      );
}

class ConversationModel extends ConversationEntity {
  const ConversationModel({
    required super.id,
    required super.type,
    required super.createdBy,
    required super.createdAt,
    super.name,
    super.lastMessageAt,
    super.lastMessagePreview,
    super.participants,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) => ConversationModel(
        id: json['id'] as String,
        type: ConversationType.fromJson(json['type'] as String),
        name: json['name'] as String?,
        createdBy: json['createdBy'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        lastMessageAt: json['lastMessageAt'] != null ? DateTime.parse(json['lastMessageAt'] as String) : null,
        lastMessagePreview: json['lastMessagePreview'] as String?,
        participants: ((json['participants'] as List?) ?? const [])
            .map((e) => ConversationParticipantModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
