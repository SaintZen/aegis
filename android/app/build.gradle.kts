import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing properties live in `android/key.properties` (gitignored).
// A template is checked in as `android/key.properties.example`. The file is
// optional at config time so debug builds and `flutter run` keep working
// before the operator generates a release keystore. The release buildType
// only switches off the debug signing config when a real key.properties
// is present.
val keystoreProperties = Properties().apply {
    val keystorePropertiesFile = rootProject.file("key.properties")
    if (keystorePropertiesFile.exists()) {
        load(FileInputStream(keystorePropertiesFile))
    }
}
val hasReleaseKeystore = keystoreProperties.isNotEmpty()

android {
    namespace = "com.zwischenzug.aegis"
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
        // Locked permanent applicationId — see operator decision log.
        // Changing this after Play Store publication requires creating a
        // brand-new app listing. Do not edit without explicit operator approval.
        applicationId = "com.zwischenzug.aegis"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = file(keystoreProperties["storeFile"] as String)
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // When `key.properties` is present (operator has generated the
            // release keystore and filled in real passwords), sign with the
            // real release key. Otherwise fall back to debug signing so
            // `flutter run --release` still works for local verification.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
