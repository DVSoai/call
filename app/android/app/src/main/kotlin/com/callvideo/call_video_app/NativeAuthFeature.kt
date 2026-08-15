package com.callvideo.call_video_app

import android.content.Context
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * MethodChannel "com.callvideo.call_video_app/native_auth" — Dart gọi mỗi
 * khi login/logout để ghi lại JWT token/apiBaseUrl vào NativeAuthBridge
 * (bản sao riêng cho native đọc, xem NativeAuthBridge.kt). Dùng bởi
 * [CallRejectNativeHandler] lúc app đã bị kill, không còn Dart để hỏi
 * token — xem app/lib/core/push/native_auth_bridge.dart.
 */
class NativeAuthFeature(private val appContext: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "com.callvideo.call_video_app/native_auth"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "saveToken" -> {
                val token = call.argument<String>("token")
                if (token != null) NativeAuthBridge.saveToken(appContext, token)
                result.success(null)
            }
            "clearToken" -> {
                NativeAuthBridge.clearToken(appContext)
                result.success(null)
            }
            "setApiBaseUrl" -> {
                val url = call.argument<String>("url")
                if (url != null) NativeAuthBridge.saveApiBaseUrl(appContext, url)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }
}
