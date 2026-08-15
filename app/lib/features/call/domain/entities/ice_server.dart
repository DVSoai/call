import 'package:equatable/equatable.dart';

class IceServer extends Equatable {
  final List<String> urls;
  final String? username;
  final String? credential;

  const IceServer({required this.urls, this.username, this.credential});

  Map<String, dynamic> toWebRtcConfig() => {
        'urls': urls,
        if (username != null) 'username': username,
        if (credential != null) 'credential': credential,
      };

  @override
  List<Object?> get props => [urls, username, credential];
}
