package com.callvideo.call_video_app

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey

/**
 * Bản sao JWT token + apiBaseUrl riêng cho code native — KHÔNG đọc trực
 * tiếp định dạng nội bộ của flutter_secure_storage (dễ vỡ khi plugin đó
 * đổi cách lưu). Dart chủ động ghi qua MethodChannel mỗi khi
 * login/logout/refresh token (xem MainActivity.kt + native_auth_bridge.dart).
 *
 * Dùng cho [CallRejectNativeHandler] — chạy được kể cả khi Flutter engine
 * chưa khởi động (app bị kill, user bấm Decline trên CallKit UI), nên
 * không thể gọi lại Dart để lấy token lúc đó.
 */
object NativeAuthBridge {
    private const val PREFS_NAME = "native_auth_bridge"
    private const val KEY_TOKEN = "token"
    private const val KEY_API_BASE_URL = "api_base_url"

    private fun prefs(context: Context): SharedPreferences {
        val masterKey = MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()
        return EncryptedSharedPreferences.create(
            context,
            PREFS_NAME,
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
        )
    }

    fun saveToken(context: Context, token: String) {
        prefs(context).edit().putString(KEY_TOKEN, token).apply()
    }

    fun getToken(context: Context): String? = prefs(context).getString(KEY_TOKEN, null)

    fun clearToken(context: Context) {
        prefs(context).edit().remove(KEY_TOKEN).apply()
    }

    fun saveApiBaseUrl(context: Context, url: String) {
        prefs(context).edit().putString(KEY_API_BASE_URL, url).apply()
    }

    fun getApiBaseUrl(context: Context): String? = prefs(context).getString(KEY_API_BASE_URL, null)
}
