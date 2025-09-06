import 'package:flutter/material.dart';

class ScheduledSession {
  final int? id;
  final int subjectId;
  final TimeOfDay startTime;
  final int durationMinutes;
  final List<int> repeatDays; // Monday = 1, Sunday = 7

  ScheduledSession({
    this.id,
    required this.subjectId,
    required this.startTime,
    required this.durationMinutes,
    required this.repeatDays,
  });

  // Helper to convert TimeOfDay to a string format 'HH:MM'
  String _timeOfDayToString(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Helper to parse a string 'HH:MM' to TimeOfDay
  static TimeOfDay _stringToTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subjectId': subjectId,
      'startTime': _timeOfDayToString(startTime),
      'durationMinutes': durationMinutes,
      'repeatDays': repeatDays.join(','),
    };
  }

  factory ScheduledSession.fromMap(Map<String, dynamic> map) {
    return ScheduledSession(
      id: map['id'],
      subjectId: map['subjectId'],
      startTime: _stringToTimeOfDay(map['startTime']),
      durationMinutes: map['durationMinutes'],
      repeatDays: (map['repeatDays'] as String).split(',').map((e) => int.parse(e)).toList(),
    );
  }

  ScheduledSession copyWith({
    int? id,
    int? subjectId,
    TimeOfDay? startTime,
    int? durationMinutes,
    List<int>? repeatDays,
  }) {
    return ScheduledSession(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      repeatDays: repeatDays ?? this.repeatDays,
    );
  }
}
