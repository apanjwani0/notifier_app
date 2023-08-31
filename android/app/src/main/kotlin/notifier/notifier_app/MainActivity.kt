package com.notifier.notifier_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.provider.Settings

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.yourapp.name/notification_access"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "hasNotificationAccess") {
                result.success(hasNotificationAccess())
            } else {
                result.notImplemented()
            }
        }
    }

    private fun hasNotificationAccess(): Boolean {
        val notificationListeners = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
        val myPackageName = packageName
        return notificationListeners?.contains(myPackageName) ?: false
    }
}
