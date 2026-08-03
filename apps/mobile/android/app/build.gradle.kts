import java.util.Base64
import java.util.Properties

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

val releaseSigningPropertiesFile = rootProject.file("key.properties")
val releaseSigningProperties =
    Properties().apply {
        if (releaseSigningPropertiesFile.isFile) {
            releaseSigningPropertiesFile.inputStream().use { load(it) }
        }
    }

fun releaseSigningProperty(key: String): String? =
    releaseSigningProperties.getProperty(key)?.trim()?.takeIf { it.isNotEmpty() }

val releaseSigningConfigured =
    listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
        .all { releaseSigningProperty(it) != null }

android {
    namespace = "com.swarnalekh.app"
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
        applicationId = "com.swarnalekh.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (releaseSigningConfigured) {
                storeFile = rootProject.file(releaseSigningProperty("storeFile")!!)
                storePassword = releaseSigningProperty("storePassword")
                keyAlias = releaseSigningProperty("keyAlias")
                keyPassword = releaseSigningProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            if (releaseSigningConfigured) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

gradle.taskGraph.whenReady {
    val releaseBuildRequested =
        allTasks.any { task ->
            task.name == "assembleRelease" ||
                task.name == "bundleRelease" ||
                task.name == "packageReleaseBundle"
        }

    if (releaseBuildRequested && !releaseSigningConfigured) {
        throw GradleException(
            "Android release signing is not configured. Create apps/mobile/android/key.properties " +
                "with storeFile, storePassword, keyAlias and keyPassword before building a release.",
        )
    }
}

flutter {
    source = "../.."
}
