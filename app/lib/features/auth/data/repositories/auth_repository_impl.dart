import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/base/failure.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._tokenStorage);

  final AuthRemoteDataSource _remote;
  final TokenStorage _tokenStorage;

  @override
  Future<Either<Failure, UserEntity>> devLogin(String phone) async {
    try {
      final result = await _remote.devLogin(phone);
      await _tokenStorage.saveSession(
        token: result.token,
        userId: result.user.id,
        phone: result.user.phone,
        displayName: result.user.displayName,
        preferredLanguage: result.user.preferredLanguage,
      );
      return Right(result.user);
    } on DioException catch (e) {
      return Left(Failure(AppException.fromDioException(e).message));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<String?> getSavedToken() => _tokenStorage.readToken();

  @override
  Future<UserEntity?> getSavedUser() async {
    final profile = await _tokenStorage.readUserProfile();
    if (profile == null) return null;
    return UserEntity(
      id: profile['id']!,
      phone: profile['phone']!,
      displayName: profile['displayName']!,
      preferredLanguage: profile['preferredLanguage']!,
    );
  }

  @override
  Future<Either<Failure, UserEntity>> updatePreferredLanguage(String language) async {
    try {
      await _remote.updatePreferredLanguage(language);
      await _tokenStorage.writePreferredLanguage(language);
      final profile = await _tokenStorage.readUserProfile();
      if (profile == null) return const Left(Failure('Chưa đăng nhập'));
      return Right(UserEntity(
        id: profile['id']!,
        phone: profile['phone']!,
        displayName: profile['displayName']!,
        preferredLanguage: profile['preferredLanguage']!,
      ));
    } on DioException catch (e) {
      return Left(Failure(AppException.fromDioException(e).message));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<void> logout() => _tokenStorage.clear();
}
