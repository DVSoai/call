package com.callvideo.call_video_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** Chỉ wiring — logic từng tính năng native nằm ở class riêng (NativeAuthFeature...). */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NativeAuthFeature.CHANNEL)
            .setMethodCallHandler(NativeAuthFeature(applicationContext))
    }
}
