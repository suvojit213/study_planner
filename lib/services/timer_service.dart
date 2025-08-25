import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/subject.dart';
import '../models/study_session.dart';
import '../database/database_helper.dart';

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
  Future<void> endStudy() async {
    if (_state == TimerState.stopped) return;

    _timer?.cancel();
    _state = TimerState.stopped;

    if (_currentSession != null) {
      // Update session in database
      final updatedSession = _currentSession!.copyWith(
        endTime: DateTime.now(),
        durationMinutes: _elapsedSeconds ~/ 60,
        isCompleted: true,
      );

      await _dbHelper.updateStudySession(updatedSession);
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

