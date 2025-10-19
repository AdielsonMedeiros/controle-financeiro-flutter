pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        val localPropertiesFile = file("local.properties")
        
        if (!localPropertiesFile.exists()) {
            throw GradleException("local.properties file not found. Please create it with flutter.sdk property.")
        }
        
        try {
            localPropertiesFile.inputStream().use { properties.load(it) }
        } catch (e: Exception) {
            throw GradleException("Failed to load local.properties: ${e.message}")
        }
        
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        if (flutterSdkPath.isNullOrBlank()) {
            throw GradleException("flutter.sdk property not set in local.properties")
        }
        
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
    id("com.android.application") version "8.9.1" apply false
    // START: FlutterFire Configuration
    id("com.google.gms.google-services") version("4.3.15") apply false
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")
