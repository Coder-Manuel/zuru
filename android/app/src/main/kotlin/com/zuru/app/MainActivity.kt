package com.zuru.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannels()
    }

    // Ids must match the channelId values in the backend push templates.
    private fun createNotificationChannels() {
        val manager = getSystemService(NotificationManager::class.java) ?: return
        manager.createNotificationChannels(
            listOf(
                NotificationChannel(
                    "mission_updates",
                    "Live check updates",
                    NotificationManager.IMPORTANCE_DEFAULT,
                ).apply {
                    description = "Accepted, declined and on-the-way updates"
                },
                NotificationChannel(
                    "live_alerts",
                    "Live alerts",
                    NotificationManager.IMPORTANCE_HIGH,
                ).apply {
                    description = "New requests, payments and lives starting now"
                },
            ),
        )
    }
}
