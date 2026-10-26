package com.zuru.app

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle
import com.cloudwebrtc.webrtc.audio.AudioSwitchManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private var pendingBluetoothResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannels()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Must match StreamAudio._channel on the Dart side.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.zuru.app/audio")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "ensureBluetoothPermission" -> ensureBluetoothPermission(result)
                    else -> result.notImplemented()
                }
            }
        // Must match NotificationService._androidChannel on the Dart side.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.zuru.app/notifications")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "playAlert" -> {
                        playNotificationSound(call.argument<String>("channelId"))
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
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

    // FCM shows nothing for a push while the app is open, so it would arrive
    // silently. Play the push's channel sound instead, unless the user has
    // muted notifications or that channel. The notification audio usage also
    // keeps Do Not Disturb and silent mode in charge.
    private fun playNotificationSound(channelId: String?) {
        val manager = getSystemService(NotificationManager::class.java) ?: return
        if (!manager.areNotificationsEnabled()) return

        val channel = manager.getNotificationChannel(channelId ?: DEFAULT_CHANNEL_ID)
            ?: manager.getNotificationChannel(DEFAULT_CHANNEL_ID)
        if (channel != null &&
            (channel.importance < NotificationManager.IMPORTANCE_DEFAULT || channel.sound == null)
        ) {
            return
        }

        val sound = channel?.sound ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        val ringtone = RingtoneManager.getRingtone(applicationContext, sound) ?: return
        ringtone.audioAttributes = channel?.audioAttributes
            ?: AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
        ringtone.play()
    }

    // ── Bluetooth audio ──────────────────────────────────────────────────────

    // Android 12+ needs BLUETOOTH_CONNECT at runtime before Bluetooth headsets
    // can carry a live's audio. Resolves true when granted.
    private fun ensureBluetoothPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S || hasBluetoothPermission()) {
            result.success(true)
            return
        }
        if (pendingBluetoothResult != null) {
            result.success(false)
            return
        }
        pendingBluetoothResult = result
        requestPermissions(
            arrayOf(Manifest.permission.BLUETOOTH_CONNECT),
            BLUETOOTH_REQUEST_CODE,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != BLUETOOTH_REQUEST_CODE) return

        val granted = grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
        if (granted) restartWebRtcAudioSwitch()
        pendingBluetoothResult?.success(granted)
        pendingBluetoothResult = null
    }

    private fun hasBluetoothPermission() =
        checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) ==
            PackageManager.PERMISSION_GRANTED

    // flutter_webrtc builds its AudioSwitch when the engine starts and only
    // wires up Bluetooth headsets if BLUETOOTH_CONNECT is granted by then.
    // Rebuild it after a fresh grant so this session can use headsets without
    // an app restart. Only called before a room connects, while no call is
    // active. Relies on flutter_webrtc's public AudioSwitchManager.instance;
    // re-check this when upgrading flutter_webrtc.
    private fun restartWebRtcAudioSwitch() {
        val current = AudioSwitchManager.instance ?: return
        current.stop()
        val replacement = AudioSwitchManager(applicationContext)
        // Keeps the onDeviceChange events flowing to Dart. Copied by name: its
        // type lives in flutter_webrtc's private audioswitch dependency. The
        // new switch starts on the next main-loop turn, after this assignment.
        val listener = AudioSwitchManager::class.java.getField("audioDeviceChangeListener")
        listener.set(replacement, listener.get(current))
        AudioSwitchManager.instance = replacement
    }

    private companion object {
        const val BLUETOOTH_REQUEST_CODE = 4201

        // The manifest's default_notification_channel_id.
        const val DEFAULT_CHANNEL_ID = "mission_updates"
    }
}
