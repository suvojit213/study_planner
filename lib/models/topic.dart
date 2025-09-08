
class Topic {
  final int? id;
  final int subjectId;
  final String name;
  bool isCompleted;
  DateTime? startDate;
  DateTime? endDate;

  Topic({
    this.id,
    required this.subjectId,
    required this.name,
    this.isCompleted = false,
    this.startDate,
    this.endDate,
  });

  Topic copyWith({
    int? id,
    int? subjectId,
    String? name,
    bool? isCompleted,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return Topic(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      name: name ?? this.name,
      isCompleted: isCompleted ?? this.isCompleted,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subjectId': subjectId,
      'name': name,
      'isCompleted': isCompleted ? 1 : 0,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    };
  }

  factory Topic.fromMap(Map<String, dynamic> map) {
    return Topic(
      id: map['id'],
      subjectId: map['subjectId'],
      name: map['name'],
      isCompleted: map['isCompleted'] == 1,
      startDate: map['startDate'] != null ? DateTime.parse(map['startDate']) : null,
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
    );
  }
}
