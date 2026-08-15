import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.phone,
    required super.displayName,
    required super.preferredLanguage,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        phone: json['phone'] as String,
        displayName: json['displayName'] as String? ?? '',
        preferredLanguage: json['preferredLanguage'] as String? ?? 'vi',
      );
}
