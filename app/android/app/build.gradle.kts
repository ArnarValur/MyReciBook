import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
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
