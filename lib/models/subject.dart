class Subject {
  final int? id;
  final String name;
  final String? description;
  final int targetMinutes;
  final DateTime createdAt;

  Subject({
    this.id,
    required this.name,
    this.description,
    required this.targetMinutes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'target_minutes': targetMinutes,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      targetMinutes: map['target_minutes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }

  Subject copyWith({
    int? id,
    String? name,
    String? description,
    int? targetMinutes,
    DateTime? createdAt,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

