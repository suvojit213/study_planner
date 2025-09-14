
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_planner/models/subject.dart';
import 'package:study_planner/services/settings_service.dart';
import 'package:study_planner/database/database_helper.dart';
import 'package:study_planner/models/study_session.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: false,
    ),
    iosConfiguration: IosConfiguration(
      onForeground: onStart,
      onBackground: onBackground,
      autoStart: false,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Timer? _timer;
  int _elapsedSeconds = 0;
  Subject? _currentSubject;
  StudySession? _currentSession;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SettingsService _settingsService = SettingsService();
  SharedPreferences? _prefs;

  Future<void> _saveState(String status) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString('timer_status', status);
    if (_currentSubject != null) {
      await _prefs!.setString('timer_subject', _currentSubject!.name);
    }
    await _prefs!.setInt('timer_elapsed', _elapsedSeconds);
  }

  Future<void> _clearState() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove('timer_status');
    await _prefs!.remove('timer_subject');
    await _prefs!.remove('timer_elapsed');
  }

  void _updateNotification(String text) {
    flutterLocalNotificationsPlugin.show(
      1,
      'Study Timer',
      text,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'study_timer_channel',
          'Study Timer',
          channelDescription: 'Notification for the study timer',
          importance: Importance.default,
          priority: Priority.default,
          ongoing: true,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  void _handleTimer(Timer timer, ServiceInstance service, FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
    _elapsedSeconds++;
    service.invoke('update', {'elapsedSeconds': _elapsedSeconds});
    await _saveState('running');

    final hours = _elapsedSeconds ~/ 3600;
    final minutes = (_elapsedSeconds % 3600) ~/ 60;
    final seconds = _elapsedSeconds % 60;
    _updateNotification(
        'Studying ${_currentSubject?.name}: ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}');

    if (_currentSubject != null &&
        _currentSubject!.dailyTarget != null &&
        _currentSubject!.dailyTarget!.inSeconds > 0 &&
        _elapsedSeconds >= _currentSubject!.dailyTarget!.inSeconds) {
      
      final updatedSession = _currentSession!.copyWith(
        endTime: DateTime.now(),
        durationMinutes: _elapsedSeconds ~/ 60,
        isCompleted: true,
      );
      await _dbHelper.updateStudySession(updatedSession);
      
      _showCompletionNotification(flutterLocalNotificationsPlugin, _currentSubject!.name, _settingsService);

      service.invoke('completed', {'subject': _currentSubject!.toMap(), 'duration': _elapsedSeconds});
      
      _timer?.cancel();
      _currentSubject = null;
      _currentSession = null;
      _elapsedSeconds = 0;
      await _clearState();
      flutterLocalNotificationsPlugin.cancel(1);
    }

    if (_elapsedSeconds % 60 == 0 && _currentSession != null) {
      final updatedSession = _currentSession!.copyWith(
        durationMinutes: _elapsedSeconds ~/ 60,
      );
      await _dbHelper.updateStudySession(updatedSession);
    }
  }

  void _startTimer(ServiceInstance service, FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _handleTimer(timer, service, flutterLocalNotificationsPlugin));
  }

  service.on('start').listen((event) async {
    _currentSubject = Subject.fromMap(event!['subject']);
    _elapsedSeconds = 0;

    _currentSession = StudySession(
      subjectId: _currentSubject!.id!,
      startTime: DateTime.now(),
      durationMinutes: 0,
      isCompleted: false,
    );

    final sessionId = await _dbHelper.insertStudySession(_currentSession!);
    _currentSession = _currentSession!.copyWith(id: sessionId);

    _updateNotification('Starting timer for ${_currentSubject?.name}');
    _startTimer(service, flutterLocalNotificationsPlugin);
  });

  service.on('pause').listen((event) async {
    _timer?.cancel();
    await _saveState('paused');
    _updateNotification('Timer paused for ${_currentSubject?.name}');
  });



  service.on('resume').listen((event) {
    _startTimer(service, flutterLocalNotificationsPlugin);
  });

  service.on('stop').listen((event) async {
    _timer?.cancel();
    if (_currentSession != null) {
      final updatedSession = _currentSession!.copyWith(
        endTime: DateTime.now(),
        durationMinutes: _elapsedSeconds ~/ 60,
        isCompleted: false,
      );
      await _dbHelper.updateStudySession(updatedSession);
    }
    _currentSubject = null;
    _currentSession = null;
    _elapsedSeconds = 0;
    await _clearState();
    flutterLocalNotificationsPlugin.cancel(1);
  });
}

Future<void> _showCompletionNotification(FlutterLocalNotificationsPlugin plugin, String subjectName, SettingsService settingsService) async {
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
      sound: alarmSound != null ? UriAndroidNotificationSound(alarmSound) : null,
    );
    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await plugin.show(
      0,
      'Target Completed!',
      'Congratulations! You have completed your study target for \$subjectName.',
      platformChannelSpecifics,
    );
}
