package com.nexora.parent

import android.app.Activity
import android.os.Bundle
import android.graphics.Typeface
import android.view.Gravity
import android.view.ViewGroup
import android.widget.*
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import kotlin.concurrent.thread

class MainActivity : Activity() {
    private val prefs by lazy { getSharedPreferences("nexora", MODE_PRIVATE) }
    private lateinit var status: TextView
    private lateinit var list: LinearLayout
    private lateinit var keyInput: EditText

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(28, 32, 28, 24)
        }
        root.addView(TextView(this).apply {
            text = "NEXORA"; textSize = 28f; setTypeface(null, Typeface.BOLD)
        })
        root.addView(TextView(this).apply {
            text = "Application parent · V1 association et état des appareils"; textSize = 14f
        })
        keyInput = EditText(this).apply {
            hint = "Clé parent configurée sur le serveur"
            setSingleLine(true)
            setText(prefs.getString("parent_key", ""))
        }
        root.addView(keyInput)
        root.addView(Button(this).apply {
            text = "Enregistrer la clé parent"
            setOnClickListener { prefs.edit().putString("parent_key", keyInput.text.toString()).apply(); refreshDevices() }
        })
        root.addView(Button(this).apply {
            text = "Créer un code d’association"
            setOnClickListener { createPairingCode() }
        })
        status = TextView(this).apply { text = "Prêt."; textSize = 15f; setPadding(0, 16, 0, 16) }
        root.addView(status)
        root.addView(Button(this).apply { text = "Actualiser les appareils"; setOnClickListener { refreshDevices() } })
        list = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        val scroll = ScrollView(this).apply { addView(list) }
        root.addView(scroll, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f))
        setContentView(root)
    }

    private fun request(method: String, path: String, body: JSONObject? = null, parent: Boolean = true, callback: (Int, String) -> Unit) {
        thread {
            var code = 0
            var text = "Connexion impossible"
            try {
                val conn = (URL(BuildConfig.API_BASE_URL + path).openConnection() as HttpURLConnection)
                conn.requestMethod = method
                conn.connectTimeout = 8000; conn.readTimeout = 8000
                if (parent) conn.setRequestProperty("x-parent-key", prefs.getString("parent_key", "") ?: "")
                conn.setRequestProperty("Content-Type", "application/json")
                if (body != null) { conn.doOutput = true; conn.outputStream.use { it.write(body.toString().toByteArray()) } }
                code = conn.responseCode
                text = (if (code < 400) conn.inputStream else conn.errorStream)?.bufferedReader()?.use { it.readText() } ?: ""
                conn.disconnect()
            } catch (e: Exception) { text = e.message ?: "Erreur réseau" }
            runOnUiThread { callback(code, text) }
        }
    }

    private fun createPairingCode() {
        request("POST", "/api/pairing-codes", JSONObject(), true) { code, response ->
            if (code in 200..299) {
                val obj = JSONObject(response)
                status.text = "Code temporaire : ${obj.optString("code")}\nExpire : ${obj.optString("expiresAt")}\nCommunique-le uniquement à l'appareil que tu veux associer."
            } else status.text = "Erreur ($code) : $response"
        }
    }

    private fun refreshDevices() {
        request("GET", "/api/devices", null, true) { code, response ->
            list.removeAllViews()
            if (code !in 200..299) { status.text = "Impossible de charger les appareils ($code) : $response"; return@request }
            val arr = JSONArray(response)
            if (arr.length() == 0) list.addView(TextView(this).apply { text = "Aucun appareil associé."; setPadding(0, 12, 0, 12) })
            for (i in 0 until arr.length()) {
                val d = arr.getJSONObject(i)
                val item = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setPadding(0, 12, 0, 12) }
                item.addView(TextView(this).apply {
                    text = "${d.optString("deviceName")} · ${d.optString("status")}\nDernière communication : ${d.optString("lastSeenAt")}"
                    textSize = 16f
                })
                item.addView(Button(this).apply {
                    text = "Révoquer cet appareil"
                    setOnClickListener {
                        request("POST", "/api/devices/${d.optString("deviceId")}/revoke", JSONObject(), true) { c, r ->
                            status.text = if (c in 200..299) "Association révoquée." else "Erreur ($c) : $r"
                            refreshDevices()
                        }
                    }
                })
                list.addView(item)
                list.addView(View(this).apply { setBackgroundColor(0xFFE0E0E0.toInt()) }, LinearLayout.LayoutParams(-1, 1))
            }
        }
    }
}
