package com.example.study_planner

import android.media.RingtoneManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.study_planner/settings"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getDefaultAlarmSound") {
                val defaultAlarmSoundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                result.success(defaultAlarmSoundUri?.toString())
            } else {
                result.notImplemented()
            }
        }
    }
}
