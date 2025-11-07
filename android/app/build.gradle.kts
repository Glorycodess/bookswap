// android/app/build.gradle.kts

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")  // ADD THIS LINE
    // Flutter Gradle Plugin must be applied last
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.bookswap_app"
    compileSdk = 36
    ndkVersion = "27.0.12077973"  // CHANGED FROM 25.1.8937393

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.bookswap_app"
        minSdk = flutter.minSdkVersion  // CHANGED - Firebase needs at least 23
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    buildFeatures {
        viewBinding = true
    }
}

flutter {
    source = "../.."
}

// Firebase dependencies
dependencies {
    // Import Firebase BOM to manage versions consistently
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))  // UPDATED VERSION
    implementation("com.google.firebase:firebase-auth")  // REMOVED -ktx
    implementation("com.google.firebase:firebase-firestore")  // REMOVED -ktx
    implementation("com.google.firebase:firebase-storage")  // REMOVED -ktx
}
