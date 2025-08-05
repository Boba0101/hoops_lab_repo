/*
 * Copyright 2018 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

@file:Suppress(
    "unused",
    "nothing_to_inline",
    "useless_cast",
    "unchecked_cast",
    "extension_shadowed_by_member",
    "redundant_projection",
    "RemoveRedundantBackticks",
    "ObjectPropertyName",
    "deprecation",
    "detekt:all"
)
@file:org.gradle.api.Generated

package org.gradle.kotlin.dsl

import org.gradle.plugin.use.PluginDependenciesSpec
import org.gradle.plugin.use.PluginDependencySpec
import FlutterPlugin
import FlutterAppPluginLoaderPlugin


/**
 * The `android` plugin implemented by [com.android.build.gradle.AppPlugin].
 */
val `PluginDependenciesSpec`.`android`: PluginDependencySpec
    get() = this.id("android")


/**
 * The `android-library` plugin implemented by [com.android.build.gradle.LibraryPlugin].
 */
val `PluginDependenciesSpec`.`android-library`: PluginDependencySpec
    get() = this.id("android-library")


/**
 * The `android-reporting` plugin implemented by [com.android.build.gradle.ReportingPlugin].
 */
val `PluginDependenciesSpec`.`android-reporting`: PluginDependencySpec
    get() = this.id("android-reporting")


/**
 * The `com` plugin group.
 */
@org.gradle.api.Generated
class `ComPluginGroup`(internal val plugins: PluginDependenciesSpec)


/**
 * Plugin ids starting with `com`.
 */
val `PluginDependenciesSpec`.`com`: `ComPluginGroup`
    get() = `ComPluginGroup`(this)


/**
 * The `com.android` plugin group.
 */
@org.gradle.api.Generated
class `ComAndroidPluginGroup`(internal val plugins: PluginDependenciesSpec)


/**
 * Plugin ids starting with `com.android`.
 */
val `ComPluginGroup`.`android`: `ComAndroidPluginGroup`
    get() = `ComAndroidPluginGroup`(plugins)


/**
 * The `com.android.ai-pack` plugin implemented by [com.android.build.gradle.AiPackPlugin].
 */
val `ComAndroidPluginGroup`.`ai-pack`: PluginDependencySpec
    get() = plugins.id("com.android.ai-pack")


/**
 * The `com.android.application` plugin implemented by [com.android.build.gradle.AppPlugin].
 */
val `ComAndroidPluginGroup`.`application`: PluginDependencySpec
    get() = plugins.id("com.android.application")


/**
 * The `com.android.asset-pack` plugin implemented by [com.android.build.gradle.AssetPackPlugin].
 */
val `ComAndroidPluginGroup`.`asset-pack`: PluginDependencySpec
    get() = plugins.id("com.android.asset-pack")


/**
 * The `com.android.asset-pack-bundle` plugin implemented by [com.android.build.gradle.AssetPackBundlePlugin].
 */
val `ComAndroidPluginGroup`.`asset-pack-bundle`: PluginDependencySpec
    get() = plugins.id("com.android.asset-pack-bundle")


/**
 * The `com.android.base` plugin implemented by [com.android.build.gradle.api.AndroidBasePlugin].
 */
val `ComAndroidPluginGroup`.`base`: PluginDependencySpec
    get() = plugins.id("com.android.base")


/**
 * The `com.android.dynamic-feature` plugin implemented by [com.android.build.gradle.DynamicFeaturePlugin].
 */
val `ComAndroidPluginGroup`.`dynamic-feature`: PluginDependencySpec
    get() = plugins.id("com.android.dynamic-feature")


/**
 * The `com.android.ecosystem` plugin implemented by [com.android.build.gradle.AndroidEcosystemPlugin].
 */
val `ComAndroidPluginGroup`.`ecosystem`: PluginDependencySpec
    get() = plugins.id("com.android.ecosystem")


/**
 * The `com.android.fused-library` plugin implemented by [com.android.build.gradle.api.FusedLibraryPlugin].
 */
val `ComAndroidPluginGroup`.`fused-library`: PluginDependencySpec
    get() = plugins.id("com.android.fused-library")


/**
 * The `com.android.internal` plugin group.
 */
@org.gradle.api.Generated
class `ComAndroidInternalPluginGroup`(internal val plugins: PluginDependenciesSpec)


/**
 * Plugin ids starting with `com.android.internal`.
 */
val `ComAndroidPluginGroup`.`internal`: `ComAndroidInternalPluginGroup`
    get() = `ComAndroidInternalPluginGroup`(plugins)


/**
 * The `com.android.internal.ai-pack` plugin implemented by [com.android.build.gradle.internal.plugins.AiPackPlugin].
 */
val `ComAndroidInternalPluginGroup`.`ai-pack`: PluginDependencySpec
    get() = plugins.id("com.android.internal.ai-pack")


/**
 * The `com.android.internal.application` plugin implemented by [com.android.build.gradle.internal.plugins.AppPlugin].
 */
val `ComAndroidInternalPluginGroup`.`application`: PluginDependencySpec
    get() = plugins.id("com.android.internal.application")


/**
 * The `com.android.internal.asset-pack` plugin implemented by [com.android.build.gradle.internal.plugins.AssetPackPlugin].
 */
val `ComAndroidInternalPluginGroup`.`asset-pack`: PluginDependencySpec
    get() = plugins.id("com.android.internal.asset-pack")


/**
 * The `com.android.internal.asset-pack-bundle` plugin implemented by [com.android.build.gradle.internal.plugins.AssetPackBundlePlugin].
 */
val `ComAndroidInternalPluginGroup`.`asset-pack-bundle`: PluginDependencySpec
    get() = plugins.id("com.android.internal.asset-pack-bundle")


/**
 * The `com.android.internal.dynamic-feature` plugin implemented by [com.android.build.gradle.internal.plugins.DynamicFeaturePlugin].
 */
val `ComAndroidInternalPluginGroup`.`dynamic-feature`: PluginDependencySpec
    get() = plugins.id("com.android.internal.dynamic-feature")


/**
 * The `com.android.internal.ecosystem` plugin implemented by [com.android.build.gradle.internal.plugins.AndroidEcosystemPlugin].
 */
val `ComAndroidInternalPluginGroup`.`ecosystem`: PluginDependencySpec
    get() = plugins.id("com.android.internal.ecosystem")


/**
 * The `com.android.internal.fused-library` plugin implemented by [com.android.build.gradle.internal.plugins.FusedLibraryPlugin].
 */
val `ComAndroidInternalPluginGroup`.`fused-library`: PluginDependencySpec
    get() = plugins.id("com.android.internal.fused-library")


/**
 * The `com.android.internal.kotlin` plugin group.
 */
@org.gradle.api.Generated
class `ComAndroidInternalKotlinPluginGroup`(internal val plugins: PluginDependenciesSpec)


/**
 * Plugin ids starting with `com.android.internal.kotlin`.
 */
val `ComAndroidInternalPluginGroup`.`kotlin`: `ComAndroidInternalKotlinPluginGroup`
    get() = `ComAndroidInternalKotlinPluginGroup`(plugins)


/**
 * The `com.android.internal.kotlin.multiplatform` plugin group.
 */
@org.gradle.api.Generated
class `ComAndroidInternalKotlinMultiplatformPluginGroup`(internal val plugins: PluginDependenciesSpec)


/**
 * Plugin ids starting with `com.android.internal.kotlin.multiplatform`.
 */
val `ComAndroidInternalKotlinPluginGroup`.`multiplatform`: `ComAndroidInternalKotlinMultiplatformPluginGroup`
    get() = `ComAndroidInternalKotlinMultiplatformPluginGroup`(plugins)


/**
 * The `com.android.internal.kotlin.multiplatform.library` plugin implemented by [com.android.build.gradle.internal.plugins.KotlinMultiplatformAndroidPlugin].
 */
val `ComAndroidInternalKotlinMultiplatformPluginGroup`.`library`: PluginDependencySpec
    get() = plugins.id("com.android.internal.kotlin.multiplatform.library")


/**
 * The `com.android.internal.library` plugin implemented by [com.android.build.gradle.internal.plugins.LibraryPlugin].
 */
val `ComAndroidInternalPluginGroup`.`library`: PluginDependencySpec
    get() = plugins.id("com.android.internal.library")


/**
 * The `com.android.internal.lint` plugin implemented by [com.android.build.gradle.internal.plugins.LintPlugin].
 */
val `ComAndroidInternalPluginGroup`.`lint`: PluginDependencySpec
    get() = plugins.id("com.android.internal.lint")


/**
 * The `com.android.internal.privacy-sandbox-sdk` plugin implemented by [com.android.build.gradle.internal.plugins.PrivacySandboxSdkPlugin].
 */
val `ComAndroidInternalPluginGroup`.`privacy-sandbox-sdk`: PluginDependencySpec
    get() = plugins.id("com.android.internal.privacy-sandbox-sdk")


/**
 * The `com.android.internal.reporting` plugin implemented by [com.android.build.gradle.internal.plugins.ReportingPlugin].
 */
val `ComAndroidInternalPluginGroup`.`reporting`: PluginDependencySpec
    get() = plugins.id("com.android.internal.reporting")


/**
 * The `com.android.internal.test` plugin implemented by [com.android.build.gradle.internal.plugins.TestPlugin].
 */
val `ComAndroidInternalPluginGroup`.`test`: PluginDependencySpec
    get() = plugins.id("com.android.internal.test")


/**
 * The `com.android.internal.version-check` plugin implemented by [com.android.build.gradle.internal.plugins.VersionCheckPlugin].
 */
val `ComAndroidInternalPluginGroup`.`version-check`: PluginDependencySpec
    get() = plugins.id("com.android.internal.version-check")


/**
 * The `com.android.kotlin` plugin group.
 */
@org.gradle.api.Generated
class `ComAndroidKotlinPluginGroup`(internal val plugins: PluginDependenciesSpec)


/**
 * Plugin ids starting with `com.android.kotlin`.
 */
val `ComAndroidPluginGroup`.`kotlin`: `ComAndroidKotlinPluginGroup`
    get() = `ComAndroidKotlinPluginGroup`(plugins)


/**
 * The `com.android.kotlin.multiplatform` plugin group.
 */
@org.gradle.api.Generated
class `ComAndroidKotlinMultiplatformPluginGroup`(internal val plugins: PluginDependenciesSpec)


/**
 * Plugin ids starting with `com.android.kotlin.multiplatform`.
 */
val `ComAndroidKotlinPluginGroup`.`multiplatform`: `ComAndroidKotlinMultiplatformPluginGroup`
    get() = `ComAndroidKotlinMultiplatformPluginGroup`(plugins)


/**
 * The `com.android.kotlin.multiplatform.library` plugin implemented by [com.android.build.gradle.api.KotlinMultiplatformAndroidPlugin].
 */
val `ComAndroidKotlinMultiplatformPluginGroup`.`library`: PluginDependencySpec
    get() = plugins.id("com.android.kotlin.multiplatform.library")


/**
 * The `com.android.library` plugin implemented by [com.android.build.gradle.LibraryPlugin].
 */
val `ComAndroidPluginGroup`.`library`: PluginDependencySpec
    get() = plugins.id("com.android.library")


/**
 * The `com.android.lint` plugin implemented by [com.android.build.gradle.LintPlugin].
 */
val `ComAndroidPluginGroup`.`lint`: PluginDependencySpec
    get() = plugins.id("com.android.lint")


/**
 * The `com.android.privacy-sandbox-sdk` plugin implemented by [com.android.build.gradle.api.PrivacySandboxSdkPlugin].
 */
val `ComAndroidPluginGroup`.`privacy-sandbox-sdk`: PluginDependencySpec
    get() = plugins.id("com.android.privacy-sandbox-sdk")


/**
 * The `com.android.reporting` plugin implemented by [com.android.build.gradle.ReportingPlugin].
 */
val `ComAndroidPluginGroup`.`reporting`: PluginDependencySpec
    get() = plugins.id("com.android.reporting")


/**
 * The `com.android.test` plugin implemented by [com.android.build.gradle.TestPlugin].
 */
val `ComAndroidPluginGroup`.`test`: PluginDependencySpec
    get() = plugins.id("com.android.test")


/**
 * The `com.google` plugin group.
 */
@org.gradle.api.Generated
class `ComGooglePluginGroup`(internal val plugins: PluginDependenciesSpec)


/**
 * Plugin ids starting with `com.google`.
 */
val `ComPluginGroup`.`google`: `ComGooglePluginGroup`
    get() = `ComGooglePluginGroup`(plugins)


/**
 * The `com.google.android` plugin group.
 */
@org.gradle.api.Generated
class `ComGoogleAndroidPluginGroup`(internal val plugins: PluginDependenciesSpec)


/**
 * Plugin ids starting with `com.google.android`.
 */
val `ComGooglePluginGroup`.`android`: `ComGoogleAndroidPluginGroup`
    get() = `ComGoogleAndroidPluginGroup`(plugins)


/**
 * The `com.google.android.gms` plugin group.
 */
@org.gradle.api.Generated
class `ComGoogleAndroidGmsPluginGroup`(internal val plugins: PluginDependenciesSpec)


/**
 * Plugin ids starting with `com.google.android.gms`.
 */
val `ComGoogleAndroidPluginGroup`.`gms`: `ComGoogleAndroidGmsPluginGroup`
    get() = `ComGoogleAndroidGmsPluginGroup`(plugins)


/**
 * The `com.google.android.gms.strict-version-matcher-plugin` plugin implemented by [com.google.android.gms.StrictVersionMatcherPlugin].
 */
val `ComGoogleAndroidGmsPluginGroup`.`strict-version-matcher-plugin`: PluginDependencySpec
    get() = plugins.id("com.google.android.gms.strict-version-matcher-plugin")


/**
 * The `com.google.gms` plugin group.
 */
@org.gradle.api.Generated
class `ComGoogleGmsPluginGroup`(internal val plugins: PluginDependenciesSpec)


/**
 * Plugin ids starting with `com.google.gms`.
 */
val `ComGooglePluginGroup`.`gms`: `ComGoogleGmsPluginGroup`
    get() = `ComGoogleGmsPluginGroup`(plugins)


/**
 * The `com.google.gms.google-services` plugin implemented by [com.google.gms.googleservices.GoogleServicesPlugin].
 */
val `ComGoogleGmsPluginGroup`.`google-services`: PluginDependencySpec
    get() = plugins.id("com.google.gms.google-services")


/**
 * The `dev` plugin group.
 */
@org.gradle.api.Generated
class `DevPluginGroup`(internal val plugins: PluginDependenciesSpec)


/**
 * Plugin ids starting with `dev`.
 */
val `PluginDependenciesSpec`.`dev`: `DevPluginGroup`
    get() = `DevPluginGroup`(this)


/**
 * The `dev.flutter` plugin group.
 */
@org.gradle.api.Generated
class `DevFlutterPluginGroup`(internal val plugins: PluginDependenciesSpec)


/**
 * Plugin ids starting with `dev.flutter`.
 */
val `DevPluginGroup`.`flutter`: `DevFlutterPluginGroup`
    get() = `DevFlutterPluginGroup`(plugins)


/**
 * The `dev.flutter.flutter-gradle-plugin` plugin implemented by [FlutterPlugin].
 */
val `DevFlutterPluginGroup`.`flutter-gradle-plugin`: PluginDependencySpec
    get() = plugins.id("dev.flutter.flutter-gradle-plugin")


/**
 * The `dev.flutter.flutter-plugin-loader` plugin implemented by [FlutterAppPluginLoaderPlugin].
 */
val `DevFlutterPluginGroup`.`flutter-plugin-loader`: PluginDependencySpec
    get() = plugins.id("dev.flutter.flutter-plugin-loader")


/**
 * The `kotlin` plugin implemented by [org.jetbrains.kotlin.gradle.plugin.KotlinPluginWrapper].
 */
val `PluginDependenciesSpec`.`kotlin`: PluginDependencySpec
    get() = this.id("kotlin")


/**
 * The `kotlin-android` plugin implemented by [org.jetbrains.kotlin.gradle.plugin.KotlinAndroidPluginWrapper].
 */
val `PluginDependenciesSpec`.`kotlin-android`: PluginDependencySpec
    get() = this.id("kotlin-android")


/**
 * The `kotlin-android-extensions` plugin implemented by [org.jetbrains.kotlin.gradle.internal.AndroidExtensionsSubpluginIndicator].
 */
val `PluginDependenciesSpec`.`kotlin-android-extensions`: PluginDependencySpec
    get() = this.id("kotlin-android-extensions")


/**
 * The `kotlin-kapt` plugin implemented by [org.jetbrains.kotlin.gradle.internal.Kapt3GradleSubplugin].
 */
val `PluginDependenciesSpec`.`kotlin-kapt`: PluginDependencySpec
    get() = this.id("kotlin-kapt")


/**
 * The `kotlin-multiplatform` plugin implemented by [org.jetbrains.kotlin.gradle.plugin.KotlinMultiplatformPluginWrapper].
 */
val `PluginDependenciesSpec`.`kotlin-multiplatform`: PluginDependencySpec
    get() = this.id("kotlin-multiplatform")


/**
 * The `kotlin-native-cocoapods` plugin implemented by [org.jetbrains.kotlin.gradle.plugin.cocoapods.KotlinCocoapodsPlugin].
 */
val `PluginDependenciesSpec`.`kotlin-native-cocoapods`: PluginDependencySpec
    get() = this.id("kotlin-native-cocoapods")


/**
 * The `kotlin-native-performance` plugin implemented by [org.jetbrains.kotlin.gradle.plugin.performance.KotlinPerformancePlugin].
 */
val `PluginDependenciesSpec`.`kotlin-native-performance`: PluginDependencySpec
    get() = this.id("kotlin-native-performance")


/**
 * The `kotlin-parcelize` plugin implemented by [org.jetbrains.kotlin.gradle.internal.ParcelizeSubplugin].
 */
val `PluginDependenciesSpec`.`kotlin-parcelize`: PluginDependencySpec
    get() = this.id("kotlin-parcelize")


/**
 * The `kotlin-platform-android` plugin implemented by [org.jetbrains.kotlin.gradle.plugin.KotlinPlatformAndroidPlugin].
 */
val `PluginDependenciesSpec`.`kotlin-platform-android`: PluginDependencySpec
    get() = this.id("kotlin-platform-android")


/**
 * The `kotlin-platform-common` plugin implemented by [org.jetbrains.kotlin.gradle.plugin.KotlinPlatformCommonPlugin].
 */
val `PluginDependenciesSpec`.`kotlin-platform-common`: PluginDependencySpec
    get() = this.id("kotlin-platform-common")


/**
 * The `kotlin-platform-js` plugin implemented by [org.jetbrains.kotlin.gradle.plugin.KotlinPlatformJsPlugin].
 */
val `PluginDependenciesSpec`.`kotlin-platform-js`: PluginDependencySpec
    get() = this.id("kotlin-platform-js")


/**
 * The `kotlin-platform-jvm` plugin implemented by [org.jetbrains.kotlin.gradle.plugin.KotlinPlatformJvmPlugin].
 */
val `PluginDependenciesSpec`.`kotlin-platform-jvm`: PluginDependencySpec
    get() = this.id("kotlin-platform-jvm")


/**
 * The `kotlin-scripting` plugin implemented by [org.jetbrains.kotlin.gradle.scripting.internal.ScriptingGradleSubplugin].
 */
val `PluginDependenciesSpec`.`kotlin-scripting`: PluginDependencySpec
    get() = this.id("kotlin-scripting")


/**
 * The `org` plugin group.
 */
@org.gradle.api.Generated
class `OrgPluginGroup`(internal val plugins: PluginDependenciesSpec)


/**
 * Plugin ids starting with `org`.
 */
val `PluginDependenciesSpec`.`org`: `OrgPluginGroup`
    get() = `OrgPluginGroup`(this)


/**
 * The `org.jetbrains` plugin group.
 */
@org.gradle.api.Generated
class `OrgJetbrainsPluginGroup`(internal val plugins: PluginDependenciesSpec)


/**
 * Plugin ids starting with `org.jetbrains`.
 */
val `OrgPluginGroup`.`jetbrains`: `OrgJetbrainsPluginGroup`
    get() = `OrgJetbrainsPluginGroup`(plugins)


/**
 * The `org.jetbrains.kotlin` plugin group.
 */
@org.gradle.api.Generated
class `OrgJetbrainsKotlinPluginGroup`(internal val plugins: PluginDependenciesSpec)


/**
 * Plugin ids starting with `org.jetbrains.kotlin`.
 */
val `OrgJetbrainsPluginGroup`.`kotlin`: `OrgJetbrainsKotlinPluginGroup`
    get() = `OrgJetbrainsKotlinPluginGroup`(plugins)


/**
 * The `org.jetbrains.kotlin.android` plugin implemented by [org.jetbrains.kotlin.gradle.plugin.KotlinAndroidPluginWrapper].
 */
val `OrgJetbrainsKotlinPluginGroup`.`android`: PluginDependencySpec
    get() = plugins.id("org.jetbrains.kotlin.android")


/**
 * The `org.jetbrains.kotlin.js` plugin implemented by [org.jetbrains.kotlin.gradle.plugin.KotlinJsPluginWrapper].
 */
val `OrgJetbrainsKotlinPluginGroup`.`js`: PluginDependencySpec
    get() = plugins.id("org.jetbrains.kotlin.js")


/**
 * The `org.jetbrains.kotlin.jvm` plugin implemented by [org.jetbrains.kotlin.gradle.plugin.KotlinPluginWrapper].
 */
val `OrgJetbrainsKotlinPluginGroup`.`jvm`: PluginDependencySpec
    get() = plugins.id("org.jetbrains.kotlin.jvm")


/**
 * The `org.jetbrains.kotlin.kapt` plugin implemented by [org.jetbrains.kotlin.gradle.internal.Kapt3GradleSubplugin].
 */
val `OrgJetbrainsKotlinPluginGroup`.`kapt`: PluginDependencySpec
    get() = plugins.id("org.jetbrains.kotlin.kapt")


/**
 * The `org.jetbrains.kotlin.multiplatform` plugin implemented by [org.jetbrains.kotlin.gradle.plugin.KotlinMultiplatformPluginWrapper].
 */
val `OrgJetbrainsKotlinPluginGroup`.`multiplatform`: PluginDependencySpec
    get() = plugins.id("org.jetbrains.kotlin.multiplatform")


/**
 * The `org.jetbrains.kotlin.native` plugin group.
 */
@org.gradle.api.Generated
class `OrgJetbrainsKotlinNativePluginGroup`(internal val plugins: PluginDependenciesSpec)


/**
 * Plugin ids starting with `org.jetbrains.kotlin.native`.
 */
val `OrgJetbrainsKotlinPluginGroup`.`native`: `OrgJetbrainsKotlinNativePluginGroup`
    get() = `OrgJetbrainsKotlinNativePluginGroup`(plugins)


/**
 * The `org.jetbrains.kotlin.native.cocoapods` plugin implemented by [org.jetbrains.kotlin.gradle.plugin.cocoapods.KotlinCocoapodsPlugin].
 */
val `OrgJetbrainsKotlinNativePluginGroup`.`cocoapods`: PluginDependencySpec
    get() = plugins.id("org.jetbrains.kotlin.native.cocoapods")


/**
 * The `org.jetbrains.kotlin.native.performance` plugin implemented by [org.jetbrains.kotlin.gradle.plugin.performance.KotlinPerformancePlugin].
 */
val `OrgJetbrainsKotlinNativePluginGroup`.`performance`: PluginDependencySpec
    get() = plugins.id("org.jetbrains.kotlin.native.performance")


/**
 * The `org.jetbrains.kotlin.platform` plugin group.
 */
@org.gradle.api.Generated
class `OrgJetbrainsKotlinPlatformPluginGroup`(internal val plugins: PluginDependenciesSpec)


/**
 * Plugin ids starting with `org.jetbrains.kotlin.platform`.
 */
val `OrgJetbrainsKotlinPluginGroup`.`platform`: `OrgJetbrainsKotlinPlatformPluginGroup`
    get() = `OrgJetbrainsKotlinPlatformPluginGroup`(plugins)


/**
 * The `org.jetbrains.kotlin.platform.android` plugin implemented by [org.jetbrains.kotlin.gradle.plugin.KotlinPlatformAndroidPlugin].
 */
val `OrgJetbrainsKotlinPlatformPluginGroup`.`android`: PluginDependencySpec
    get() = plugins.id("org.jetbrains.kotlin.platform.android")


/**
 * The `org.jetbrains.kotlin.platform.common` plugin implemented by [org.jetbrains.kotlin.gradle.plugin.KotlinPlatformCommonPlugin].
 */
val `OrgJetbrainsKotlinPlatformPluginGroup`.`common`: PluginDependencySpec
    get() = plugins.id("org.jetbrains.kotlin.platform.common")


/**
 * The `org.jetbrains.kotlin.platform.js` plugin implemented by [org.jetbrains.kotlin.gradle.plugin.KotlinPlatformJsPlugin].
 */
val `OrgJetbrainsKotlinPlatformPluginGroup`.`js`: PluginDependencySpec
    get() = plugins.id("org.jetbrains.kotlin.platform.js")


/**
 * The `org.jetbrains.kotlin.platform.jvm` plugin implemented by [org.jetbrains.kotlin.gradle.plugin.KotlinPlatformJvmPlugin].
 */
val `OrgJetbrainsKotlinPlatformPluginGroup`.`jvm`: PluginDependencySpec
    get() = plugins.id("org.jetbrains.kotlin.platform.jvm")


/**
 * The `org.jetbrains.kotlin.plugin` plugin group.
 */
@org.gradle.api.Generated
class `OrgJetbrainsKotlinPluginPluginGroup`(internal val plugins: PluginDependenciesSpec)


/**
 * Plugin ids starting with `org.jetbrains.kotlin.plugin`.
 */
val `OrgJetbrainsKotlinPluginGroup`.`plugin`: `OrgJetbrainsKotlinPluginPluginGroup`
    get() = `OrgJetbrainsKotlinPluginPluginGroup`(plugins)


/**
 * The `org.jetbrains.kotlin.plugin.parcelize` plugin implemented by [org.jetbrains.kotlin.gradle.internal.ParcelizeSubplugin].
 */
val `OrgJetbrainsKotlinPluginPluginGroup`.`parcelize`: PluginDependencySpec
    get() = plugins.id("org.jetbrains.kotlin.plugin.parcelize")


/**
 * The `org.jetbrains.kotlin.plugin.scripting` plugin implemented by [org.jetbrains.kotlin.gradle.scripting.internal.ScriptingGradleSubplugin].
 */
val `OrgJetbrainsKotlinPluginPluginGroup`.`scripting`: PluginDependencySpec
    get() = plugins.id("org.jetbrains.kotlin.plugin.scripting")
