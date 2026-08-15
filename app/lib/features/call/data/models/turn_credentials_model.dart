import '../../domain/entities/turn_credentials.dart';

class TurnCredentialsModel extends TurnCredentials {
  const TurnCredentialsModel({
    required super.username,
    required super.password,
    required super.ttl,
    required super.urls,
  });

  factory TurnCredentialsModel.fromJson(Map<String, dynamic> json) => TurnCredentialsModel(
        username: json['username'] as String,
        password: json['password'] as String,
        ttl: json['ttl'] as int,
        urls: (json['urls'] as List).map((e) => e as String).toList(),
      );
}
