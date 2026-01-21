package com.vaultsafe.app

import android.content.Context
import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/// Platform channel handler for Android-specific features
class PlatformHandler(private val context: Context) : MethodCallHandler {
    companion object {
        const val CHANNEL = "com.vaultsafe/platform"
    }

    fun registerWith(messenger: io.flutter.plugin.common.BinaryMessenger) {
        val channel = MethodChannel(messenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "setSecureFlag" -> {
                // Secure flag is set in MainActivity
                result.success(true)
            }
            "enablePrivacyScreen" -> {
                // Already handled by FLAG_SECURE in AndroidManifest
                result.success(true)
            }
            "disablePrivacyScreen" -> {
                // Cannot disable on Android (security feature)
                result.success(false)
            }
            "isInBackground" -> {
                val isInBackground = !isAppInForeground()
                result.success(isInBackground)
            }
            "minimizeApp" -> {
                // Move task to back
                val activity = (context as? android.app.Activity)
                activity?.moveTaskToBack(true)
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun isAppInForeground(): Boolean {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
        val runningProcesses = activityManager.runningAppProcesses ?: return false

        for (processInfo in runningProcesses) {
            if (processInfo.importance == android.app.ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND) {
                return true
            }
        }
        return false
    }
}
