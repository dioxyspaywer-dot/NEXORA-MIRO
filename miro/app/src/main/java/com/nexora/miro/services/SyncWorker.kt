package com.nexora.miro.services
import android.app.Service
import android.content.Intent
import android.os.IBinder
import com.nexora.miro.Api
import com.nexora.miro.Prefs
import org.json.JSONObject
class SyncWorker:Service(){
  override fun onBind(intent:Intent?):IBinder?=null
  override fun onStartCommand(intent:Intent?,flags:Int,startId:Int):Int{
    Prefs.deviceId?.let{id->Api.post("/miro/heartbeat",JSONObject().put("deviceId",id).put("status","online"),Prefs.token){}}
    stopSelf();return START_NOT_STICKY
  }
}