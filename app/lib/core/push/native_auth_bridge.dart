import 'package:flutter/services.dart';

/// Cầu nối MethodChannel sang native (Android MainActivity.kt) — ghi lại
/// JWT token + apiBaseUrl vào 1 bản sao riêng native đọc được
/// (EncryptedSharedPreferences, xem NativeAuthBridge.kt), KHÔNG phải bản
/// chính flutter_secure_storage đang dùng.
///
/// Lý do cần bản sao riêng: [CallRejectNativeHandler] (native) phải gửi
/// được HTTP reject khi user bấm Decline trên CallKit UI lúc app đã bị
/// kill hẳn — lúc đó không còn Dart nào chạy để hỏi token qua
/// flutter_secure_storage (dù có, đọc định dạng nội bộ của plugin đó từ
/// Kotlin cũng dễ vỡ khi plugin đổi implementation).
class NativeAuthBridge {
  static const _channel = MethodChannel('com.callvideo.call_video_app/native_auth');

  // Chỉ hỗ trợ Android hiện tại (iOS chưa có CallRejectNativeHandler
  // tương ứng) — nuốt lỗi PlatformException/MissingPluginException thay vì
  // throw, vì đây chỉ là bản sao phụ trợ cho native, không phải nguồn sự
  // thật (flutter_secure_storage vẫn là nơi lưu token chính).
  static Future<void> saveToken(String token) async {
    try {
      await _channel.invokeMethod<void>('saveToken', {'token': token});
    } catch (_) {}
  }

  static Future<void> clearToken() async {
    try {
      await _channel.invokeMethod<void>('clearToken');
    } catch (_) {}
  }

  static Future<void> setApiBaseUrl(String url) async {
    try {
      await _channel.invokeMethod<void>('setApiBaseUrl', {'url': url});
    } catch (_) {}
  }
}
