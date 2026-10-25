package com.nexora.miro

import android.Manifest
import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.nexora.miro.databinding.ActivityMainBinding
import com.nexora.miro.services.SyncWorker

class MainActivity : AppCompatActivity() {
    private lateinit var b: ActivityMainBinding
    private val PERMISSION_CODE = 101

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Prefs.init(this)
        if (!Prefs.paired) {
            startActivity(Intent(this, PairingActivity::class.java)); finish(); return
        }

        b = ActivityMainBinding.inflate(layoutInflater)
        setContentView(b.root)
        b.tvStatus.text = "Connecté — Appareil: ${Prefs.deviceId}"

        checkAndRequestPermissions()

        b.btnUnpair.setOnClickListener {
            Prefs.clear(); startActivity(Intent(this, PairingActivity::class.java)); finish()
        }
    }

    private fun checkAndRequestPermissions() {
        // Accès aux statistiques d'usage : permission spéciale, accordée manuellement
        // par l'utilisateur dans l'écran système dédié (aucun contournement possible).
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
            val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            val mode = appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), packageName)
            if (mode != AppOpsManager.MODE_ALLOWED) startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
        }

        val permissions = mutableListOf(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION,
            Manifest.permission.RECORD_AUDIO,
            Manifest.permission.CAMERA
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            permissions.add(Manifest.permission.POST_NOTIFICATIONS)
        }

        val needed = permissions.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }
        if (needed.isNotEmpty()) {
            ActivityCompat.requestPermissions(this, needed.toTypedArray(), PERMISSION_CODE)
        } else {
            startBackgroundServices()
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_CODE) startBackgroundServices()
    }

    private fun startBackgroundServices() {
        val syncIntent = Intent(this, SyncWorker::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) startForegroundService(syncIntent) else startService(syncIntent)
    }
}
