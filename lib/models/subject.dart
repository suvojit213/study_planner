class Subject {
  final int? id;
  final String name;
  final String? description;
  final Duration? dailyTarget;
  final DateTime createdAt;

  Subject({
    this.id,
    required this.name,
    this.description,
    this.dailyTarget,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'daily_target_minutes': dailyTarget?.inMinutes,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      dailyTarget: map['daily_target_minutes'] != null
          ? Duration(minutes: map['daily_target_minutes'])
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }

  Subject copyWith({
    int? id,
    String? name,
    String? description,
    Duration? dailyTarget,
    DateTime? createdAt,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      dailyTarget: dailyTarget ?? this.dailyTarget,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

