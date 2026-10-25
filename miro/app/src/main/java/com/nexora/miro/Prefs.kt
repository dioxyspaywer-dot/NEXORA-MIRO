package com.nexora.miro
import android.content.Context
import android.content.SharedPreferences
object Prefs {
  private lateinit var sp: SharedPreferences
  fun init(ctx:Context){sp=ctx.getSharedPreferences("miro_prefs",Context.MODE_PRIVATE)}
  var token:String? get()=sp.getString("token",null); set(v)=sp.edit().putString("token",v).apply()
  var deviceId:String? get()=sp.getString("deviceId",null); set(v)=sp.edit().putString("deviceId",v).apply()
  var paired:Boolean get()=sp.getBoolean("paired",false); set(v)=sp.edit().putBoolean("paired",v).apply()
  fun clear()=sp.edit().clear().apply()
}