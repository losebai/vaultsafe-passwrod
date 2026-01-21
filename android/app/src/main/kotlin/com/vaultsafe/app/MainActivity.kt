package com.vaultsafe.app

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterFragmentActivity() {
    private lateinit var platformHandler: PlatformHandler

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        // Register platform handler
        platformHandler = PlatformHandler(this)
        platformHandler.registerWith(flutterEngine.dartExecutor.binaryMessenger)
    }

    // Prevent screenshots for security
    override fun onPause() {
        super.onPause()
        // Screen will be blurred when app goes to background
        window.setFlags(
            android.view.WindowManager.LayoutParams.FLAG_SECURE,
            android.view.WindowManager.LayoutParams.FLAG_SECURE
        )
    }

    override fun onResume() {
        super.onResume()
        // Remove secure flag when app is active (optional)
        // window.clearFlags(android.view.WindowManager.LayoutParams.FLAG_SECURE)
    }
}
