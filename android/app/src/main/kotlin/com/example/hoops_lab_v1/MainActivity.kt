package com.example.hoops_lab_v1

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.pm.PackageManager

class MainActivity: FlutterActivity() {
    private val NATIVE_SECRETS_CHANNEL = "com.example.hoops_lab_v1/native_secrets"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NATIVE_SECRETS_CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "getMapsApiKey" -> {
                    try {
                        val appInfo = packageManager.getApplicationInfo(packageName, PackageManager.GET_META_DATA)
                        val apiKey = appInfo.metaData.getString("com.google.android.geo.API_KEY")
                        result.success(apiKey)
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", "Could not retrieve Maps API key.", null)
                    }
                }
                "getGeminiApiKey" -> {
                    result.success(BuildConfig.GEMINI_API_KEY)
                }
                else -> result.notImplemented()
            }
        }
    }
}