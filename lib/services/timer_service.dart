import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/subject.dart';
import '../models/study_session.dart';
import '../database/database_helper.dart';
import '../main.dart';
import 'settings_service.dart';

enum TimerState { stopped, running, paused }

class TimerService extends ChangeNotifier {
  static final TimerService _instance = TimerService._internal();
  factory TimerService() => _instance;
  TimerService._internal();

  Timer? _timer;
  TimerState _state = TimerState.stopped;
  int _elapsedSeconds = 0;
  Subject? _currentSubject;
  StudySession? _currentSession;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SettingsService _settingsService = SettingsService();
  final ValueNotifier<bool> isTargetCompleted = ValueNotifier(false);

  // Getters
  TimerState get state => _state;
  int get elapsedSeconds => _elapsedSeconds;
  Subject? get currentSubject => _currentSubject;
  StudySession? get currentSession => _currentSession;

  String get formattedTime {
    int hours = _elapsedSeconds ~/ 3600;
    int minutes = (_elapsedSeconds % 3600) ~/ 60;
    int seconds = _elapsedSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  // Start study session
  Future<bool> startStudy(Subject subject) async {
    if (_state != TimerState.stopped) {
      return false;
    }

    isTargetCompleted.value = false;
    _currentSubject = subject;
    _elapsedSeconds = 0;
    _state = TimerState.running;

    // Create new study session
    _currentSession = StudySession(
      subjectId: subject.id!,
      startTime: DateTime.now(),
      durationMinutes: 0,
      isCompleted: false,
    );

    // Save to database
    final sessionId = await _dbHelper.insertStudySession(_currentSession!);
    _currentSession = _currentSession!.copyWith(id: sessionId);

    _startTimer();
    notifyListeners();
    return true;
  }

  // Pause study session
  void pauseStudy() {
    if (_state != TimerState.running) return;

    _state = TimerState.paused;
    _timer?.cancel();
    notifyListeners();
  }

  // Resume study session
  void resumeStudy() {
    if (_state != TimerState.paused) return;

    _state = TimerState.running;
    _startTimer();
    notifyListeners();
  }

  // End study session
  Future<void> endStudy({bool isCompleted = false}) async {
    if (_state == TimerState.stopped) return;

    _timer?.cancel();
    _state = TimerState.stopped;

    if (_currentSession != null) {
      // Update session in database
      final updatedSession = _currentSession!.copyWith(
        endTime: DateTime.now(),
        durationMinutes: _elapsedSeconds ~/ 60,
        isCompleted: isCompleted,
      );

      await _dbHelper.updateStudySession(updatedSession);
    }

    if (isCompleted && _currentSubject != null) {
      isTargetCompleted.value = true;
      _showCompletionNotification(_currentSubject!.name);
    }

    _currentSubject = null;
    _currentSession = null;
    _elapsedSeconds = 0;
    notifyListeners();
  }

  // Private method to start the timer
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      notifyListeners();

      if (_currentSubject != null &&
          _currentSubject!.dailyTarget != null &&
          _currentSubject!.dailyTarget!.inSeconds > 0 &&
          _elapsedSeconds >= _currentSubject!.dailyTarget!.inSeconds) {
        endStudy(isCompleted: true);
      }

      // Auto-save session every minute
      if (_elapsedSeconds % 60 == 0 && _currentSession != null) {
        _autoSaveSession();
      }
    });
  }

  // Auto-save session progress
  Future<void> _autoSaveSession() async {
    if (_currentSession == null) return;

    final updatedSession = _currentSession!.copyWith(
      durationMinutes: _elapsedSeconds ~/ 60,
    );

    await _dbHelper.updateStudySession(updatedSession);
  }

  Future<void> _showCompletionNotification(String subjectName) async {
    final customAlarmSound = await _settingsService.getAlarmSound();
    final defaultAlarmSound = await _settingsService.getDefaultAlarmSound();
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
    await flutterLocalNotificationsPlugin.show(
      0,
      'Target Completed!',
      'Congratulations! You have completed your study target for $subjectName.',
      platformChannelSpecifics,
    );
  }

  // Get today's total study time
  Future<int> getTodayTotalMinutes() async {
    final todayTime = await _dbHelper.getTodayStudyTime();
    return todayTime.values.fold<int>(0, (int sum, int minutes) => sum + minutes);
  }

  // Get subject progress for today
  Future<Map<String, int>> getTodayProgress() async {
    return await _dbHelper.getTodayStudyTime();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

