import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Crash reporting is opt-in at BUILD time as well as at run time. Both Google
// plugins abort the build if google-services.json is absent, so they are
// applied only when Arnar has actually dropped the Firebase Console download
// into android/app/. Without it the app still builds and runs — it just has no
// remote crash sink, and CrashReporter falls back to the local ring buffer
// alone. Adding the file is the whole switch; nothing else changes.
val googleServicesFile = file("google-services.json")
val hasFirebase = googleServicesFile.exists()
if (hasFirebase) {
    apply(plugin = "com.google.gms.google-services")
    apply(plugin = "com.google.firebase.crashlytics")
} else {
    logger.lifecycle(
        "MyReciBook: android/app/google-services.json absent — building " +
            "WITHOUT Crashlytics. Local crash log still records everything.")
}

// Upload-key signing (Play App Signing holds the app key; this one is
// rotatable via Play Console if lost). key.properties is gitignored — absent
// (CI, fresh clone) the release build falls back to debug signing so
// `flutter run --release` still works; Play uploads require the real key.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}
val hasUploadKey = keystoreProperties.isNotEmpty()

android {
    namespace = "com.merkurialstudio.myrecibook"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.merkurialstudio.myrecibook"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasUploadKey) {
            create("release") {
                // Fail with the real cause: a typo'd key would otherwise
                // surface as file(null) breaking even debug builds. Relative
                // paths resolve against android/ (key.properties' home).
                val storePath = keystoreProperties.getProperty("storeFile")
                    ?: error("key.properties exists but has no storeFile= entry")
                storeFile = rootProject.file(storePath)
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasUploadKey) {
                signingConfigs.getByName("release")
            } else {
                // Loud, not silent: a debug-signed "release" looks fine until
                // Play Console rejects it.
                logger.warn(
                    "WARNING: android/key.properties missing — release build " +
                        "will be DEBUG-signed; Play Console will reject it.")
                signingConfigs.getByName("debug")
            }
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
