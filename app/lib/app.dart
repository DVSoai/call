import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/di/service_locator.dart';
import 'core/push/push_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/call/presentation/bloc/call_bloc.dart';

class CallVideoApp extends StatefulWidget {
  const CallVideoApp({super.key});

  @override
  State<CallVideoApp> createState() => _CallVideoAppState();
}

class _CallVideoAppState extends State<CallVideoApp> {
  late final AuthBloc _authBloc;
  late final CallBloc _callBloc;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // AuthBloc/CallBloc là lazySingleton (sống suốt phiên đăng nhập) —
    // lấy từ get_it thay vì tạo mới, xem service_locator.dart.
    _authBloc = getIt<AuthBloc>()..add(const AuthEvent.sessionCheckRequested());
    _callBloc = getIt<CallBloc>();
    _router = buildAppRouter(authBloc: _authBloc, callBloc: _callBloc);
    // Gắn NGAY lúc khởi động (không chờ authenticated) — app có thể cold-start
    // chính vì user vừa bấm Accept trên CallKit UI, cần bắt được sự kiện đó
    // (hoặc activeCalls() còn sót lại) sớm nhất có thể.
    getIt<PushService>().wireCallBloc(_callBloc);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<CallBloc>.value(value: _callBloc),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        // Chỉ mở WebSocket signaling đúng 1 lần ngay khi vừa xác thực xong
        // (không mở lại mỗi lần AuthState rebuild vì lý do khác).
        listenWhen: (previous, current) =>
            previous.status != AuthStatus.authenticated && current.status == AuthStatus.authenticated,
        listener: (context, state) {
          _callBloc.add(const CallEvent.signalingStarted());
          // Không await — đăng ký token là fire-and-forget, không được chặn
          // luồng mở WebSocket signaling phía trên.
          getIt<PushService>().registerToken();
        },
        child: MaterialApp.router(
          title: 'call_video',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          routerConfig: _router,
        ),
      ),
    );
  }
}
