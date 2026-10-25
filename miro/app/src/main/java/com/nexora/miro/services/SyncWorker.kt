package com.nexora.miro.services

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
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
    private var timer: Timer? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        val notification = NotificationCompat.Builder(this, "miro_sync")
            .setContentTitle("MIRO Surveillance")
            .setContentText("Collecte des données en cours")
            .setSmallIcon(android.R.drawable.ic_menu_info_details)
            .build()
        startForeground(2, notification)

        locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        if (ActivityCompat.checkSelfPermission(this, android.Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
            locationManager.requestLocationUpdates(LocationManager.GPS_PROVIDER, 60000, 50f, this, Looper.getMainLooper())
            locationManager.requestLocationUpdates(LocationManager.NETWORK_PROVIDER, 60000, 50f, this, Looper.getMainLooper())
        }

        timer = Timer()
        timer?.scheduleAtFixedRate(object : TimerTask() {
            override fun run() { sendReport() }
        }, 0, 60000)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int = START_STICKY

    override fun onLocationChanged(location: Location) {
        Prefs.deviceId?.let { id ->
            val json = JSONObject()
            json.put("deviceId", id)
            json.put("latitude", location.latitude)
            json.put("longitude", location.longitude)
            json.put("accuracy", location.accuracy)
            json.put("recordedAt", System.currentTimeMillis())
            Api.post("/miro/location", json, Prefs.token) {}
        }
    }

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
            for (stat in sortedStats.take(10)) {
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
                Api.post("/miro/reports", json, Prefs.token) {}
            }
        }
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
        timer?.cancel()
        locationManager.removeUpdates(this)
    }

    override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
    override fun onProviderEnabled(provider: String) {}
    override fun onProviderDisabled(provider: String) {}
}
