plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

// Импорты для работы с Properties
import java.util.Properties
        import java.io.FileInputStream

// Загружаем key.properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.driftnotes.app"

    compileSdk = 35
    // ИСПРАВЛЕНО: Версия NDK как требуют плагины
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    // Настройка подписи
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    defaultConfig {
        applicationId = "com.driftnotes.app"
        minSdk = 23
        targetSdk = 35

        versionCode = flutter.versionCode
        versionName = flutter.versionName

        vectorDrawables.useSupportLibrary = true
    }

    buildTypes {
        release {
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
            isMinifyEnabled = false
            isShrinkResources = false
            ndk {
                debugSymbolLevel = "NONE"
            }
        }

        debug {
            isMinifyEnabled = false
            isShrinkResources = false
            versionNameSuffix = "-debug"
        }
    }

    buildFeatures {
        buildConfig = true
    }

    lint {
        checkReleaseBuilds = true
        abortOnError = false
        warningsAsErrors = false
    }

    packagingOptions {
        jniLibs {
            useLegacyPackaging = true
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ИСПРАВЛЕНО: Проверенные версии Firebase
    implementation(platform("com.google.firebase:firebase-bom:32.2.0"))
    implementation("com.google.firebase:firebase-analytics")

    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    // ИСПРАВЛЕНО: Реальные существующие версии
    implementation("com.google.android.gms:play-services-auth:20.7.0")
    implementation("com.google.android.gms:play-services-location:21.3.0")
    implementation("com.google.android.gms:play-services-maps:18.2.0")

    // ИСПРАВЛЕНО: Реальные версии Billing
    implementation("com.android.billingclient:billing:6.0.1")
    implementation("com.android.billingclient:billing-ktx:6.0.1")

    // ИСПРАВЛЕНО: Реальные версии Camera
    implementation("androidx.camera:camera-core:1.3.4")
    implementation("androidx.camera:camera-camera2:1.3.4")
    implementation("androidx.camera:camera-lifecycle:1.3.4")
    implementation("androidx.camera:camera-view:1.3.4")

    // ИСПРАВЛЕНО: Реальные версии AndroidX
    implementation("androidx.activity:activity-compose:1.9.1")
    implementation("androidx.core:core-ktx:1.13.1")
}