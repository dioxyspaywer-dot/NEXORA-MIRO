package com.nexora.miro
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.io.IOException
object Api {
  private val client=OkHttpClient()
  private const val BASE="https://your-server.vercel.app/api" // ← Remplacer par ton URL serveur
  fun post(path:String,body:JSONObject,token:String?=null,cb:(Result<JSONObject>)->Unit){
    val req=Request.Builder().url("$BASE$path").post(body.toString().toRequestBody("application/json".toMediaType())).apply{if(token!=null)addHeader("Authorization","Bearer $token")}.build()
    client.newCall(req).enqueue(object:Callback{
      override fun onFailure(call:Call,e:IOException)=cb(Result.failure(e))
      override fun onResponse(call:Call,response:Response){val b=response.body?.string()?:"{}";cb(if(response.isSuccessful)Result.success(JSONObject(b))else Result.failure(Exception(b)))}
    })
  }
}