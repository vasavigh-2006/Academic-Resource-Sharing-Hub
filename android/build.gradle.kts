
// Project-level build file


// Flutter's custom build directory setup
val newBuildDir: Directory = rootProject.layout.buildDirectory
    .dir("../../build")
    .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}


subprojects {
    // Crucial for Flutter projects to link the app module correctly
    project.evaluationDependsOn(":app")
}





tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
