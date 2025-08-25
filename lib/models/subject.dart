class Subject {
  final int? id;
  final String name;
  final String? description;
  final int targetMinutes;
  final int? dailyTargetMinutes;
  final int? monthlyTargetMinutes;
  final DateTime createdAt;

  Subject({
    this.id,
    required this.name,
    this.description,
    required this.targetMinutes,
    this.dailyTargetMinutes,
    this.monthlyTargetMinutes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'target_minutes': targetMinutes,
      'daily_target_minutes': dailyTargetMinutes,
      'monthly_target_minutes': monthlyTargetMinutes,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      targetMinutes: map['target_minutes'],
      dailyTargetMinutes: map['daily_target_minutes'],
      monthlyTargetMinutes: map['monthly_target_minutes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }

  Subject copyWith({
    int? id,
    String? name,
    String? description,
    int? targetMinutes,
    int? dailyTargetMinutes,
    int? monthlyTargetMinutes,
    DateTime? createdAt,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      dailyTargetMinutes: dailyTargetMinutes ?? this.dailyTargetMinutes,
      monthlyTargetMinutes: monthlyTargetMinutes ?? this.monthlyTargetMinutes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

