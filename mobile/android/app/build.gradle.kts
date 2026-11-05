plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// The demo app (lib/demo/demo_main.dart) installs beside the real one:
//   flutter build apk --release -t lib/demo/demo_main.dart -P sfmDemo=true
// Its own package and name, so it never shares data with the study app.
val sfmDemo = (project.findProperty("sfmDemo") as String?) == "true"

android {
    namespace = "zm.ac.zcas.sfm_lcp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = if (sfmDemo) "zm.ac.zcas.sfm_lcp.demo" else "zm.ac.zcas.sfm_lcp"
        resValue("string", "app_name", if (sfmDemo) "SFM-LCP Demo" else "SFM-LCP")
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
}

flutter {
    source = "../.."
}
