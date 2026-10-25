package com.nexora.miro
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.io.IOException
import java.util.concurrent.TimeUnit

object Api {
  // Render (offre gratuite) met le serveur en veille : le premier appel peut prendre ~50 s
  private val client = OkHttpClient.Builder()
      .connectTimeout(60, TimeUnit.SECONDS)
      .readTimeout(60, TimeUnit.SECONDS)
      .writeTimeout(60, TimeUnit.SECONDS)
      .build()
  private const val BASE = "https://nexora-miro.onrender.com/api" // URL du serveur (Render)

  fun post(path: String, body: JSONObject, token: String? = null, cb: (Result<JSONObject>) -> Unit) {
    val req = Request.Builder().url("$BASE$path")
        .post(body.toString().toRequestBody("application/json".toMediaType()))
        .apply { if (token != null) addHeader("Authorization", "Bearer $token") }.build()
    client.newCall(req).enqueue(object : Callback {
      override fun onFailure(call: Call, e: IOException) = cb(Result.failure(e))
      override fun onResponse(call: Call, response: Response) {
        val b = response.body?.string() ?: "{}"
        cb(if (response.isSuccessful) Result.success(JSONObject(b)) else Result.failure(Exception(b)))
      }
    })
  }

  fun get(path: String, token: String? = null, cb: (Result<String>) -> Unit) {
    val req = Request.Builder().url("$BASE$path")
        .apply { if (token != null) addHeader("Authorization", "Bearer $token") }.build()
    client.newCall(req).enqueue(object : Callback {
      override fun onFailure(call: Call, e: IOException) = cb(Result.failure(e))
      override fun onResponse(call: Call, response: Response) {
        val b = response.body?.string() ?: "[]"
        cb(if (response.isSuccessful) Result.success(b) else Result.failure(Exception(b)))
      }
    })
  }

  fun postMultipart(path: String, requestBody: RequestBody, token: String? = null, cb: (Boolean) -> Unit) {
    val req = Request.Builder().url("$BASE$path").post(requestBody)
        .apply { if (token != null) addHeader("Authorization", "Bearer $token") }.build()
    client.newCall(req).enqueue(object : Callback {
      override fun onFailure(call: Call, e: IOException) = cb(false)
      override fun onResponse(call: Call, response: Response) = cb(response.isSuccessful)
    })
  }
}
