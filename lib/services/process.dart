import 'package:flutter/material.dart';

class Process {
  String name;
  int burstTime;
  int remainingTime;
  int waitingTime;
  int turnaroundTime;
  Color color;

  Process({
    required this.name,
    required this.burstTime,
    this.remainingTime = 0,
    this.waitingTime = 0,
    this.turnaroundTime = 0,
    Color? color,
  }) : color = color ?? Color((DateTime.now().microsecondsSinceEpoch * name.hashCode).toInt()).withOpacity(1.0) {
    remainingTime = burstTime;
  }
}