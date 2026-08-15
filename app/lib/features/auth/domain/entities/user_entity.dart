import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String phone;
  final String displayName;
  final String preferredLanguage;

  const UserEntity({
    required this.id,
    required this.phone,
    required this.displayName,
    required this.preferredLanguage,
  });

  @override
  List<Object?> get props => [id, phone, displayName, preferredLanguage];
}
