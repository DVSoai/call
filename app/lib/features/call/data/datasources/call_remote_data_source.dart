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
  /// tiếp joinGroupCall() lúc user bấm Accept. Truyền conversationId để
  /// Server nhận ra "group này đang có cuộc gọi sống" và trả về đúng roomId
  /// đang có (join lại) thay vì tạo room mới mỗi lần bấm gọi.
  Future<String> createGroupCall({
    required List<String> participantIds,
    required String callType,
    String? conversationId,
  }) async {
    final res = await _dio.post('/calls/group', data: {
      'participantIds': participantIds,
      'callType': callType,
      if (conversationId != null) 'conversationId': conversationId,
    });
    return (res.data as Map<String, dynamic>)['roomId'] as String;
  }

  /// POST /calls/:roomId/join — chính thức tham gia SFU room, Server sẽ tự
  /// gửi offer xuống qua WebSocket sau lệnh gọi này.
  Future<void> joinGroupCall(String roomId) async {
    await _dio.post('/calls/$roomId/join');
  }
}
