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
        minSdk = 24
        project.ext.set("flutter.minSdkVersion", 24)
        targetSdk = 35

        // ДОБАВЛЕНО: Включаем multidex для поддержки больших приложений
        multiDexEnabled = true

        versionCode = flutter.versionCode
        versionName = flutter.versionName

        vectorDrawables.useSupportLibrary = true
    }

    buildTypes {
        release {
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
            // ИСПРАВЛЕНО: Включаем минификацию для работы ProGuard правил
            isMinifyEnabled = true
            isShrinkResources = true

            // ДОБАВЛЕНО: Подключаем ProGuard правила для Google Maps
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")

            ndk {
                debugSymbolLevel = "NONE"
            }
            packaging {
                jniLibs {
                    keepDebugSymbols += "**/*.so"
                }
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

    // ДОБАВЛЕНО: Настройки для App Bundle
    bundle {
        abi {
            enableSplit = true
        }
        density {
            enableSplit = true
        }
        language {
            enableSplit = false
        }
    }

    packaging {
        jniLibs {
            useLegacyPackaging = true
            keepDebugSymbols += "*/arm64-v8a/libc++_shared.so"
            keepDebugSymbols += "*/x86_64/libc++_shared.so"
            keepDebugSymbols += "*/x86/libc++_shared.so"
            keepDebugSymbols += "*/armeabi-v7a/libc++_shared.so"
            pickFirsts += "**/libc++_shared.so"
            pickFirsts += "**/libjsc.so"
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ДОБАВЛЕНО: Multidex для поддержки больших приложений
    implementation("androidx.multidex:multidex:2.0.1")

    // ИСПРАВЛЕНО: Проверенные версии Firebase
    implementation(platform("com.google.firebase:firebase-bom:32.2.0"))
    implementation("com.google.firebase:firebase-analytics")

    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    // ОБНОВЛЕНО: Новые версии Google Play Services
    implementation("com.google.android.gms:play-services-auth:21.0.0")
    implementation("com.google.android.gms:play-services-location:21.3.0")
    implementation("com.google.android.gms:play-services-maps:19.0.0")

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