class Exam {
  final int? id;
  final int subjectId;
  final String name;
  final DateTime date;

  Exam({
    this.id,
    required this.subjectId,
    required this.name,
    required this.date,
  });

  Exam copyWith({
    int? id,
    int? subjectId,
    String? name,
    DateTime? date,
  }) {
    return Exam(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      name: name ?? this.name,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subjectId': subjectId,
      'name': name,
      'date': date.toIso8601String(),
    };
  }

  factory Exam.fromMap(Map<String, dynamic> map) {
    return Exam(
      id: map['id'],
      subjectId: map['subjectId'],
      name: map['name'],
      date: DateTime.parse(map['date']),
    );
  }
}
