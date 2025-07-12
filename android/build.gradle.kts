buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // ОБНОВЛЕННЫЕ версии для совместимости с Gradle 8.10.2
        classpath("com.android.tools.build:gradle:8.3.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.10")
        classpath("com.google.gms:google-services:4.4.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // Принудительно используем Java 17
    tasks.withType<JavaCompile>().configureEach {
        options.compilerArgs.addAll(listOf(
            "-Xlint:-options",
            "-Xlint:-deprecation"
        ))
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}