allprojects {
    repositories {
        google()
        mavenCentral()
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

    // 일부 플러그인(file_picker 등)이 compileSdk 34 로 고정돼 있어, compileSdk 36 을
    // 요구하는 최신 의존성(flutter_plugin_android_lifecycle)과 AAR 메타데이터 충돌이 난다.
    // 안드로이드 서브프로젝트의 compileSdk 를 36 으로 통일해 해소한다(런타임 동작 무변경).
    // (evaluationDependsOn 보다 먼저 afterEvaluate 를 등록해야 한다.)
    afterEvaluate {
        extensions.findByName("android")?.withGroovyBuilder {
            "compileSdkVersion"(36)
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
