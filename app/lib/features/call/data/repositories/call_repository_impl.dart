import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/base/failure.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/network/signaling_service.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/signaling_message.dart';
import '../../domain/entities/turn_credentials.dart';
import '../../domain/repositories/call_repository.dart';
import '../datasources/call_remote_data_source.dart';

class CallRepositoryImpl implements CallRepository {
  CallRepositoryImpl(this._remote, this._signaling, this._tokenStorage);

  final CallRemoteDataSource _remote;
  final SignalingService _signaling;
  final TokenStorage _tokenStorage;

  @override
  Future<Either<Failure, TurnCredentials>> getTurnCredentials() async {
    try {
      final model = await _remote.getTurnCredentials();
      return Right(model);
    } on DioException catch (e) {
      return Left(Failure(AppException.fromDioException(e).message));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> createGroupCall({
    required List<String> participantIds,
    required String callType,
  }) async {
    try {
      final roomId = await _remote.createGroupCall(participantIds: participantIds, callType: callType);
      return Right(roomId);
    } on DioException catch (e) {
      return Left(Failure(AppException.fromDioException(e).message));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> joinGroupCall(String roomId) async {
    try {
      await _remote.joinGroupCall(roomId);
      return const Right(null);
    } on DioException catch (e) {
      return Left(Failure(AppException.fromDioException(e).message));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<void> connectSignaling() async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw StateError('CallRepository: chưa đăng nhập — không có token để mở WebSocket');
    }
    await _signaling.connect(token);
  }

  @override
  void disconnectSignaling() => _signaling.disconnect();

  @override
  void sendSignaling(SignalingMessage message) => _signaling.send(message);

  @override
  Stream<SignalingMessage> get signalingMessages => _signaling.messages;

  @override
  bool get isSignalingConnected => _signaling.isConnected;
}
