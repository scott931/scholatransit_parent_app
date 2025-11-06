package com.scholatransit.driver.scholatransit_parent_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.localbroadcastmanager.content.LocalBroadcastManager

class MainActivity : FlutterActivity() {
    private val CHANNEL_NAME = "com.scholatransit.driver/notification_listener"
    private val TAG = "MainActivity"
    private var methodChannel: MethodChannel? = null
    private val notificationReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                AppNotificationListenerService.ACTION_NOTIFICATION_POSTED -> {
                    val data = intent.getSerializableExtra(
                        AppNotificationListenerService.EXTRA_NOTIFICATION_DATA
                    ) as? Map<String, Any?>
                    methodChannel?.invokeMethod("onNotificationPosted", data)
                }
                AppNotificationListenerService.ACTION_NOTIFICATION_REMOVED -> {
                    val data = intent.getSerializableExtra(
                        AppNotificationListenerService.EXTRA_NOTIFICATION_DATA
                    ) as? Map<String, Any?>
                    methodChannel?.invokeMethod("onNotificationRemoved", data)
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME
        )

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isNotificationListenerEnabled" -> {
                    val enabled = isNotificationListenerEnabled()
                    result.success(enabled)
                }
                "requestNotificationListenerPermission" -> {
                    requestNotificationListenerPermission()
                    result.success(null)
                }
                "getActiveNotifications" -> {
                    try {
                        val service = AppNotificationListenerService.getInstance()
                        if (service != null) {
                            val notifications = service.getActiveNotificationsAsMap()
                            result.success(notifications)
                        } else {
                            result.error(
                                "SERVICE_NOT_AVAILABLE",
                                "Notification listener service is not available",
                                null
                            )
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Register broadcast receiver
        val filter = IntentFilter().apply {
            addAction(AppNotificationListenerService.ACTION_NOTIFICATION_POSTED)
            addAction(AppNotificationListenerService.ACTION_NOTIFICATION_REMOVED)
        }
        LocalBroadcastManager.getInstance(this).registerReceiver(notificationReceiver, filter)
    }

    override fun onDestroy() {
        super.onDestroy()
        LocalBroadcastManager.getInstance(this).unregisterReceiver(notificationReceiver)
    }

    private fun isNotificationListenerEnabled(): Boolean {
        val enabledListeners = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners"
        )

        val packageName = packageName
        return enabledListeners?.contains(packageName) == true
    }

    private fun requestNotificationListenerPermission() {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        startActivity(intent)
    }
}
