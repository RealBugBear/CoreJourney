plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.alexandermessinger.corejourney"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        // Default will be overridden by flavors
        applicationId = "com.alexandermessinger.corejourney"
        minSdk = flutter.minSdkVersion // Android 5.0 minimum
        targetSdk = flutter.targetSdkVersion
        versionCode = 1
        versionName = "1.0.0"
        
        // Multiplatform support
        multiDexEnabled = true
    }

    // Product Flavors for dev/staging/prod
    flavorDimensions += "environment"
    productFlavors {
        create("development") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "CoreJourney DEV")
        }
        
        create("staging") {
            dimension = "environment"
            applicationIdSuffix = ".staging"
            versionNameSuffix = "-staging"
            resValue("string", "app_name", "CoreJourney STAGING")
        }
        
        create("production") {
            dimension = "environment"
            resValue("string", "app_name", "CoreJourney")
        }
    }

    buildTypes {
        release {
            // For release builds, you'll need to configure signing
            // See android/SIGNING_SETUP.md for instructions
            signingConfig = signingConfigs.getByName("debug")
            
            // Enable ProGuard/R8 for code shrinking
            isMinifyEnabled = true
            isShrinkResources = true
            
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        
        debug {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
        }
    }
}

flutter {
    source = "../.."
}
