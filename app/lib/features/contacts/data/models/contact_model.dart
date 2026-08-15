import '../../domain/entities/contact_entity.dart';
import 'user_summary_model.dart';

class ContactModel extends ContactEntity {
  const ContactModel({
    required super.id,
    required super.status,
    required super.requesterId,
    required super.createdAt,
    required super.otherUser,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) => ContactModel(
        id: json['id'] as String,
        status: ContactStatus.fromJson(json['status'] as String),
        requesterId: json['requesterId'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        otherUser: UserSummaryModel.fromJson(json['otherUser'] as Map<String, dynamic>),
      );
}
