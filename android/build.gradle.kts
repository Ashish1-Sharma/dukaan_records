// Top-level build.gradle.kts for your Flutter Android project

// ✅ Buildscript section for classpath dependencies like Gradle plugin
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.4.0")
        // Or latest version compatible with your compileSdk
    }
}

// ✅ Allprojects repositories (for resolving subproject dependencies)
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ✅ Optional: change build directory to shared path
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// ✅ Force app to evaluate first (optional and advanced)
subprojects {
    project.evaluationDependsOn(":app")
}

// ✅ Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
