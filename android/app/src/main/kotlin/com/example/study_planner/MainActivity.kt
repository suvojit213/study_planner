package com.example.study_planner

import android.media.RingtoneManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val SETTINGS_CHANNEL = "com.example.study_planner/settings"
    private val ALARM_CHANNEL = "com.example.study_planner/alarm"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SETTINGS_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getDefaultAlarmSound") {
                val defaultAlarmSoundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                result.success(defaultAlarmSoundUri?.toString())
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ALARM_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "scheduleAlarm") {
                val timeInMillis = call.argument<Long>("timeInMillis")
                val subject = call.argument<String>("subject")
                if (timeInMillis != null && subject != null) {
                    val scheduler = AlarmScheduler(this)
                    scheduler.schedule(timeInMillis, subject)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENTS", "Invalid arguments", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
