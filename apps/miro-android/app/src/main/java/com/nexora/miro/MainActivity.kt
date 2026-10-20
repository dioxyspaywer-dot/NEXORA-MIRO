package com.nexora.miro

import android.app.Activity
import android.os.Bundle
import android.view.ViewGroup
import android.widget.*
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import kotlin.concurrent.thread

class MainActivity : Activity() {
    private val prefs by lazy { getSharedPreferences("miro", MODE_PRIVATE) }
    private lateinit var codeInput: EditText
    private lateinit var nameInput: EditText
    private lateinit var status: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val root = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setPadding(28, 32, 28, 24) }
        root.addView(TextView(this).apply { text = "MIRO"; textSize = 28f })
        root.addView(TextView(this).apply { text = "Compagnon Android · Association avec NEXORA"; textSize = 14f })
        nameInput = EditText(this).apply { hint = "Nom de cet appareil"; setText(prefs.getString("device_name", "Téléphone compagnon")) }
        root.addView(nameInput)
        codeInput = EditText(this).apply { hint = "Code à 6 chiffres fourni par le parent"; setSingleLine(true) }
        root.addView(codeInput)
        root.addView(Button(this).apply {
            text = "Associer à NEXORA"
            setOnClickListener { pairDevice() }
        })
        status = TextView(this).apply { text = if (prefs.getString("device_token", null) != null) "Appareil associé. Appuie sur Vérifier la connexion." else "Non associé."; setPadding(0, 16, 0, 16) }
        root.addView(status)
        root.addView(Button(this).apply { text = "Vérifier la connexion"; setOnClickListener { heartbeat() } })
        setContentView(ScrollView(this).apply { addView(root, ViewGroup.LayoutParams(-1, -1)) })
    }

    private fun request(method: String, path: String, body: JSONObject? = null, token: String? = null, callback: (Int, String) -> Unit) {
        thread {
            var code = 0; var text = "Connexion impossible"
            try {
                val conn = URL(BuildConfig.API_BASE_URL + path).openConnection() as HttpURLConnection
                conn.requestMethod = method; conn.connectTimeout = 8000; conn.readTimeout = 8000
                conn.setRequestProperty("Content-Type", "application/json")
                if (token != null) conn.setRequestProperty("x-device-token", token)
                if (body != null) { conn.doOutput = true; conn.outputStream.use { it.write(body.toString().toByteArray()) } }
                code = conn.responseCode
                text = (if (code < 400) conn.inputStream else conn.errorStream)?.bufferedReader()?.use { it.readText() } ?: ""
                conn.disconnect()
            } catch (e: Exception) { text = e.message ?: "Erreur réseau" }
            runOnUiThread { callback(code, text) }
        }
    }

    private fun pairDevice() {
        val payload = JSONObject().put("code", codeInput.text.toString().trim())
            .put("deviceName", nameInput.text.toString().trim()).put("platform", "Android")
        request("POST", "/api/pair", payload) { code, response ->
            if (code in 200..299) {
                val obj = JSONObject(response)
                prefs.edit().putString("device_id", obj.optString("deviceId"))
                    .putString("device_token", obj.optString("deviceToken"))
                    .putString("device_name", nameInput.text.toString().trim()).apply()
                codeInput.setText("")
                status.text = "Association réussie. Appuie sur Vérifier la connexion."
            } else status.text = "Association impossible ($code) : $response"
        }
    }

    private fun heartbeat() {
        val token = prefs.getString("device_token", null)
        if (token == null) { status.text = "Cet appareil n'est pas encore associé."; return }
        request("POST", "/api/device/heartbeat", JSONObject(), token) { code, response ->
            status.text = if (code in 200..299) "Connexion réussie · ${JSONObject(response).optString("serverTime")}" else "Connexion échouée ($code) : $response"
        }
    }
}
