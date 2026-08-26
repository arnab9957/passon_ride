import java.awt.Graphics2D
import java.awt.image.BufferedImage
import javax.imageio.ImageIO
import java.io.File

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.PassionRide.app.passon_ride"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.PassionRide.app.passon_ride"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

tasks.register("generateAppIcons") {
    doLast {
        val sourceFile = File("C:/Users/SOVAN/.gemini/antigravity-ide/brain/6f302632-ec92-4f4a-b2df-a53a647b1b96/passion_ride_logo_1787726913895.jpg")
        if (!sourceFile.exists()) {
            println("Source logo file not found!")
            return@doLast
        }
        
        val sizes = mapOf(
            "mipmap-mdpi" to 48,
            "mipmap-hdpi" to 72,
            "mipmap-xhdpi" to 96,
            "mipmap-xxhdpi" to 144,
            "mipmap-xxxhdpi" to 192
        )
        
        val srcImg = ImageIO.read(sourceFile)
        sizes.forEach { (folder, size) ->
            val destDir = File(projectDir, "src/main/res/$folder")
            destDir.mkdirs()
            val destFile = File(destDir, "ic_launcher.png")
            
            val resizedImg = BufferedImage(size, size, BufferedImage.TYPE_INT_ARGB)
            val g = resizedImg.createGraphics()
            g.drawImage(srcImg, 0, 0, size, size, null)
            g.dispose()
            
            ImageIO.write(resizedImg, "png", destFile)
            println("Generated ${destFile.absolutePath} (${size}x${size})")
        }
    }
}

tasks.named("preBuild") {
    dependsOn("generateAppIcons")
}
