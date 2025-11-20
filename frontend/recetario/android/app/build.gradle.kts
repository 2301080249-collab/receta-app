plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.cenfotec.recetario"
    compileSdk = 36  // Actualizado a SDK 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true  // 🆕 AGREGAR ESTA LÍNEA
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.cenfotec.recetario"
        minSdk = flutter.minSdkVersion  // Mínimo para desugaring
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // 🆕 AGREGAR ESTA LÍNEA
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
