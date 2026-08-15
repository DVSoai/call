import 'package:dio/dio.dart';

import '../models/turn_credentials_model.dart';

class CallRemoteDataSource {
  CallRemoteDataSource(this._dio);

  final Dio _dio;

  Future<TurnCredentialsModel> getTurnCredentials() async {
    final res = await _dio.get('/turn-credentials');
    return TurnCredentialsModel.fromJson(res.data as Map<String, dynamic>);
  }
}
