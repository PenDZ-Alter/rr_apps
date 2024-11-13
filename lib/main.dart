import 'package:flutter/material.dart';
import 'package:rr_apps/pages/dashboard.dart';
import 'package:rr_apps/pages/simulation.dart';

void main() {
  runApp(const RoundRobinApp());
}

class RoundRobinApp extends StatelessWidget {
  const RoundRobinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Round Robin Scheduler',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const TaskManager(),
    );
  }
}