plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.callvideo.call_video_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.callvideo.call_video_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // sherpa_onnx và flutter_onnxruntime đều tự đóng gói cùng 1 thư viện
    // native libonnxruntime.so (cả 2 wrap onnxruntime, mỗi bên phân phối
    // riêng) — Gradle không tự chọn được nên báo lỗi trùng file lúc merge.
    // pickFirst lấy đại 1 bản, đủ dùng vì cả 2 cùng gọi chung 1 bộ C API
    // onnxruntime chuẩn (không phải fork riêng khác API).
    packaging {
        jniLibs {
            pickFirsts += "**/libonnxruntime.so"
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Đọc/ghi JWT token từ code native (CallRejectNativeHandler) — cùng cơ
    // chế mã hoá Android Keystore mà flutter_secure_storage dùng, nhưng
    // dùng file riêng do chính app quản lý (xem NativeAuthBridge.kt) thay
    // vì đọc trực tiếp định dạng nội bộ của flutter_secure_storage (dễ vỡ
    // khi plugin đó đổi implementation).
    implementation("androidx.security:security-crypto:1.1.0")
}
