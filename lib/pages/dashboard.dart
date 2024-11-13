import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rr_apps/services/Tasks.dart';

class TaskManager extends StatefulWidget {
  const TaskManager({super.key});

  @override
  State<TaskManager> createState() => _TaskManagerState();
}

class _TaskManagerState extends State<TaskManager> {
  final List<Task> tasks = [];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _estimatedTimeController = TextEditingController();
  final TextEditingController _timeSliceController = TextEditingController(text: '5'); // Default 5 seconds
  
  Timer? _timer;
  bool isRunning = false;
  Task? currentTask;
  int currentTimeSlice = 0;
  List<Task> taskQueue = [];
  int elapsedSeconds = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _addTask() {
    if (_titleController.text.isNotEmpty && 
        _descriptionController.text.isNotEmpty && 
        _estimatedTimeController.text.isNotEmpty) {
      setState(() {
        tasks.add(
          Task(
            title: _titleController.text,
            description: _descriptionController.text,
            estimatedTime: int.parse(_estimatedTimeController.text),
          ),
        );
        _titleController.clear();
        _descriptionController.clear();
        _estimatedTimeController.clear();
      });
    }
  }

  void _startTaskRotation() {
    if (tasks.isEmpty || isRunning) return;

    setState(() {
      isRunning = true;
      taskQueue = tasks.where((task) => task.status != TaskStatus.completed).toList();
      elapsedSeconds = 0;
      print('Starting Round Robin with ${taskQueue.length} tasks');
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _executeTaskTimeSlice();
    });
  }

  void _executeTaskTimeSlice() {
    setState(() {
      if (currentTask == null && taskQueue.isNotEmpty) {
        currentTask = taskQueue.removeAt(0);
        currentTask!.status = TaskStatus.inProgress;
        currentTask!.startTime ??= DateTime.now();
        currentTimeSlice = 0;
        print('Starting task: ${currentTask!.title}');
      }

      if (currentTask != null) {
        elapsedSeconds++;
        currentTimeSlice++;
        currentTask!.remainingTime--;
        currentTask!.lastActiveTime = DateTime.now();

        print('Task ${currentTask!.title}: ${currentTask!.remainingTime}s remaining, Time slice: $currentTimeSlice/${_timeSliceController.text}s');

        if (currentTask!.remainingTime <= 0) {
          print('Task ${currentTask!.title} completed');
          currentTask!.status = TaskStatus.completed;
          currentTask = null;
        } else if (currentTimeSlice >= int.parse(_timeSliceController.text)) {
          print('Time slice expired for ${currentTask!.title}, moving to queue');
          currentTask!.status = TaskStatus.paused;
          taskQueue.add(currentTask!);
          currentTask = null;
        }
      }

      if (currentTask == null && taskQueue.isEmpty) {
        print('All tasks completed');
        _timer?.cancel();
        isRunning = false;
      }
    });
  }

  void _resetTasks() {
    setState(() {
      _timer?.cancel();
      isRunning = false;
      currentTask = null;
      taskQueue.clear();
      elapsedSeconds = 0;
      
      for (var task in tasks) {
        task.remainingTime = task.estimatedTime;
        task.status = TaskStatus.pending;
        task.startTime = null;
        task.lastActiveTime = null;
      }
      print('Tasks reset');
    });
  }

  String _formatDuration(int seconds) {
    return '$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Round Robin Task Manager (Seconds)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Task Title',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !isRunning,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Task Description',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !isRunning,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _estimatedTimeController,
                            decoration: const InputDecoration(
                              labelText: 'Duration (seconds)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            enabled: !isRunning,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _timeSliceController,
                            decoration: const InputDecoration(
                              labelText: 'Time Slice (seconds)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            enabled: !isRunning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: !isRunning ? _addTask : null,
                          child: const Text('Add Task'),
                        ),
                        ElevatedButton(
                          onPressed: !isRunning ? _startTaskRotation : null,
                          child: const Text('Start Tasks'),
                        ),
                        ElevatedButton(
                          onPressed: isRunning ? _resetTasks : null,
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (isRunning)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text('Total Time: ${_formatDuration(elapsedSeconds)} seconds',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      if (currentTask != null)
                        Column(
                          children: [
                            Text('Current Task: ${currentTask!.title}',
                                style: const TextStyle(fontSize: 16)),
                            Text('Time Slice: $currentTimeSlice/${_timeSliceController.text}s',
                                style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: task.color,
                        child: Text(task.title[0]),
                      ),
                      title: Text(task.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(task.description),
                          Text('Status: ${task.status.name}'),
                          Text('Remaining: ${task.remainingTime} seconds'),
                          if (task.startTime != null)
                            Text('Started: ${task.startTime!.hour}:${task.startTime!.minute}:${task.startTime!.second}'),
                          if (task.lastActiveTime != null)
                            Text('Last Active: ${task.lastActiveTime!.hour}:${task.lastActiveTime!.minute}:${task.lastActiveTime!.second}'),
                        ],
                      ),
                      trailing: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Center(
                          child: Text(
                            '${(task.remainingTime / task.estimatedTime * 100).round()}%',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}