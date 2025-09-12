import 'package:flutter/material.dart';

class Subject {
  final int? id;
  final String name;
  final String? description;
  final Duration? dailyTarget;
  final Duration? weeklyTarget;
  final Duration? monthlyTarget;
  final DateTime createdAt;
  final Color color;

  Subject({
    this.id,
    required this.name,
    this.description,
    this.dailyTarget,
    this.weeklyTarget,
    this.monthlyTarget,
    required this.createdAt,
    this.color = Colors.blue,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'daily_target_minutes': dailyTarget?.inMinutes,
      'weekly_target_minutes': weeklyTarget?.inMinutes,
      'monthly_target_minutes': monthlyTarget?.inMinutes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'color': color.value,
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
      weeklyTarget: map['weekly_target_minutes'] != null
          ? Duration(minutes: map['weekly_target_minutes'])
          : null,
      monthlyTarget: map['monthly_target_minutes'] != null
          ? Duration(minutes: map['monthly_target_minutes'])
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      color: Color(map['color'] ?? Colors.blue.value),
    );
  }

  Subject copyWith({
    int? id,
    String? name,
    String? description,
    Duration? dailyTarget,
    Duration? weeklyTarget,
    Duration? monthlyTarget,
    DateTime? createdAt,
    Color? color,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      dailyTarget: dailyTarget ?? this.dailyTarget,
      weeklyTarget: weeklyTarget ?? this.weeklyTarget,
      monthlyTarget: monthlyTarget ?? this.monthlyTarget,
      createdAt: createdAt ?? this.createdAt,
      color: color ?? this.color,
    );
  }
}

