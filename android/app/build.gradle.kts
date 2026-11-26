import java.util.Properties
import java.io.FileInputStream
import org.gradle.api.GradleException
import groovy.json.JsonSlurper

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// The config file is intentionally supplied by the project owner and is not committed.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

val firebaseLocalProperties = Properties()
val firebaseLocalPropertiesFile = rootProject.file("local.properties")
if (firebaseLocalPropertiesFile.exists()) {
    firebaseLocalPropertiesFile.inputStream().use { firebaseLocalProperties.load(it) }
}
val googleServicesProjectId = file("google-services.json")
    .takeIf { it.exists() }
    ?.let { configFile ->
        val config = JsonSlurper().parse(configFile) as? Map<*, *>
        (config?.get("project_info") as? Map<*, *>)?.get("project_id") as? String
    }
val firebaseProjectId = googleServicesProjectId
    ?: firebaseLocalProperties.getProperty("firebase.projectId")
    ?: providers.gradleProperty("firebaseProjectId").orNull
    ?: System.getenv("FIREBASE_PROJECT_ID")
val firebaseAuthHost = firebaseProjectId?.let { "$it.firebaseapp.com" }
    ?: "missing-firebase-project-id.firebaseapp.com"

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (!keystorePropertiesFile.exists()) {
    throw GradleException("Missing android/key.properties. Configure Android release signing before building.")
}
keystoreProperties.load(FileInputStream(keystorePropertiesFile))

android {
    namespace = "com.abplay.app"
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
        applicationId = "com.abplay.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["firebaseAuthHost"] = firebaseAuthHost
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
