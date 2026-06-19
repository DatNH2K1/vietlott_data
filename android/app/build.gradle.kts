import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.datnh.vietlott_data.vietlott_data"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.datnh.vietlott_data.vietlott_data"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Load from .env file if it exists
            val envFile = rootProject.file("../.env")
            val envProps = Properties()
            if (envFile.exists()) {
                envFile.inputStream().use { envProps.load(it) }
                println("BMAD: Loaded signing config from ${envFile.absolutePath}")
            } else {
                println("BMAD: .env file not found at ${envFile.absolutePath}")
            }

            val keystoreFileName: String? = System.getenv("ANDROID_KEYSTORE_FILE") ?: envProps.getProperty("ANDROID_KEYSTORE_FILE")
            if (!keystoreFileName.isNullOrEmpty()) {
                storeFile = file(keystoreFileName)
                storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD") ?: envProps.getProperty("ANDROID_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("ANDROID_KEY_ALIAS") ?: envProps.getProperty("ANDROID_KEY_ALIAS")
                keyPassword = System.getenv("ANDROID_KEY_PASSWORD") ?: envProps.getProperty("ANDROID_KEY_PASSWORD")
            } else {
                // Fallback to debug for local builds if no env vars or .env file
                val debugKeystore = signingConfigs.getByName("debug")
                storeFile = debugKeystore.storeFile
                storePassword = debugKeystore.storePassword
                keyAlias = debugKeystore.keyAlias
                keyPassword = debugKeystore.keyPassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

