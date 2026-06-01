import java.util.Properties
import java.io.FileInputStream

val localProperties = Properties().apply {
    val file = rootDir.resolve("local.properties")
    if (file.exists()) {
        FileInputStream(file).use { load(it) }
    }
}
var mapboxToken = localProperties.getProperty("MAPBOX_DOWNLOADS_TOKEN")

pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    // START: FlutterFire Configuration
    id("com.google.gms.google-services") version "4.3.15" apply false
    id("com.google.firebase.crashlytics") version "2.8.1" apply false
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

// ── Dependency resolution — includes Mapbox Maven repository ──────────────────
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()

        // Flutter engine artifacts (arm64_v8a_debug, flutter_embedding_debug, etc.)
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }

        // JitPack — needed by flutter_webrtc (audioswitch)
        maven { url = uri("https://jitpack.io") }

        // Mapbox Navigation SDK — authenticated Maven repository.
        // Credentials come from local.properties (MAPBOX_DOWNLOADS_TOKEN).
        maven {
            url = uri("https://api.mapbox.com/downloads/v2/releases/maven")
            authentication {
                create<BasicAuthentication>("basic")
            }
            credentials {
                username = "mapbox"
                password = mapboxToken
            }
        }
    }
}

include(":app")
