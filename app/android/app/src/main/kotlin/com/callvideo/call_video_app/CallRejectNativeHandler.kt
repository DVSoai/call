package com.callvideo.call_video_app

import android.content.Context
import android.os.Bundle
import android.util.Log
import com.hiennv.flutter_callkit_incoming.CallkitEventCallback
import com.hiennv.flutter_callkit_incoming.Data
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors

/**
 * Xử lý Decline NGAY Ở TẦNG NATIVE, không chờ Flutter engine — khi app bị
 * kill hẳn, plugin flutter_callkit_incoming xử lý nút Decline hoàn toàn
 * bằng native code (đóng notification, không mở lại app), nên nếu chỉ dựa
 * vào Dart (PushService.rejectIfMatching) thì caller sẽ không bao giờ được
 * báo — cứ đứng đợi tới khi room RINGING tự hết hạn TTL (xem
 * docs/CALL_SYSTEM.md §5.2, backend Hub.RejectCall).
 *
 * Đăng ký ở [CallVideoApplication.onCreate] — bắt buộc đăng ký ở đó (không
 * phải MainActivity) vì Application.onCreate() vẫn chạy dù OS chỉ đánh
 * thức process để giao broadcast, không hề mở Activity/Flutter engine nào.
 */
class CallRejectNativeHandler(private val appContext: Context) : CallkitEventCallback {

    private val executor = Executors.newSingleThreadExecutor()

    override fun onCallEvent(event: CallkitEventCallback.CallEvent, callData: Bundle) {
        if (event != CallkitEventCallback.CallEvent.DECLINE) return

        val parsed = try {
            Data.fromBundle(callData)
        } catch (e: Exception) {
            Log.w(TAG, "parse callData lỗi", e)
            return
        }
        val roomId = parsed.extra["roomId"] as? String
        if (roomId.isNullOrEmpty()) {
            Log.w(TAG, "decline nhưng thiếu roomId trong extra — bỏ qua")
            return
        }

        executor.execute { sendRejectRequest(roomId) }
    }

    private fun sendRejectRequest(roomId: String) {
        val token = NativeAuthBridge.getToken(appContext)
        val baseUrl = NativeAuthBridge.getApiBaseUrl(appContext)
        if (token.isNullOrEmpty() || baseUrl.isNullOrEmpty()) {
            Log.w(TAG, "thiếu token/apiBaseUrl — không gửi reject được (chưa từng login?)")
            return
        }

        var connection: HttpURLConnection? = null
        try {
            val url = URL("$baseUrl/calls/$roomId/reject")
            connection = (url.openConnection() as HttpURLConnection).apply {
                requestMethod = "POST"
                setRequestProperty("Authorization", "Bearer $token")
                setRequestProperty("Content-Type", "application/json")
                connectTimeout = 8000
                readTimeout = 8000
                doOutput = true
            }
            OutputStreamWriter(connection.outputStream).use { it.write("") }
            val code = connection.responseCode
            Log.i(TAG, "reject roomId=$roomId -> HTTP $code")
        } catch (e: Exception) {
            Log.w(TAG, "gửi reject lỗi cho roomId=$roomId", e)
        } finally {
            connection?.disconnect()
        }
    }

    companion object {
        private const val TAG = "CallRejectNativeHandler"
    }
}
