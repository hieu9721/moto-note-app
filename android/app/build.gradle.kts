import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing (REL-03, 06-08): loaded from android/key.properties,
// which .gitignore already excludes. android/key.properties.example is the
// committed template with placeholder values — copy it and fill in real
// keystore credentials. Never falls back to the debug key: see the
// missing-file guard at the bottom of this file.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasKeystoreProperties = keystorePropertiesFile.exists()
if (hasKeystoreProperties) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "io.github.hieu9721.motonote"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications even before its API is called
        // (01-RESEARCH.md Pitfall 5a) — Gradle enforces this at AAR-metadata check time.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "io.github.hieu9721.motonote"
        // P1-D-02: pinned explicitly rather than inherited from Flutter's default (24).
        // Notification channels are an API 26+ concept — this removes the entire
        // pre-channel legacy branch from Phase 4.
        // REL-03 closing evidence (06-RESEARCH.md Pitfall 1): this project's minSdk
        // (26) is already above flutter_local_notifications 22.3.0's own floor (24) —
        // no change needed here for that clause.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasKeystoreProperties) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")

            // R8 minification and resource shrinking (REL-03).
            isMinifyEnabled = true
            isShrinkResources = true

            // No custom ProGuard keep-rule file is added, deliberately
            // (06-RESEARCH.md Pitfall 2): flutter_local_notifications 22.3.0's own
            // README states GSON's rules are auto-provided from v19+; freezed and
            // json_serializable generate plain Dart that R8 never touches; whether
            // google_sign_in_android's transitive AARs need anything is an empirical
            // question answered on-device in 06-10, not guessed at here. A
            // speculative rule block copied from a generic tutorial would suppress
            // the very signal that check is looking for.

            // No ABI-split Gradle configuration block is added, deliberately
            // (06-RESEARCH.md Pitfall 3): that DSL configures split APKs built
            // directly by Gradle. This project builds an App Bundle
            // (`flutter build appbundle`), which Google Play's own serving layer
            // already splits per ABI at install time — REL-03's ABI-split clause is
            // satisfied by the AAB format itself, no extra Gradle config needed.
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // Required by flutter_local_notifications (01-RESEARCH.md Pitfall 5a).
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}

// Fail loudly, not silently, when android/key.properties is missing and a
// release-variant task is invoked — a silent fallback to the debug key is
// exactly how a debug-signed artifact reaches Play Console and is rejected
// after the upload (T-06-08-03; 06-RESEARCH.md Pitfall 4; §15 R6). Debug
// builds are entirely unaffected: this only matches task names containing
// "Release".
if (!hasKeystoreProperties) {
    tasks.matching { it.name.contains("Release") }.configureEach {
        doFirst {
            throw GradleException(
                "android/key.properties is missing. Copy " +
                    "android/key.properties.example to android/key.properties and " +
                    "fill in your real release keystore credentials before building " +
                    "a release variant — see the 06-08 plan's checkpoint " +
                    "instructions for how to generate the keystore."
            )
        }
    }
}
