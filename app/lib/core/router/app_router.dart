import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/call/presentation/bloc/call_bloc.dart';
import '../../features/call/presentation/pages/call_page.dart';
import '../../features/contacts/presentation/bloc/contact_requests_bloc.dart';
import '../../features/contacts/presentation/bloc/contact_search_bloc.dart';
import '../../features/contacts/presentation/bloc/contacts_bloc.dart';
import '../../features/contacts/presentation/pages/contact_requests_page.dart';
import '../../features/contacts/presentation/pages/contact_search_page.dart';
import '../../features/contacts/presentation/pages/contacts_page.dart';
import '../../features/history/presentation/bloc/history_bloc.dart';
import '../../features/history/presentation/pages/history_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/pages/splash_page.dart';
import '../../features/message/presentation/bloc/chat_bloc.dart';
import '../../features/message/presentation/bloc/conversations_bloc.dart';
import '../../features/message/presentation/bloc/new_conversation_bloc.dart';
import '../../features/message/presentation/pages/chat_page.dart';
import '../../features/message/presentation/pages/message_page.dart';
import '../../features/message/presentation/pages/new_conversation_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../di/service_locator.dart';
import '../utils/app_logger.dart';
import 'app_shell.dart';
import 'go_router_refresh_stream.dart';

/// redirect tập trung toàn bộ luồng điều hướng theo AuthState + CallState
/// — page không tự gọi context.go() cho các case "phải ở đâu", chỉ gọi
/// context.push() cho hành động chủ động của user.
///
/// 4 tab chính (Home/Message/Contacts/Profile) nằm trong StatefulShellRoute
/// — mỗi tab giữ navigation stack riêng. Lịch sử cuộc gọi KHÔNG phải tab
/// riêng (chốt lại: chỉ 4 tab) — vào qua ProfilePage > "Lịch sử cuộc gọi"
/// bằng context.push('/history'), nằm ngoài shell nên có nút back riêng.
GoRouter buildAppRouter({required AuthBloc authBloc, required CallBloc callBloc}) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: Listenable.merge([
      GoRouterRefreshStream(authBloc.stream),
      GoRouterRefreshStream(callBloc.stream),
    ]),
    redirect: (context, state) {
      final authStatus = authBloc.state.status;
      final loc = state.matchedLocation;

      if (authStatus == AuthStatus.initial || authStatus == AuthStatus.loading) {
        return loc == '/splash' ? null : '/splash';
      }

      final authenticated = authStatus == AuthStatus.authenticated;
      if (!authenticated) {
        return loc == '/login' ? null : '/login';
      }
      if (loc == '/login' || loc == '/splash') return '/home';

      final callActive = callBloc.state.status != CallStatus.idle;
      if (callActive && loc != '/call') {
        AppLogger.w('router: redirect -> /call (callBloc.status=${callBloc.state.status}, from=$loc)');
        return '/call';
      }
      if (!callActive && loc == '/call') return '/home';

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/call', builder: (context, state) => const CallPage()),
      GoRoute(
        path: '/history',
        builder: (context, state) => BlocProvider(
          create: (_) => HistoryBloc(getCallHistoryUseCase: getIt())..add(const HistoryEvent.started()),
          child: const HistoryPage(),
        ),
      ),
      GoRoute(
        path: '/contacts/requests',
        builder: (context, state) => BlocProvider(
          create: (_) => ContactRequestsBloc(
            listIncomingRequestsUseCase: getIt(),
            listOutgoingRequestsUseCase: getIt(),
            respondContactRequestUseCase: getIt(),
            removeContactUseCase: getIt(),
          )..add(const ContactRequestsEvent.started()),
          child: const ContactRequestsPage(),
        ),
      ),
      GoRoute(
        path: '/contacts/search',
        builder: (context, state) => BlocProvider(
          create: (_) => ContactSearchBloc(
            searchUserByPhoneUseCase: getIt(),
            sendContactRequestUseCase: getIt(),
          ),
          child: const ContactSearchPage(),
        ),
      ),
      GoRoute(
        path: '/message/new',
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => ContactsBloc(
                listContactsUseCase: getIt(),
                removeContactUseCase: getIt(),
              )..add(const ContactsEvent.started()),
            ),
            BlocProvider(create: (_) => NewConversationBloc(createConversationUseCase: getIt())),
          ],
          child: const NewConversationPage(),
        ),
      ),
      GoRoute(
        path: '/message/chat/:id',
        builder: (context, state) {
          final conversationId = state.pathParameters['id']!;
          final args = state.extra as ChatPageArgs?;
          final currentUserId = context.read<AuthBloc>().state.user?.id ?? '';
          return BlocProvider(
            create: (_) => ChatBloc(
              conversationId: conversationId,
              currentUserId: currentUserId,
              listMessagesUseCase: getIt(),
              repository: getIt(),
            )..add(const ChatEvent.started()),
            child: ChatPage(
              title: args?.title ?? 'Trò chuyện',
              conversationId: conversationId,
              peerId: args?.peerId,
              participantIds: args?.participantIds ?? const [],
            ),
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (context, state) => const HomePage())]),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/message',
                builder: (context, state) => BlocProvider(
                  create: (_) => ConversationsBloc(
                    listConversationsUseCase: getIt(),
                    repository: getIt(),
                  )..add(const ConversationsEvent.started()),
                  child: const MessagePage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/contacts',
                builder: (context, state) => BlocProvider(
                  create: (_) => ContactsBloc(
                    listContactsUseCase: getIt(),
                    removeContactUseCase: getIt(),
                  )..add(const ContactsEvent.started()),
                  child: const ContactsPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (context, state) => const ProfilePage())]),
        ],
      ),
    ],
  );
}
