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
        jvmTarget = "17"
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
}

// Adding dependencies correctly in Kotlin DSL
dependencies {
    // Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:30.3.1")) // Use the Firebase Bill of Materials for version management
    implementation("com.google.firebase:firebase-messaging-ktx") // Firebase Messaging
    implementation("com.google.firebase:firebase-analytics-ktx") // Firebase Analytics, if needed
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4") // Required for certain compatibility features
    implementation("androidx.appcompat:appcompat:1.6.1") // Ensure this is updated
    implementation("androidx.core:core-ktx:1.10.1") // Ensure this is updated
}

// Flutter source mapping, it's specific to your directory structure
flutter {
    source = "../.."
}