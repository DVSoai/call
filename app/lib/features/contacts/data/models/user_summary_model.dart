import '../../domain/entities/user_summary_entity.dart';

class UserSummaryModel extends UserSummaryEntity {
  const UserSummaryModel({
    required super.id,
    required super.phone,
    required super.displayName,
  });

  factory UserSummaryModel.fromJson(Map<String, dynamic> json) => UserSummaryModel(
        id: json['id'] as String,
        phone: json['phone'] as String,
        displayName: json['displayName'] as String,
      );
}
