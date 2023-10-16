package com.zegocloud.uikit.flutter.live_streaming

import android.annotation.SuppressLint
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    @SuppressLint("LongLogTag")
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        try {
            flutterEngine.plugins.add(SudMGPPlugin())
        } catch (e: Exception) {
            Log.e(
                "GeneratedPluginRegistrant",
                "Error registering plugin SudMGPPlugin, com.zegocloud.minigame.demo.SudMGPPlugin",
                e
            )
        }
    }
}
