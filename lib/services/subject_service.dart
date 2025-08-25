import 'package:flutter/foundation.dart';
import '../models/subject.dart';
import '../database/database_helper.dart';

class SubjectService extends ChangeNotifier {
  static final SubjectService _instance = SubjectService._internal();
  factory SubjectService() => _instance;
  SubjectService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Subject> _subjects = [];
  Subject? _selectedSubject;

  // Getters
  List<Subject> get subjects => _subjects;
  Subject? get selectedSubject => _selectedSubject;

  // Initialize and load subjects
  Future<void> initialize() async {
    await loadSubjects();
  }

  // Load all subjects from database
  Future<void> loadSubjects() async {
    _subjects = await _dbHelper.getAllSubjects();
    notifyListeners();
  }

  // Add new subject
  Future<bool> addSubject({
    required String name,
    String? description,
    required int targetMinutes,
  }) async {
    try {
      // Check if subject with same name already exists
      if (_subjects.any((subject) => subject.name.toLowerCase() == name.toLowerCase())) {
        return false; // Subject already exists
      }

      final subject = Subject(
        name: name,
        description: description,
        targetMinutes: targetMinutes,
        createdAt: DateTime.now(),
      );

      final id = await _dbHelper.insertSubject(subject);
      final newSubject = subject.copyWith(id: id);
      
      _subjects.add(newSubject);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding subject: $e');
      return false;
    }
  }

  // Update existing subject
  Future<bool> updateSubject(Subject subject) async {
    try {
      await _dbHelper.updateSubject(subject);
      
      final index = _subjects.indexWhere((s) => s.id == subject.id);
      if (index != -1) {
        _subjects[index] = subject;
        
        // Update selected subject if it's the same
        if (_selectedSubject?.id == subject.id) {
          _selectedSubject = subject;
        }
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating subject: $e');
      return false;
    }
  }

  // Delete subject
  Future<bool> deleteSubject(int subjectId) async {
    try {
      await _dbHelper.deleteSubject(subjectId);
      
      _subjects.removeWhere((subject) => subject.id == subjectId);
      
      // Clear selected subject if it was deleted
      if (_selectedSubject?.id == subjectId) {
        _selectedSubject = null;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting subject: $e');
      return false;
    }
  }

  // Select subject for study session
  void selectSubject(Subject subject) {
    _selectedSubject = subject;
    notifyListeners();
  }

  // Clear selected subject
  void clearSelection() {
    _selectedSubject = null;
    notifyListeners();
  }

  // Get subject by ID
  Subject? getSubjectById(int id) {
    try {
      return _subjects.firstWhere((subject) => subject.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get total study time for a subject
  Future<int> getSubjectTotalTime(int subjectId) async {
    return await _dbHelper.getTotalStudyTimeForSubject(subjectId);
  }

  // Get subject progress (studied vs target)
  Future<Map<String, dynamic>> getSubjectProgress(Subject subject) async {
    final totalMinutes = await getSubjectTotalTime(subject.id!);
    final progressPercentage = subject.targetMinutes > 0 
        ? (totalMinutes / subject.targetMinutes * 100).clamp(0, 100)
        : 0.0;

    return {
      'totalMinutes': totalMinutes,
      'targetMinutes': subject.targetMinutes,
      'progressPercentage': progressPercentage,
      'remainingMinutes': (subject.targetMinutes - totalMinutes).clamp(0, subject.targetMinutes),
    };
  }

  // Get today's study time for a subject
  Future<int> getSubjectTodayTime(String subjectName) async {
    final todayTime = await _dbHelper.getTodayStudyTime();
    return todayTime[subjectName] ?? 0;
  }

  Future<List<StudySession>> getStudySessionsForSubject(int subjectId) async {
    return await _dbHelper.getStudySessionsForSubject(subjectId);
  }

  Future<double> getAverageSessionDuration(int subjectId) async {
    return await _dbHelper.getAverageSessionDuration(subjectId);
  }

  // Search subjects by name
  List<Subject> searchSubjects(String query) {
    if (query.isEmpty) return _subjects;
    
    return _subjects.where((subject) =>
        subject.name.toLowerCase().contains(query.toLowerCase()) ||
        (subject.description?.toLowerCase().contains(query.toLowerCase()) ?? false)
    ).toList();
  }

  // Sort subjects by different criteria
  void sortSubjects(String criteria) {
    switch (criteria) {
      case 'name':
        _subjects.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'target':
        _subjects.sort((a, b) => b.targetMinutes.compareTo(a.targetMinutes));
        break;
      case 'created':
        _subjects.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    notifyListeners();
  }
}

