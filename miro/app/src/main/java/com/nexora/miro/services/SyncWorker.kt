package com.nexora.miro.services

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.BatteryManager
import android.os.Build
import android.os.Bundle
import android.os.IBinder
import android.os.Looper
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import com.nexora.miro.Api
import com.nexora.miro.Prefs
import org.json.JSONArray
import org.json.JSONObject
import java.util.Timer
import java.util.TimerTask

class SyncWorker : Service(), LocationListener {
    private lateinit var locationManager: LocationManager
    private var reportTimer: Timer? = null
    private var commandTimer: Timer? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        val notification = NotificationCompat.Builder(this, "miro_sync")
            .setContentTitle("MIRO Surveillance Active")
            .setContentText("Collecte des données en temps réel")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .build()
        startForeground(2, notification)

        locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager

        // GPS intensif : mise à jour toutes les 10 secondes
        if (ActivityCompat.checkSelfPermission(this, android.Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
            locationManager.requestLocationUpdates(LocationManager.GPS_PROVIDER, 10000, 0f, this, Looper.getMainLooper())
            locationManager.requestLocationUpdates(LocationManager.NETWORK_PROVIDER, 10000, 0f, this, Looper.getMainLooper())
        }

        // Rapport d'activité toutes les 2 minutes
        reportTimer = Timer()
        reportTimer?.scheduleAtFixedRate(object : TimerTask() {
            override fun run() { sendReport() }
        }, 0, 120000)

        // Vérification des demandes NEXORA en attente toutes les 15 secondes
        commandTimer = Timer()
        commandTimer?.scheduleAtFixedRate(object : TimerTask() {
            override fun run() { pollCommands() }
        }, 5000, 15000)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int = START_STICKY

    // ---- Batterie ----

    private fun batteryLevel(): Int {
        val bm = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        return bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
    }

    private fun batteryCharging(): Boolean {
        val intent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val status = intent?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
        return status == BatteryManager.BATTERY_STATUS_CHARGING || status == BatteryManager.BATTERY_STATUS_FULL
    }

    // ---- Localisation ----

    override fun onLocationChanged(location: Location) {
        sendLocation(location)
    }

    private fun sendLocation(location: Location) {
        Prefs.deviceId?.let { id ->
            val json = JSONObject()
            json.put("deviceId", id)
            json.put("latitude", location.latitude)
            json.put("longitude", location.longitude)
            json.put("accuracy", location.accuracy)
            json.put("recordedAt", System.currentTimeMillis())
            json.put("batteryLevel", batteryLevel())
            json.put("batteryCharging", batteryCharging())
            Api.post("/miro/location", json, Prefs.token) {}
        }
    }

    // ---- Rapport d'activité (toutes les applications, sans limite) ----

    private fun sendReport() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP_MR1) return
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val endTime = System.currentTimeMillis()
        val startTime = endTime - 3600000
        val stats = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startTime, endTime)
        if (stats != null && stats.isNotEmpty()) {
            val sortedStats = stats.sortedByDescending { it.totalTimeInForeground }
            val appUsageArray = JSONArray()
            var totalScreenTime = 0L
            // Toutes les applications utilisées, pas seulement les 10 premières
            for (stat in sortedStats) {
                if (stat.totalTimeInForeground > 0) {
                    totalScreenTime += stat.totalTimeInForeground
                    val appObj = JSONObject()
                    appObj.put("packageName", stat.packageName)
                    appObj.put("durationMs", stat.totalTimeInForeground)
                    appUsageArray.put(appObj)
                }
            }
            Prefs.deviceId?.let { id ->
                val json = JSONObject()
                json.put("deviceId", id)
                json.put("date", System.currentTimeMillis())
                json.put("totalScreenTimeMs", totalScreenTime)
                json.put("appUsage", appUsageArray)
                json.put("batteryLevel", batteryLevel())
                json.put("batteryCharging", batteryCharging())
                Api.post("/miro/reports", json, Prefs.token) {}
            }
        }
    }

    // ---- Demandes à la demande envoyées depuis NEXORA ----

    private fun pollCommands() {
        val id = Prefs.deviceId ?: return
        Api.get("/miro/commands/$id", Prefs.token) { result ->
            result.onSuccess { body ->
                try {
                    val arr = JSONArray(body)
                    for (i in 0 until arr.length()) {
                        handleCommand(arr.getJSONObject(i))
                    }
                } catch (_: Exception) {}
            }
        }
    }

    private fun handleCommand(cmd: JSONObject) {
        val sessionId = cmd.optString("sessionId", null) ?: return
        when (cmd.optString("type")) {
            "location" -> {
                val last = lastKnownLocation()
                if (last != null) sendLocation(last)
                completeCommand(sessionId, "ended")
            }
            "report" -> {
                sendReport()
                completeCommand(sessionId, "ended")
            }
            "screen_recording", "screen_share", "audio_call", "video_call" -> {
                // Nécessite un consentement d'enregistrement d'écran déjà actif sur l'appareil ;
                // pas de contournement possible, donc on rejette si rien n'est prêt.
                completeCommand(sessionId, "rejected")
            }
        }
    }

    @Suppress("MissingPermission")
    private fun lastKnownLocation(): Location? {
        if (ActivityCompat.checkSelfPermission(this, android.Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) return null
        return locationManager.getLastKnownLocation(LocationManager.GPS_PROVIDER)
            ?: locationManager.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)
    }

    private fun completeCommand(sessionId: String, status: String) {
        val json = JSONObject()
        json.put("sessionId", sessionId)
        json.put("status", status)
        Api.post("/miro/command-result", json, Prefs.token) {}
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel("miro_sync", "Sync Service", NotificationManager.IMPORTANCE_LOW)
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        reportTimer?.cancel()
        commandTimer?.cancel()
        locationManager.removeUpdates(this)
    }

    override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
    override fun onProviderEnabled(provider: String) {}
    override fun onProviderDisabled(provider: String) {}
}
