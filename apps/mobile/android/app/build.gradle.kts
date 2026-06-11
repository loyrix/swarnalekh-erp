import java.util.Base64

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val mobileEnvFile = rootProject.projectDir.parentFile.resolve(".env")
if (!project.hasProperty("dart-defines") && mobileEnvFile.isFile) {
    val allowedKeys = setOf("SUPABASE_URL", "SUPABASE_ANON_KEY", "API_BASE_URL")
    val envDefines =
        mobileEnvFile
            .readLines()
            .map { it.trim() }
            .filter { it.isNotEmpty() && !it.startsWith("#") && it.contains("=") }
            .mapNotNull { line ->
                val key = line.substringBefore("=").trim()
                val value = line.substringAfter("=").trim().trim('"', '\'')
                if (key in allowedKeys) "$key=$value" else null
            }

    if (envDefines.isNotEmpty()) {
        extensions.extraProperties["dart-defines"] =
            envDefines.joinToString(",") {
                Base64.getEncoder().encodeToString(it.toByteArray(Charsets.UTF_8))
            }
    }
}

android {
    namespace = "com.swarnbook.swarnbook"
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
        applicationId = "com.swarnbook.swarnbook"
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
