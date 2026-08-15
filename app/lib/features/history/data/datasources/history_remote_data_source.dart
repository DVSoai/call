import 'package:dio/dio.dart';

import '../models/call_history_model.dart';

class HistoryRemoteDataSource {
  HistoryRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<CallHistoryModel>> getCallHistory({required int limit, required int offset}) async {
    final res = await _dio.get('/calls/history', queryParameters: {'limit': limit, 'offset': offset});
    final data = res.data as Map<String, dynamic>;
    final calls = data['calls'] as List;
    return calls.map((e) => CallHistoryModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
