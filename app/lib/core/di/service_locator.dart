import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/dev_login_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/call/data/datasources/call_remote_data_source.dart';
import '../../features/call/data/repositories/call_repository_impl.dart';
import '../../features/call/domain/repositories/call_repository.dart';
import '../../features/call/domain/usecases/create_group_call_usecase.dart';
import '../../features/call/domain/usecases/get_turn_credentials_usecase.dart';
import '../../features/call/domain/usecases/join_group_call_usecase.dart';
import '../../features/call/presentation/bloc/call_bloc.dart';
import '../../features/contacts/data/datasources/contacts_remote_data_source.dart';
import '../../features/contacts/data/repositories/contacts_repository_impl.dart';
import '../../features/contacts/domain/repositories/contacts_repository.dart';
import '../../features/contacts/domain/usecases/list_contacts_usecase.dart';
import '../../features/contacts/domain/usecases/list_incoming_requests_usecase.dart';
import '../../features/contacts/domain/usecases/list_outgoing_requests_usecase.dart';
import '../../features/contacts/domain/usecases/remove_contact_usecase.dart';
import '../../features/contacts/domain/usecases/respond_contact_request_usecase.dart';
import '../../features/contacts/domain/usecases/search_user_by_phone_usecase.dart';
import '../../features/contacts/domain/usecases/send_contact_request_usecase.dart';
import '../../features/history/data/datasources/history_remote_data_source.dart';
import '../../features/history/data/repositories/history_repository_impl.dart';
import '../../features/history/domain/repositories/history_repository.dart';
import '../../features/history/domain/usecases/get_call_history_usecase.dart';
import '../../features/message/data/datasources/message_remote_data_source.dart';
import '../../features/message/data/repositories/message_repository_impl.dart';
import '../../features/message/domain/repositories/message_repository.dart';
import '../../features/message/domain/usecases/add_participants_usecase.dart';
import '../../features/message/domain/usecases/create_conversation_usecase.dart';
import '../../features/message/domain/usecases/leave_conversation_usecase.dart';
import '../../features/message/domain/usecases/list_conversations_usecase.dart';
import '../../features/message/domain/usecases/list_messages_usecase.dart';
import '../network/auth_interceptor.dart';
import '../network/dio_client.dart';
import '../network/force_logout_interceptor.dart';
import '../network/session_expiry_notifier.dart';
import '../network/signaling_service.dart';
import '../push/push_service.dart';
import '../storage/token_storage.dart';

final getIt = GetIt.instance;

/// Đăng ký thủ công (không dùng injectable/codegen) — đơn giản, đủ dùng
/// với quy mô app hiện tại (đúng quy ước đã khảo sát từ Multime_Version_2).
///
/// AuthBloc/CallBloc đăng ký lazySingleton vì cả 2 sống suốt phiên đăng
/// nhập (CallBloc phải luôn lắng nghe signaling để nhận cuộc gọi đến bất
/// kể đang ở màn hình nào). Các Bloc "ngắn hạn" theo từng màn hình (vd.
/// HistoryBloc) KHÔNG đăng ký ở đây — tạo trực tiếp tại nơi dùng qua
/// BlocProvider(create: (_) => HistoryBloc(getIt())), xem app_router.dart.
Future<void> setupServiceLocator() async {
  // ---- core ----
  getIt.registerLazySingleton(() => const FlutterSecureStorage());
  getIt.registerLazySingleton(() => TokenStorage(getIt()));
  getIt.registerLazySingleton(() => SessionExpiryNotifier());
  getIt.registerLazySingleton(() => AuthInterceptor(getIt()));
  getIt.registerLazySingleton(() => ForceLogoutInterceptor(getIt(), getIt()));
  getIt.registerLazySingleton(() => DioClient.create(getIt(), getIt()));
  // 1 kết nối WebSocket dùng chung cho cả call signaling lẫn chat (xem
  // core/network/signaling_service.dart) — vòng đời do CallBloc quản lý
  // (connect lúc signalingStarted, disconnect lúc logout).
  getIt.registerLazySingleton(() => SignalingService());
  getIt.registerLazySingleton(() => PushService(getIt()));

  // ---- auth ----
  getIt.registerLazySingleton(() => AuthRemoteDataSource(getIt()));
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(getIt(), getIt()));
  getIt.registerFactory(() => DevLoginUseCase(getIt()));
  getIt.registerLazySingleton(
    () => AuthBloc(
      devLoginUseCase: getIt(),
      authRepository: getIt(),
      sessionExpiryNotifier: getIt(),
    ),
  );

  // ---- call ----
  getIt.registerLazySingleton(() => CallRemoteDataSource(getIt()));
  getIt.registerLazySingleton<CallRepository>(() => CallRepositoryImpl(getIt(), getIt(), getIt()));
  getIt.registerFactory(() => GetTurnCredentialsUseCase(getIt()));
  getIt.registerFactory(() => CreateGroupCallUseCase(getIt()));
  getIt.registerFactory(() => JoinGroupCallUseCase(getIt()));
  getIt.registerLazySingleton(
    () => CallBloc(
      repository: getIt(),
      getTurnCredentialsUseCase: getIt(),
      createGroupCallUseCase: getIt(),
      joinGroupCallUseCase: getIt(),
      tokenStorage: getIt(),
    ),
  );

  // ---- history ----
  getIt.registerLazySingleton(() => HistoryRemoteDataSource(getIt()));
  getIt.registerLazySingleton<HistoryRepository>(() => HistoryRepositoryImpl(getIt()));
  getIt.registerFactory(() => GetCallHistoryUseCase(getIt()));

  // ---- contacts ----
  // ContactsBloc/ContactRequestsBloc/ContactSearchBloc KHÔNG đăng ký ở đây
  // — tạo trực tiếp tại route (app_router.dart), giống HistoryBloc, vì đều
  // là Bloc "ngắn hạn" theo màn hình.
  getIt.registerLazySingleton(() => ContactsRemoteDataSource(getIt()));
  getIt.registerLazySingleton<ContactsRepository>(() => ContactsRepositoryImpl(getIt()));
  getIt.registerFactory(() => SearchUserByPhoneUseCase(getIt()));
  getIt.registerFactory(() => SendContactRequestUseCase(getIt()));
  getIt.registerFactory(() => ListIncomingRequestsUseCase(getIt()));
  getIt.registerFactory(() => ListOutgoingRequestsUseCase(getIt()));
  getIt.registerFactory(() => RespondContactRequestUseCase(getIt()));
  getIt.registerFactory(() => ListContactsUseCase(getIt()));
  getIt.registerFactory(() => RemoveContactUseCase(getIt()));

  // ---- message ----
  // ConversationsBloc/ChatBloc/NewConversationBloc KHÔNG đăng ký ở đây —
  // tạo trực tiếp tại route, cùng lý do với contacts. sendChatMessage/
  // incomingMessages đi thẳng qua MessageRepository (giống CallBloc dùng
  // thẳng CallRepository cho signaling) — không có usecase riêng vì đây là
  // luồng WebSocket real-time, không phải 1 REST action rời rạc.
  getIt.registerLazySingleton(() => MessageRemoteDataSource(getIt()));
  getIt.registerLazySingleton<MessageRepository>(() => MessageRepositoryImpl(getIt(), getIt()));
  getIt.registerFactory(() => CreateConversationUseCase(getIt()));
  getIt.registerFactory(() => ListConversationsUseCase(getIt()));
  getIt.registerFactory(() => ListMessagesUseCase(getIt()));
  getIt.registerFactory(() => AddParticipantsUseCase(getIt()));
  getIt.registerFactory(() => LeaveConversationUseCase(getIt()));
}
