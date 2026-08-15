import 'package:dio/dio.dart';

import '../models/contact_model.dart';
import '../models/user_summary_model.dart';

class ContactsRemoteDataSource {
  ContactsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<UserSummaryModel> searchByPhone(String phone) async {
    final res = await _dio.get('/users/search', queryParameters: {'phone': phone});
    return UserSummaryModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> sendRequest(String addresseeId) async {
    await _dio.post('/contacts/requests', data: {'addresseeId': addresseeId});
  }

  Future<List<ContactModel>> listIncomingRequests() async {
    final res = await _dio.get('/contacts/requests', queryParameters: {'type': 'incoming'});
    final data = res.data as Map<String, dynamic>;
    final requests = data['requests'] as List;
    return requests.map((e) => ContactModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ContactModel>> listOutgoingRequests() async {
    final res = await _dio.get('/contacts/requests', queryParameters: {'type': 'outgoing'});
    final data = res.data as Map<String, dynamic>;
    final requests = data['requests'] as List;
    return requests.map((e) => ContactModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> respondRequest({required String contactId, required bool accept}) async {
    final action = accept ? 'accept' : 'reject';
    await _dio.put('/contacts/requests/$contactId/$action');
  }

  Future<List<ContactModel>> listContacts() async {
    final res = await _dio.get('/contacts');
    final data = res.data as Map<String, dynamic>;
    final contacts = data['contacts'] as List;
    return contacts.map((e) => ContactModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> removeContact(String contactId) async {
    await _dio.delete('/contacts/$contactId');
  }
}
