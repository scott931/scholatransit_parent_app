package com.scholatransit.driver.scholatransit_parent_app

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import android.content.Intent
import android.os.Build
import androidx.localbroadcastmanager.content.LocalBroadcastManager

class AppNotificationListenerService : NotificationListenerService() {
    companion object {
        private const val TAG = "NotificationListener"
        private var instance: AppNotificationListenerService? = null
        const val ACTION_NOTIFICATION_POSTED = "com.scholatransit.driver.NOTIFICATION_POSTED"
        const val ACTION_NOTIFICATION_REMOVED = "com.scholatransit.driver.NOTIFICATION_REMOVED"
        const val EXTRA_NOTIFICATION_DATA = "notification_data"

        fun getInstance(): AppNotificationListenerService? = instance
    }

    private var localBroadcastManager: LocalBroadcastManager? = null

    override fun onCreate() {
        super.onCreate()
        instance = this
        localBroadcastManager = LocalBroadcastManager.getInstance(this)
        Log.d(TAG, "NotificationListenerService created")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        super.onNotificationPosted(sbn)
        val notification = sbn.notification
        val packageName = sbn.packageName

        // Extract notification data
        val title = notification.extras?.getCharSequence("android.title")?.toString() ?: ""
        val text = notification.extras?.getCharSequence("android.text")?.toString() ?: ""
        val ticker = notification.tickerText?.toString() ?: ""
        val postTime = sbn.postTime

        val notificationData = mapOf(
            "packageName" to packageName,
            "title" to title,
            "text" to text,
            "ticker" to ticker,
            "postTime" to postTime,
            "id" to sbn.id,
            "tag" to (sbn.tag ?: ""),
            "key" to sbn.key,
            "isGroup" to (notification.extras?.getBoolean("android.isGroupSummary") ?: false)
        )

        Log.d(TAG, "Notification posted: $packageName - $title")

        // Send broadcast to MainActivity
        sendBroadcast(ACTION_NOTIFICATION_POSTED, notificationData)
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        super.onNotificationRemoved(sbn)
        val notificationData = mapOf(
            "packageName" to sbn.packageName,
            "id" to sbn.id,
            "tag" to (sbn.tag ?: ""),
            "key" to sbn.key
        )

        Log.d(TAG, "Notification removed: ${sbn.packageName}")

        // Send broadcast to MainActivity
        sendBroadcast(ACTION_NOTIFICATION_REMOVED, notificationData)
    }

    private fun sendBroadcast(action: String, data: Map<String, Any?>) {
        val intent = Intent(action).apply {
            // Convert map to HashMap for serialization
            val hashMap = HashMap<String, Any?>()
            hashMap.putAll(data)
            putExtra(EXTRA_NOTIFICATION_DATA, hashMap)
        }
        localBroadcastManager?.sendBroadcast(intent)
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        Log.d(TAG, "NotificationListenerService destroyed")
    }

    fun getActiveNotificationsAsMap(): List<Map<String, Any?>> {
        val notifications = try {
            val activeNotifs = getActiveNotifications()
            if (activeNotifs != null) {
                activeNotifs.map { sbn ->
                    val notification = sbn.notification
                    mapOf(
                        "packageName" to sbn.packageName,
                        "title" to (notification.extras?.getCharSequence("android.title")?.toString() ?: ""),
                        "text" to (notification.extras?.getCharSequence("android.text")?.toString() ?: ""),
                        "ticker" to (notification.tickerText?.toString() ?: ""),
                        "postTime" to sbn.postTime,
                        "id" to sbn.id,
                        "tag" to (sbn.tag ?: ""),
                        "key" to sbn.key,
                        "isGroup" to (notification.extras?.getBoolean("android.isGroupSummary") ?: false)
                    )
                }
            } else {
                emptyList()
            }
        } catch (e: SecurityException) {
            Log.e(TAG, "SecurityException getting active notifications: ${e.message}")
            emptyList()
        }

        return notifications
    }
}

