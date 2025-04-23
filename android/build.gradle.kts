// Root build.gradle file

allprojects {
    repositories {
        google()  // Ensure this is included
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Add this section for Firebase plugin
buildscript {
    repositories {
        google()  // Ensure this is included
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:7.0.4'  // or your current version
        classpath 'com.google.gms:google-services:4.3.10'  // Add this line for Google services
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
