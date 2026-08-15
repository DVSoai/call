import 'package:equatable/equatable.dart';

import 'ice_server.dart';

/// Kết quả GET /turn-credentials — credential time-limited theo cơ chế
/// shared-secret của coturn (xem backend/internal/api/handlers_turn.go).
class TurnCredentials extends Equatable {
  final String username;
  final String password;
  final int ttl;
  final List<String> urls;

  const TurnCredentials({
    required this.username,
    required this.password,
    required this.ttl,
    required this.urls,
  });

  /// STUN công cộng của Google làm fallback + TURN server thật của mình.
  /// STUN không cần credential (chỉ giúp khám phá public IP), TURN thì
  /// cần username/password vừa cấp.
  List<IceServer> toIceServers() => [
        const IceServer(urls: ['stun:stun.l.google.com:19302']),
        IceServer(urls: urls, username: username, credential: password),
      ];

  @override
  List<Object?> get props => [username, password, ttl, urls];
}
