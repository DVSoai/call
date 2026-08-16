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

    // sherpa_onnx (ghim 1.12.39, xem pubspec.yaml) và flutter_onnxruntime
    // đều tự đóng gói libonnxruntime.so — giờ CÙNG bundle bản 1.24.3 nên
    // nội dung file gần như giống nhau, pickFirst chỉ để Gradle hết báo lỗi
    // trùng file lúc merge, không còn phải lo chọn nhầm bản (trước đây 2
    // bên bundle 2 bản KHÁC NHAU — 1.27.1 vs 1.23.0 — pickFirst khi đó chỉ
    // che được lỗi build, không giải quyết được lỗi runtime "cannot locate
    // symbol OrtGetApiBase").
    packaging {
        jniLibs {
            pickFirsts += "**/libonnxruntime.so"
        }
    }
}

configurations.all {
    resolutionStrategy {
        // flutter_onnxruntime hardcode "com.microsoft.onnxruntime:onnxruntime-android:1.23.0"
        // trong chính android/build.gradle của nó — ép về đúng bản
        // sherpa_onnx 1.12.39 đang bundle (1.24.3) để symbol version khớp
        // nhau, xem giải thích đầy đủ ở pubspec.yaml.
        force("com.microsoft.onnxruntime:onnxruntime-android:1.24.3")
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
