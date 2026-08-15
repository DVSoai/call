import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';
import 'core/di/service_locator.dart';
import 'core/push/native_auth_bridge.dart';
import 'core/push/push_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Đọc URL backend từ .env (copy từ .env.example) — phải load trước
  // setupServiceLocator() vì DioClient/SignalingService dùng AppConstants
  // ngay lúc khởi tạo.
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Đăng ký TRƯỚC setupServiceLocator/runApp — bắt được cả message đến lúc
  // app đang khởi động, không chỉ sau khi UI đã dựng xong.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  // Mirror sang native (CallRejectNativeHandler cần base URL để gọi REST
  // reject lúc app đã kill — xem native_auth_bridge.dart).
  NativeAuthBridge.setApiBaseUrl(AppConstants.apiBaseUrl);
  await setupServiceLocator();
  runApp(const CallVideoApp());
}
