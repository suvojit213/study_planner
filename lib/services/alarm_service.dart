
import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:study_planner/main.dart';
import 'package:study_planner/services/settings_service.dart';

class AlarmService {
  static const int alarmId = 0;

  static Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
  }

  static Future<void> scheduleAlarm(DateTime scheduledTime, String subjectName) async {
    await AndroidAlarmManager.oneShotAt(
      scheduledTime,
      alarmId,
      callback,
      exact: true,
      wakeup: true,
      alarmClock: true,
      params: {'subject': subjectName},
    );
  }

  @pragma('vm:entry-point')
  static void callback(int id, Map<String, dynamic> params) async {
    final subjectName = params['subject'];
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    // Initialize notifications
    await initializeNotifications(flutterLocalNotificationsPlugin);

    final settingsService = SettingsService();
    final customAlarmSound = await settingsService.getAlarmSound();
    final defaultAlarmSound = await settingsService.getDefaultAlarmSound();
    final alarmSound = customAlarmSound ?? defaultAlarmSound;

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'study_target_completion_channel',
      'Study Target Completion',
      channelDescription: 'Notifies when a study target is completed',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      sound: RawResourceAndroidNotificationSound(alarmSound?.split('.').first),
    );
    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Target Completed!',
      'Congratulations! You have completed your study target for $subjectName.',
      platformChannelSpecifics,
      payload: 'alarm_completion_$subjectName',
    );

    FlutterRingtonePlayer().playAlarm(looping: true, volume: 1.0);
  }
}
