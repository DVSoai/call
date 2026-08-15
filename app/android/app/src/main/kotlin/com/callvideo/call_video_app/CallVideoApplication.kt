package com.callvideo.call_video_app

import android.app.Application
import com.hiennv.flutter_callkit_incoming.FlutterCallkitIncomingPlugin

/**
 * Application.onCreate() chạy TRƯỚC MỌI THỨ, kể cả khi OS chỉ đánh thức
 * process để giao 1 broadcast (không mở Activity/Flutter engine nào) —
 * đây là lý do đăng ký [CallRejectNativeHandler] ở đây thay vì
 * MainActivity, để nó sống sẵn sàng nhận sự kiện Decline dù app đã bị kill
 * hẳn trước đó. Xem docs/CALL_SYSTEM.md §5.2.
 */
class CallVideoApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        FlutterCallkitIncomingPlugin.registerEventCallback(CallRejectNativeHandler(applicationContext))
    }
}
