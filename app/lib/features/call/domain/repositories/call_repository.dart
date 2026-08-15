import 'package:fpdart/fpdart.dart';

import '../../../../core/base/failure.dart';
import '../entities/signaling_message.dart';
import '../entities/turn_credentials.dart';

/// Che giấu chi tiết WebSocket (SignalingService) + REST (turn-credentials)
/// khỏi presentation layer — CallBloc chỉ biết tới interface này.
abstract class CallRepository {
  Future<Either<Failure, TurnCredentials>> getTurnCredentials();

  /// Mở WebSocket /ws — gọi 1 lần cho cả phiên đăng nhập (giữ persistent
  /// connection, giống backend Signaling Hub), không phải cho từng cuộc gọi.
  Future<void> connectSignaling();

  void disconnectSignaling();

  void sendSignaling(SignalingMessage message);

  Stream<SignalingMessage> get signalingMessages;

  bool get isSignalingConnected;
}
