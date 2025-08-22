plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties


val keystorePropertiesFile = rootProject.file("key.properties")
println("key.properties exists: ${keystorePropertiesFile.exists()}")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
    println("keyAlias: ${keystoreProperties.getProperty("keyAlias")}")
    println("keyPassword: ${keystoreProperties.getProperty("keyPassword")}")
    println("storePassword: ${keystoreProperties.getProperty("storePassword")}")
    println("storeFile: ${keystoreProperties.getProperty("storeFile")}")
} else {
    println("key.properties 파일을 찾을 수 없습니다!")
}


android {
    namespace = "com.tori.voice"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.tori.voice"  // 릴리즈 패키지 이름
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // 앱 이름
        resValue("string", "app_name", "TORI - 새로운 인연과의 만남")
    }

    val keyAlias = keystoreProperties.getProperty("keyAlias")
    val keyPassword = keystoreProperties.getProperty("keyPassword")
    val storePassword = keystoreProperties.getProperty("storePassword")
    val storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }

    signingConfigs {
        create("release") {
            if (keyAlias != null && keyPassword != null && storePassword != null && storeFile != null) {
                this.keyAlias = keyAlias
                this.keyPassword = keyPassword
                this.storePassword = storePassword
                this.storeFile = storeFile
            } else {
                throw GradleException("key.properties 내용 확인 필요!")
            }
        }
    }

    buildTypes {
        debug {
//            applicationIdSuffix = ".debug"  // com.tori.voice.debug
            signingConfig = signingConfigs.getByName("debug")
        }
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.1.0"))
    implementation("com.google.firebase:firebase-analytics")
}

flutter {
    source = "../.."
}
