import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseSigning = keystorePropertiesFile.exists()
if (hasReleaseSigning) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.giglab.kaunti47"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications uses java.time on older Android.
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.giglab.kaunti47"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["appAuthRedirectScheme"] = "kaunti47-prod"
        // Flavors override this; dev uses Google's sample app ID.
        manifestPlaceholders["admobAppId"] = "ca-app-pub-2470974563764561~5167145236"
        resValue("string", "app_name", "Kaunti47")
    }

    flavorDimensions += "environment"

    productFlavors {
        create("dev") {
            dimension = "environment"
            manifestPlaceholders["appAuthRedirectScheme"] = "kaunti47-dev"
            manifestPlaceholders["admobAppId"] = "ca-app-pub-3940256099942544~3347511713"
            resValue("string", "app_name", "Kaunti47 Dev")
        }

        create("prod") {
            dimension = "environment"
            manifestPlaceholders["appAuthRedirectScheme"] = "kaunti47-prod"
            manifestPlaceholders["admobAppId"] = "ca-app-pub-2470974563764561~5167145236"
            resValue("string", "app_name", "Kaunti47")
        }
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
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

dependencies {
    // Required by flutter_local_notifications (see compileOptions).
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
