
class Topic {
  final int? id;
  final int subjectId;
  final String name;
  bool isCompleted;

  Topic({
    this.id,
    required this.subjectId,
    required this.name,
    this.isCompleted = false,
  });

  Topic copyWith({
    int? id,
    int? subjectId,
    String? name,
    bool? isCompleted,
  }) {
    return Topic(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      name: name ?? this.name,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subjectId': subjectId,
      'name': name,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory Topic.fromMap(Map<String, dynamic> map) {
    return Topic(
      id: map['id'],
      subjectId: map['subjectId'],
      name: map['name'],
      isCompleted: map['isCompleted'] == 1,
    );
  }
}
