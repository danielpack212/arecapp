plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "ARECC1.App"
    compileSdk = flutter.targetSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "ARECC1.App"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // Add this block
    lintOptions {
        disable("Instantiatable")
    }
}

// Adding dependencies correctly in Kotlin DSL
dependencies {
    // Use Firebase BoM for dependency version management
    implementation(platform("com.google.firebase:firebase-bom:30.3.1")) // Use the latest version available for Firebase BoM
    implementation("com.google.firebase:firebase-messaging-ktx") // For Firebase Messaging
    implementation("com.google.firebase:firebase-analytics-ktx") // Optional, for Firebase Analytics
    coreLibraryDesugaring ("com.android.tools:desugar_jdk_libs:2.0.4")
}

// Flutter source mapping, it's specific to your directory structure
flutter {
    source = "../.."
}