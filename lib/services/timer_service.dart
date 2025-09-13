import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../models/subject.dart';
import '../models/study_session.dart';
import '../database/database_helper.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_planner/services/subject_service.dart';

enum TimerState { stopped, running, paused }

class TimerService extends ChangeNotifier {
  static final TimerService _instance = TimerService._internal();
  factory TimerService() => _instance;
  TimerService._internal() {
    _initialize();
  }

  TimerState _state = TimerState.stopped;
  int _elapsedSeconds = 0;
  int _lastCompletedSessionDuration = 0;
  Subject? _currentSubject;
  StudySession? _currentSession;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ValueNotifier<bool> isTargetCompleted = ValueNotifier(false);

  // Getters
  TimerState get state => _state;
  int get elapsedSeconds => _elapsedSeconds;
  int get lastCompletedSessionDuration => _lastCompletedSessionDuration;
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

  void _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final status = prefs.getString('timer_status');
    if (status != null) {
      final subjectName = prefs.getString('timer_subject');
      final elapsed = prefs.getInt('timer_elapsed');
      if (subjectName != null && elapsed != null) {
        final subject = await SubjectService().getSubjectByName(subjectName);
        if (subject != null) {
          _currentSubject = subject;
          _elapsedSeconds = elapsed;
          if (status == 'running') {
            _state = TimerState.running;
          } else if (status == 'paused') {
            _state = TimerState.paused;
          }
          notifyListeners();
        }
      }
    }

    FlutterBackgroundService().on('update').listen((event) {
      if (event != null) {
        _elapsedSeconds = event['elapsedSeconds'];
        notifyListeners();
      }
    });

    FlutterBackgroundService().on('completed').listen((event) {
      if (event != null) {
        _lastCompletedSessionDuration = event['duration'];
        _currentSubject = Subject.fromMap(event['subject']);
        isTargetCompleted.value = true;
        _state = TimerState.stopped;
        _currentSession = null;
        _elapsedSeconds = 0;
        notifyListeners();
      }
    });
  }

  Future<bool> startStudy(Subject subject) async {
    if (_state != TimerState.stopped) {
      return false;
    }

    isTargetCompleted.value = false;
    _currentSubject = subject;
    _elapsedSeconds = 0;
    _state = TimerState.running;

    final service = FlutterBackgroundService();
    bool isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
    }
    service.invoke('start', {'subject': subject.toMap()});
    notifyListeners();
    return true;
  }

  void pauseStudy() {
    if (_state != TimerState.running) return;

    _state = TimerState.paused;
    FlutterBackgroundService().invoke('pause');
    notifyListeners();
  }

  void resumeStudy() {
    if (_state != TimerState.paused) return;

    _state = TimerState.running;
    FlutterBackgroundService().invoke('resume');
    notifyListeners();
  }

  Future<void> endStudy({bool isCompleted = false}) async {
    if (_state == TimerState.stopped) return;

    _state = TimerState.stopped;
    FlutterBackgroundService().invoke('stop');

    _currentSubject = null;
    _currentSession = null;
    _elapsedSeconds = 0;
    notifyListeners();
  }

  Future<int> getTodayTotalMinutes() async {
    final todayTime = await _dbHelper.getTodayStudyTime();
    return todayTime.values.fold<int>(0, (int sum, int minutes) => sum + minutes);
  }

  Future<Map<String, int>> getTodayProgress() async {
    return await _dbHelper.getTodayStudyTime();
  }

  void resetCompletionStatus() {
    isTargetCompleted.value = false;
  }
}

