import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/base/failure.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../domain/entities/contact_entity.dart';
import '../../domain/entities/user_summary_entity.dart';
import '../../domain/repositories/contacts_repository.dart';
import '../datasources/contacts_remote_data_source.dart';

class ContactsRepositoryImpl implements ContactsRepository {
  ContactsRepositoryImpl(this._remote);

  final ContactsRemoteDataSource _remote;

  @override
  Future<Either<Failure, UserSummaryEntity>> searchByPhone(String phone) async {
    try {
      return Right(await _remote.searchByPhone(phone));
    } on DioException catch (e) {
      return Left(Failure(AppException.fromDioException(e).message));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> sendRequest(String addresseeId) async {
    try {
      await _remote.sendRequest(addresseeId);
      return const Right(unit);
    } on DioException catch (e) {
      return Left(Failure(AppException.fromDioException(e).message));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ContactEntity>>> listIncomingRequests() async {
    try {
      return Right(await _remote.listIncomingRequests());
    } on DioException catch (e) {
      return Left(Failure(AppException.fromDioException(e).message));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ContactEntity>>> listOutgoingRequests() async {
    try {
      return Right(await _remote.listOutgoingRequests());
    } on DioException catch (e) {
      return Left(Failure(AppException.fromDioException(e).message));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> respondRequest({required String contactId, required bool accept}) async {
    try {
      await _remote.respondRequest(contactId: contactId, accept: accept);
      return const Right(unit);
    } on DioException catch (e) {
      return Left(Failure(AppException.fromDioException(e).message));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ContactEntity>>> listContacts() async {
    try {
      return Right(await _remote.listContacts());
    } on DioException catch (e) {
      return Left(Failure(AppException.fromDioException(e).message));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> removeContact(String contactId) async {
    try {
      await _remote.removeContact(contactId);
      return const Right(unit);
    } on DioException catch (e) {
      return Left(Failure(AppException.fromDioException(e).message));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}
