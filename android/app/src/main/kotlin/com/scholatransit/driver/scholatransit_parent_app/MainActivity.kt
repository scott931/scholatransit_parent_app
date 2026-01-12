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
    private var isDestroyed = false
    
    private val notificationReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            // Check if activity is still valid before invoking methods
            if (isDestroyed || methodChannel == null) {
                Log.d(TAG, "Activity destroyed or channel null, skipping notification broadcast")
                return
            }
            
            try {
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
            } catch (e: Exception) {
                Log.w(TAG, "Error invoking method from broadcast receiver: ${e.message}")
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        isDestroyed = false

        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME
        )

        methodChannel?.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "isNotificationListenerEnabled" -> {
                        val enabled = isNotificationListenerEnabled()
                        safeResultSuccess(result, enabled)
                    }
                    "requestNotificationListenerPermission" -> {
                        requestNotificationListenerPermission()
                        safeResultSuccess(result, null)
                    }
                    "getActiveNotifications" -> {
                        try {
                            val service = AppNotificationListenerService.getInstance()
                            if (service != null) {
                                val notifications = service.getActiveNotificationsAsMap()
                                safeResultSuccess(result, notifications)
                            } else {
                                safeResultError(
                                    result,
                                    "SERVICE_NOT_AVAILABLE",
                                    "Notification listener service is not available",
                                    null
                                )
                            }
                        } catch (e: Exception) {
                            safeResultError(result, "ERROR", e.message, null)
                        }
                    }
                    else -> {
                        safeResultNotImplemented(result)
                    }
                }
            } catch (e: Exception) {
                Log.w(TAG, "Error handling method call ${call.method}: ${e.message}")
                safeResultError(result, "ERROR", e.message, null)
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
        isDestroyed = true
        methodChannel = null
        try {
            LocalBroadcastManager.getInstance(this).unregisterReceiver(notificationReceiver)
        } catch (e: Exception) {
            Log.w(TAG, "Error unregistering receiver: ${e.message}")
        }
    }

    /**
     * Safely send a success result, catching any exceptions if Flutter engine is detached
     */
    private fun safeResultSuccess(result: MethodChannel.Result, value: Any?) {
        try {
            if (!isDestroyed) {
                result.success(value)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to send success result (engine may be detached): ${e.message}")
        }
    }

    /**
     * Safely send an error result, catching any exceptions if Flutter engine is detached
     */
    private fun safeResultError(
        result: MethodChannel.Result,
        errorCode: String,
        errorMessage: String?,
        errorDetails: Any?
    ) {
        try {
            if (!isDestroyed) {
                result.error(errorCode, errorMessage, errorDetails)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to send error result (engine may be detached): ${e.message}")
        }
    }

    /**
     * Safely send a not implemented result, catching any exceptions if Flutter engine is detached
     */
    private fun safeResultNotImplemented(result: MethodChannel.Result) {
        try {
            if (!isDestroyed) {
                result.notImplemented()
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to send not implemented result (engine may be detached): ${e.message}")
        }
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
