import 'package:flutter/material.dart';

class Task {
  String title;
  String description;
  int estimatedTime; // in minutes
  int remainingTime;
  TaskStatus status;
  Color color;
  DateTime? startTime;
  DateTime? lastActiveTime;

  Task({
    required this.title,
    required this.description,
    required this.estimatedTime,
    this.status = TaskStatus.pending,
    Color? color,
  }) : remainingTime = estimatedTime,
       color = color ?? Color((DateTime.now().microsecondsSinceEpoch * title.hashCode).toInt()).withOpacity(1.0);
}

enum TaskStatus {
  pending,
  inProgress,
  paused,
  completed
}