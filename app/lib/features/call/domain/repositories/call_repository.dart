import 'package:fpdart/fpdart.dart';

import '../../../../core/base/failure.dart';
import '../entities/signaling_message.dart';
import '../entities/turn_credentials.dart';

/// Che giấu chi tiết WebSocket (SignalingService) + REST (turn-credentials)
/// khỏi presentation layer — CallBloc chỉ biết tới interface này.
abstract class CallRepository {
  Future<Either<Failure, TurnCredentials>> getTurnCredentials();

  /// Tạo room Group Call (SFU), trả về roomId.
  Future<Either<Failure, String>> createGroupCall({
    required List<String> participantIds,
    required String callType,
  });

  /// Chính thức tham gia SFU room sau khi user bấm Accept — Server tự gửi
  /// offer xuống qua WebSocket sau lệnh gọi này.
  Future<Either<Failure, void>> joinGroupCall(String roomId);

  /// Mở WebSocket /ws — gọi 1 lần cho cả phiên đăng nhập (giữ persistent
  /// connection, giống backend Signaling Hub), không phải cho từng cuộc gọi.
  Future<void> connectSignaling();

  void disconnectSignaling();

  void sendSignaling(SignalingMessage message);

  Stream<SignalingMessage> get signalingMessages;

  bool get isSignalingConnected;
}
