plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.petitworksapps.shougakukore.programming"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.petitworksapps.shougakukore.programming"
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
            // NOTE: R8によるコード圧縮・難読化(minify)は、GitHub Actionsの
            // 標準ランナー(16GB RAM)上で org.gradle.jvmargs のヒープを
            // 2048m→3072m→4608m→7168mと段階的に増やしても
            // "OutOfMemoryError: Java heap space" が解消しなかったため、
            // 暫定的に無効化している。APKサイズは大きくなり、難読化されない。
            // 将来的に対応する場合の選択肢:
            //   - self-hosted runner等、より大きなメモリのビルド環境を使う
            //   - R8Task が実際に使用しているワーカーのメモリ制御方法を
            //     Android Gradle Plugin側で個別に調査・設定する
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
