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
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
