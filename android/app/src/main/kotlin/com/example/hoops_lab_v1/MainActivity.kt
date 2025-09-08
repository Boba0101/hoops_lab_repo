package com.example.hoops_lab_v1

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.pm.PackageManager
import android.os.Bundle

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.hoops_lab_v1/metadata"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "getApiKey") {
                try {
                    val appInfo = packageManager.getApplicationInfo(packageName, PackageManager.GET_META_DATA)
                    val apiKey = appInfo.metaData.getString("com.google.android.geo.API_KEY")
                    result.success(apiKey)
                } catch (e: Exception) {
                    result.error("UNAVAILABLE", "Could not retrieve API key.", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}