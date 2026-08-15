import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/bloc/abstract_bloc_with_api.dart';
import '../../../../core/network/session_expiry_notifier.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/dev_login_usecase.dart';

part 'auth_bloc.freezed.dart';
part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends BlocWithApi<AuthEvent, AuthState> {
  AuthBloc({
    required DevLoginUseCase devLoginUseCase,
    required AuthRepository authRepository,
    required SessionExpiryNotifier sessionExpiryNotifier,
  })  : _devLoginUseCase = devLoginUseCase,
        _authRepository = authRepository,
        super(const AuthState()) {
    on<AuthSessionCheckRequested>(_onSessionCheckRequested);
    on<AuthLoginSubmitted>(_onLoginSubmitted);
    on<AuthLoggedOut>(_onLoggedOut);

    // JWT hết hạn/không hợp lệ (401 ở bất kỳ request nào) → ForceLogoutInterceptor
    // đã xoá token cục bộ, ở đây chỉ cần đồng bộ lại AuthState để router
    // tự điều hướng về LoginPage (xem core/router/app_router.dart).
    _sessionExpirySub = sessionExpiryNotifier.onSessionExpired.listen((_) => add(const AuthEvent.loggedOut()));
  }

  final DevLoginUseCase _devLoginUseCase;
  final AuthRepository _authRepository;
  late final StreamSubscription<void> _sessionExpirySub;

  Future<void> _onSessionCheckRequested(AuthSessionCheckRequested event, Emitter<AuthState> emit) async {
    final token = await _authRepository.getSavedToken();
    if (token == null || token.isEmpty) {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
      return;
    }
    final user = await _authRepository.getSavedUser();
    emit(state.copyWith(status: AuthStatus.authenticated, user: user));
  }

  Future<void> _onLoginSubmitted(AuthLoginSubmitted event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    await callApi<UserEntity, String>(
      useCase: _devLoginUseCase,
      param: event.phone,
      onSuccess: (user) async => emit(state.copyWith(status: AuthStatus.authenticated, user: user)),
      onFailure: (message) => emit(state.copyWith(status: AuthStatus.failure, errorMessage: message)),
    );
  }

  Future<void> _onLoggedOut(AuthLoggedOut event, Emitter<AuthState> emit) async {
    await _authRepository.logout();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  @override
  Future<void> close() {
    _sessionExpirySub.cancel();
    return super.close();
  }
}
