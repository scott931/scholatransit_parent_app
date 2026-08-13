pluginManagement {
    val flutterSdkPath = run {
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
    // Bumped from 8.7.3 — several transitive androidx deps (browser 1.9.0,
    // activity 1.12.4, core 1.18.0) declare AAR metadata requiring AGP 8.9.1+.
    id("com.android.application") version "8.9.1" apply false
    // Bumped from 2.1.0 — a transitive dependency (google_maps_flutter_android,
    // pulled in via the `jni` plugin chain) ships Kotlin 2.3.10 stdlib metadata,
    // which a 2.1.0 compiler can't read ("Module was compiled with an
    // incompatible version of Kotlin"). Matched to that exact stdlib version.
    id("org.jetbrains.kotlin.android") version "2.3.10" apply false
}

include(":app")
