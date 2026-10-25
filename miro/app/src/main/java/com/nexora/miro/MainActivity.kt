package com.nexora.miro
import android.content.Intent
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import com.nexora.miro.databinding.ActivityMainBinding
class MainActivity:AppCompatActivity(){
  private lateinit var b:ActivityMainBinding
  override fun onCreate(savedInstanceState:Bundle?){
    super.onCreate(savedInstanceState);Prefs.init(this)
    if(!Prefs.paired){startActivity(Intent(this,PairingActivity::class.java));finish();return}
    b=ActivityMainBinding.inflate(layoutInflater);setContentView(b.root)
    b.tvStatus.text="Connecté — Appareil: ${Prefs.deviceId}"
    b.btnUnpair.setOnClickListener{Prefs.clear();startActivity(Intent(this,PairingActivity::class.java));finish()}
  }
}