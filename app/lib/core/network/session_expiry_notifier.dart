import 'dart:async';

/// Cầu nối giữa network layer (không biết gì về AuthBloc) và presentation
/// layer — khi Dio nhận 401 (JWT hết hạn/không hợp lệ), ForceLogoutInterceptor
/// gọi [notify], AuthBloc subscribe [onSessionExpired] để tự động logout +
/// điều hướng về LoginPage, thay vì để mỗi màn hình tự hiện lỗi 401 rời rạc.
class SessionExpiryNotifier {
  final _controller = StreamController<void>.broadcast();

  Stream<void> get onSessionExpired => _controller.stream;

  Timer? _debounce;

  /// Debounce 2s — nhiều request đồng thời cùng nhận 401 (vd. gọi song
  /// song REST + mở /ws) chỉ nên trigger force-logout đúng 1 lần.
  void notify() {
    if (_debounce != null) return;
    _controller.add(null);
    _debounce = Timer(const Duration(seconds: 2), () => _debounce = null);
  }

  void dispose() {
    _debounce?.cancel();
    _controller.close();
  }
}
