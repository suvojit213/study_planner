class StudySession {
  final int? id;
  final int subjectId;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final bool isCompleted;

  StudySession({
    this.id,
    required this.subjectId,
    required this.startTime,
    this.endTime,
    required this.durationMinutes,
    required this.isCompleted,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_id': subjectId,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      'duration_minutes': durationMinutes,
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  factory StudySession.fromMap(Map<String, dynamic> map) {
    return StudySession(
      id: map['id'],
      subjectId: map['subject_id'],
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time']),
      endTime: map['end_time'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['end_time'])
          : null,
      durationMinutes: map['duration_minutes'],
      isCompleted: map['is_completed'] == 1,
    );
  }

  StudySession copyWith({
    int? id,
    int? subjectId,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    bool? isCompleted,
  }) {
    return StudySession(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

