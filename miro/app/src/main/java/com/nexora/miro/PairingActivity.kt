package com.nexora.miro

import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.nexora.miro.databinding.ActivityPairingBinding
import org.json.JSONObject
import java.util.UUID

class PairingActivity : AppCompatActivity() {
    private lateinit var b: ActivityPairingBinding
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Prefs.init(this)
        b = ActivityPairingBinding.inflate(layoutInflater)
        setContentView(b.root)
        
        b.btnConfirm.setOnClickListener {
            val code = b.etCode.text.toString().trim()
            if (code.length != 8) { 
                Toast.makeText(this, "Code invalide", Toast.LENGTH_SHORT).show()
                return@setOnClickListener 
            }
            
            val deviceId = UUID.randomUUID().toString()
            
            val jsonBody = JSONObject()
            jsonBody.put("code", code)
            jsonBody.put("deviceId", deviceId)
            jsonBody.put("deviceName", android.os.Build.MODEL)
            jsonBody.put("manufacturer", android.os.Build.MANUFACTURER)
            jsonBody.put("model", android.os.Build.MODEL)
            jsonBody.put("androidVersion", android.os.Build.VERSION.RELEASE)
            // Correction ici pour éviter l'ambiguïté Kotlin/Java :
            jsonBody.put("supportsScreenRecording", java.lang.Boolean.TRUE)

            Api.post("/pairing/confirm", jsonBody) { result ->
                runOnUiThread {
                    result.onSuccess { 
                        Prefs.deviceId = deviceId
                        Prefs.paired = true
                        finish() 
                    }
                    result.onFailure { 
                        Toast.makeText(this, it.message ?: "Erreur", Toast.LENGTH_LONG).show() 
                    }
                }
            }
        }
    }
}