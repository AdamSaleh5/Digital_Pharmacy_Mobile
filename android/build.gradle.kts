allprojects {
    repositories {
        google()
        mavenCentral()
    }
    configurations.all {
        resolutionStrategy.eachDependency {
            when {
                requested.group == "androidx.core" && requested.name == "core-ktx" -> {
                    useVersion("1.13.1")
                    because("Avoid newer versions requiring AGP 8.9.1")
                }
                requested.group == "androidx.core" && requested.name == "core" -> {
                    useVersion("1.13.1")
                    because("Avoid newer versions requiring AGP 8.9.1")
                }
                requested.group == "androidx.browser" && requested.name == "browser" -> {
                    useVersion("1.6.0")
                    because("Avoid newer versions requiring AGP 8.9.1")
                }
            }
        }
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
