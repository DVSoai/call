import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../push/native_auth_bridge.dart';

/// Lưu JWT + thông tin user cơ bản vào secure storage (Keychain/Keystore)
/// — không bao giờ lưu token dạng plaintext (SharedPreferences).
///
/// Lưu kèm phone/displayName/preferredLanguage (không chỉ token) vì backend
/// chưa có endpoint "GET /me" — nếu chỉ lưu token, sau khi restart app
/// (session được khôi phục từ token đã lưu) sẽ không biết user là ai để
/// hiển thị ở ProfilePage cho tới lần gọi API tiếp theo.
class TokenStorage {
  TokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'auth_user_id';
  static const _phoneKey = 'auth_phone';
  static const _displayNameKey = 'auth_display_name';
  static const _preferredLanguageKey = 'auth_preferred_language';

  Future<void> saveSession({
    required String token,
    required String userId,
    required String phone,
    required String displayName,
    required String preferredLanguage,
  }) async {
    await Future.wait([
      _storage.write(key: _tokenKey, value: token),
      _storage.write(key: _userIdKey, value: userId),
      _storage.write(key: _phoneKey, value: phone),
      _storage.write(key: _displayNameKey, value: displayName),
      _storage.write(key: _preferredLanguageKey, value: preferredLanguage),
    ]);
    // Bản sao riêng cho native (CallRejectNativeHandler) — xem
    // native_auth_bridge.dart. Không await/không chặn — fire-and-forget,
    // không phải nguồn sự thật.
    NativeAuthBridge.saveToken(token);
  }

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  /// Cập nhật riêng ngôn ngữ nghe (ProfilePage) — không đụng các field khác,
  /// khác saveSession() (ghi lại toàn bộ session lúc login).
  Future<void> writePreferredLanguage(String language) => _storage.write(key: _preferredLanguageKey, value: language);

  Future<String?> readUserId() => _storage.read(key: _userIdKey);

  /// Trả về map thông tin user đã lưu, hoặc null nếu chưa từng login
  /// (phone là field bắt buộc — coi như chưa có session nếu thiếu).
  Future<Map<String, String>?> readUserProfile() async {
    final phone = await _storage.read(key: _phoneKey);
    if (phone == null) return null;
    return {
      'id': await _storage.read(key: _userIdKey) ?? '',
      'phone': phone,
      'displayName': await _storage.read(key: _displayNameKey) ?? '',
      'preferredLanguage': await _storage.read(key: _preferredLanguageKey) ?? 'vi',
    };
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _userIdKey),
      _storage.delete(key: _phoneKey),
      _storage.delete(key: _displayNameKey),
      _storage.delete(key: _preferredLanguageKey),
    ]);
    NativeAuthBridge.clearToken();
  }
}
