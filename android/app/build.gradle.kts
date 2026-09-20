import java.util.Properties

/** Yayın imzası; dosya yoksa null (bkz. buildTypes.release). */
val keystoreProperties: Properties? =
    rootProject.file("key.properties").takeIf { it.exists() }?.let { file ->
        Properties().apply { file.inputStream().use { load(it) } }
    }

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.iylabs.emojipuzzle"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Mağazada bu kimlikle yayımlanır ve yayımlandıktan sonra bir daha
        // değiştirilemez (20 Eylül, kullanıcı seçti).
        applicationId = "com.iylabs.emojipuzzle"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // §0 — Min Android API 24.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Yayın imzası `android/key.properties` dosyasından okunur. Dosya
    // depoya girmez (bkz. android/.gitignore) ve bu makinede yoksa yayın
    // derlemesi debug anahtarıyla imzalanır — `flutter run --release`
    // çalışmaya devam etsin diye. Mağazaya yüklenecek paket **mutlaka**
    // gerçek anahtarla imzalanmış olmalıdır.
    signingConfigs {
        create("release") {
            if (keystoreProperties != null) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = keystoreProperties.getProperty("storeFile")
                    ?.let { rootProject.file(it) }
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystoreProperties != null) {
                signingConfigs.getByName("release")
            } else {
                logger.warn(
                    "android/key.properties yok: yayın derlemesi DEBUG " +
                        "anahtarıyla imzalanıyor. Play bu paketi kabul etmez."
                )
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
