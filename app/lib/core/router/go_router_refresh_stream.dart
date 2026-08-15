import 'dart:async';

import 'package:flutter/foundation.dart';

/// Cầu nối Bloc.stream (Stream) -> Listenable mà GoRouter.refreshListenable
/// yêu cầu — recipe chuẩn của go_router khi kết hợp với bloc/state
/// management dạng Stream thay vì ChangeNotifier.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
