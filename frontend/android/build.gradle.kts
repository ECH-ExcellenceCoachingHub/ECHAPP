allprojects {
    repositories {
        google()
        mavenCentral()
        // ECH Labs (Unity): local .aar files such as the OpenXR loader.
        flatDir { dirs(rootProject.file("unityLibrary/libs")) }
    }

    configurations.all {
        resolutionStrategy {
            force(
                "androidx.media3:media3-common:1.5.0",
                "androidx.media3:media3-container:1.5.0",
                "androidx.media3:media3-database:1.5.0",
                "androidx.media3:media3-datasource:1.5.0",
                "androidx.media3:media3-decoder:1.5.0",
                "androidx.media3:media3-exoplayer:1.5.0",
                "androidx.media3:media3-exoplayer-dash:1.5.0",
                "androidx.media3:media3-exoplayer-hls:1.5.0",
                "androidx.media3:media3-exoplayer-rtsp:1.5.0",
                "androidx.media3:media3-exoplayer-smoothstreaming:1.5.0",
                "androidx.media3:media3-extractor:1.5.0",
                "androidx.media3:media3-session:1.5.0",
                "androidx.media3:media3-ui:1.5.0"
            )
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
// Native plugin libraries (e.g. jni, used by sentry_flutter) that do not pin an
// NDK would otherwise make the Android Gradle Plugin download its default NDK.
// Use the one the app and unityLibrary already use.
subprojects {
    plugins.withId("com.android.library") {
        val android = extensions.getByName("android")
        android.javaClass.getMethod("setNdkVersion", String::class.java).invoke(android, "27.2.12479018")
    }
}
// sentry_flutter 9 compiles its Android code with Kotlin languageVersion 1.6,
// which Kotlin 2.2 rejects ("Language version 1.6 is no longer supported").
// sentry_flutter 10 fixes it but needs a newer Dart SDK, so raise it here.
subprojects {
    if (name == "sentry_flutter") {
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                languageVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_1_8)
                apiVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_1_8)
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
