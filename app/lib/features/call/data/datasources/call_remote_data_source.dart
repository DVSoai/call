import 'package:dio/dio.dart';

import '../models/turn_credentials_model.dart';

class CallRemoteDataSource {
  CallRemoteDataSource(this._dio);

  final Dio _dio;

  Future<TurnCredentialsModel> getTurnCredentials() async {
    final res = await _dio.get('/turn-credentials');
    return TurnCredentialsModel.fromJson(res.data as Map<String, dynamic>);
  }

  /// POST /calls/group — tạo room Group Call (SFU), trả về roomId để gọi
  /// tiếp joinGroupCall() lúc user bấm Accept.
  Future<String> createGroupCall({required List<String> participantIds, required String callType}) async {
    final res = await _dio.post('/calls/group', data: {
      'participantIds': participantIds,
      'callType': callType,
    });
    return (res.data as Map<String, dynamic>)['roomId'] as String;
  }

  /// POST /calls/:roomId/join — chính thức tham gia SFU room, Server sẽ tự
  /// gửi offer xuống qua WebSocket sau lệnh gọi này.
  Future<void> joinGroupCall(String roomId) async {
    await _dio.post('/calls/$roomId/join');
  }
}
