package com.nexora.miro.services

import android.annotation.SuppressLint
import android.app.*
import android.content.Context
import android.content.Intent
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Bundle
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import com.nexora.miro.Api
import com.nexora.miro.Prefs
import org.json.JSONObject

class LocationService : Service(), LocationListener {
    private lateinit var locationManager: LocationManager

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        val notification = NotificationCompat.Builder(this, "location_channel")
            .setContentTitle("MIRO GPS Actif")
            .setContentText("Suivi en temps réel (10s)")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .build()
        startForeground(1, notification)
        
        locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        startLocationUpdates()
    }

    @SuppressLint("MissingPermission")
    private fun startLocationUpdates() {
        locationManager.requestLocationUpdates(LocationManager.GPS_PROVIDER, 10000, 0f, this, Looper.getMainLooper())
        locationManager.requestLocationUpdates(LocationManager.NETWORK_PROVIDER, 10000, 0f, this, Looper.getMainLooper())
    }

    override fun onLocationChanged(location: Location) {
        Prefs.deviceId?.let { id ->
            val json = JSONObject()
            json.put("deviceId", id)
            json.put("latitude", location.latitude)
            json.put("longitude", location.longitude)
            json.put("accuracy", location.accuracy)
            json.put("recordedAt", System.currentTimeMillis())
            Api.post("/api/miro/location", json, Prefs.token) {}
        }
    }

    private fun createNotificationChannel() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            val channel = NotificationChannel("location_channel", "GPS Service", NotificationManager.IMPORTANCE_LOW)
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
    
    override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
    override fun onProviderEnabled(provider: String) {}
    override fun onProviderDisabled(provider: String) {}
}