
import 'package:flutter/services.dart';

class AlarmService {
  static const MethodChannel _channel = MethodChannel('com.example.study_planner/alarm');

  static Future<void> scheduleAlarm(DateTime scheduledTime, String subjectName) async {
    try {
      await _channel.invokeMethod('scheduleAlarm', {
        'timeInMillis': scheduledTime.millisecondsSinceEpoch,
        'subject': subjectName,
      });
    } on PlatformException catch (e) {
      print("Failed to schedule alarm: '${e.message}'.");
    }
  }
}
