import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import java.util.Properties
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.kotlin.serialization)
    alias(libs.plugins.google.services)
    alias(libs.plugins.play.publisher)
}

val buildCalendar = Calendar.getInstance()
val buildTime = SimpleDateFormat("yyMMddHH", Locale.US).format(buildCalendar.time)
val buildMinute = buildCalendar.get(Calendar.MINUTE)
val versionCodeValue = buildTime.toInt() * 60 + buildMinute

val keystorePropertiesFile = rootProject.file("keystore.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use(keystoreProperties::load)
}

val pushCopyFile = rootProject.layout.projectDirectory.file("../backend/assets/push-copy.json")
val pushCopyExamplesFile = rootProject.layout.projectDirectory.file("../backend/assets/push-copy-examples.json")

val androidCopybookCatalogDir = layout.buildDirectory.dir("generated/source/copybookCatalog/kotlin")
val androidCopybookCatalogFile = androidCopybookCatalogDir.map {
    it.file("org/entner/HitzeV/ui/copy/CopybookTranslationCatalog.kt")
}

val generateAndroidCopybookCatalog by tasks.registering(Exec::class) {
    val script = rootProject.file("../scripts/generate_android_copybook_catalog.py")
    val swiftCatalog = rootProject.file("../iOS/Hitze-V/Hitze-V/CopybookTranslationCatalog.swift")

    inputs.file(script)
    inputs.file(swiftCatalog)
    outputs.file(androidCopybookCatalogFile)

    doFirst {
        androidCopybookCatalogFile.get().asFile.parentFile.mkdirs()
    }

    commandLine(
        "python3",
        script.absolutePath,
        swiftCatalog.absolutePath,
        androidCopybookCatalogFile.get().asFile.absolutePath
    )
}

val validateAndroidCopybookLocalizations by tasks.registering(Exec::class) {
    val script = rootProject.file("../scripts/check_android_copybook_localizations.py")
    val androidCopybook = rootProject.file("app/src/main/java/org/entner/HitzeV/ui/copy/Copybook.kt")
    val swiftCatalog = rootProject.file("../iOS/Hitze-V/Hitze-V/CopybookTranslationCatalog.swift")
    val stampFile = layout.buildDirectory.file("intermediates/copybookValidation/validated.stamp")

    inputs.file(script)
    inputs.file(androidCopybook)
    inputs.file(swiftCatalog)
    // The script only reports; the stamp gives Gradle an output so the task can be UP-TO-DATE.
    outputs.file(stampFile)

    commandLine("python3", script.absolutePath, "--strict")

    doLast {
        stampFile.get().asFile.apply {
            parentFile.mkdirs()
            writeText("ok\n")
        }
    }
}

abstract class CopyPushCopyAsset : DefaultTask() {
    @get:InputFile
    @get:PathSensitive(PathSensitivity.NONE)
    abstract val pushCopy: RegularFileProperty

    @get:OutputDirectory
    abstract val outputDirectory: DirectoryProperty

    @TaskAction
    fun copy() {
        val target = outputDirectory.get().asFile
        target.deleteRecursively()
        target.mkdirs()
        pushCopy.get().asFile.copyTo(target.resolve("push-copy.json"), overwrite = true)
    }
}

val copyPushCopyAsset by tasks.registering(CopyPushCopyAsset::class) {
    pushCopy.set(pushCopyFile)
}

android {
    namespace = "org.entner.HitzeV"
    compileSdk {
        version = release(36)
    }

    defaultConfig {
        applicationId = "org.entner.HitzeV"
        minSdk = 26
        targetSdk = 36
        versionCode = versionCodeValue
        versionName = "1.0.${buildTime}.${buildMinute}"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        vectorDrawables {
            useSupportLibrary = true
        }
    }

    signingConfigs {
        if (keystoreProperties.isNotEmpty()) {
            create("release") {
                storeFile = file(keystoreProperties["storeFile"]!!.toString())
                storePassword = keystoreProperties["storePassword"]!!.toString()
                keyAlias = keystoreProperties["keyAlias"]!!.toString()
                keyPassword = keystoreProperties["keyPassword"]!!.toString()
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            if (keystoreProperties.isNotEmpty()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    buildFeatures {
        compose = true
        buildConfig = true
    }
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
    sourceSets {
        getByName("main").java.srcDir(androidCopybookCatalogDir)
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_11)
    }
}

androidComponents {
    onVariants { variant ->
        variant.sources.assets?.addGeneratedSourceDirectory(copyPushCopyAsset, CopyPushCopyAsset::outputDirectory)
    }
}

tasks.named("preBuild") {
    dependsOn(generateAndroidCopybookCatalog)
    dependsOn(validateAndroidCopybookLocalizations)
}

tasks.withType<Test>().configureEach {
    inputs.file(pushCopyFile).withPropertyName("pushCopy").withPathSensitivity(PathSensitivity.NONE)
    inputs.file(pushCopyExamplesFile).withPropertyName("pushCopyExamples").withPathSensitivity(PathSensitivity.NONE)
    systemProperty("hitzev.pushCopy", pushCopyFile.asFile.absolutePath)
    systemProperty("hitzev.pushCopyExamples", pushCopyExamplesFile.asFile.absolutePath)
}

play {
    defaultToAppBundles.set(true)
    track.set("Hitze-V")
    val playCredentialsPath = rootProject.findProperty("playPublisherCredentials")?.toString()
        ?: "play-publisher-credentials.json"
    val playCredentialsFile = rootProject.file(playCredentialsPath)
    if (playCredentialsFile.exists()) {
        serviceAccountCredentials.set(playCredentialsFile)
    }
}

dependencies {
    implementation(libs.androidx.appcompat)
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.core.splashscreen)
    implementation(libs.androidx.lifecycle.runtime.ktx)
    implementation(libs.androidx.lifecycle.runtime.compose)
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.datastore.preferences)
    implementation(libs.androidx.work.runtime.ktx)
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.ui.graphics)
    implementation(libs.androidx.compose.ui.tooling.preview)
    implementation(libs.androidx.compose.material3)
    implementation(libs.androidx.compose.material3.adaptive)
    implementation(libs.androidx.compose.material.icons.extended)
    implementation(libs.androidx.navigation.compose)
    implementation(platform(libs.firebase.bom))
    implementation(libs.firebase.messaging)
    implementation(libs.kotlinx.coroutines.play.services)
    implementation(libs.kotlinx.serialization.json)
    testImplementation(libs.junit)
    testImplementation(libs.kotlinx.coroutines.test)
    androidTestImplementation(libs.androidx.junit)
    androidTestImplementation(libs.androidx.espresso.core)
    androidTestImplementation(platform(libs.androidx.compose.bom))
    androidTestImplementation(libs.androidx.compose.ui.test.junit4)
    debugImplementation(libs.androidx.compose.ui.tooling)
    debugImplementation(libs.androidx.compose.ui.test.manifest)
}
