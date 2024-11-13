import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rr_apps/services/process.dart';

class RoundRobinScheduler extends StatefulWidget {
  const RoundRobinScheduler({super.key});

  @override
  State<RoundRobinScheduler> createState() => _RoundRobinSchedulerState();
}

class _RoundRobinSchedulerState extends State<RoundRobinScheduler> {
  final List<Process> processes = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _burstTimeController = TextEditingController();
  final TextEditingController _quantumController = TextEditingController();
  
  List<String> executionOrder = [];
  List<MapEntry<String, Color>> timelineBlocks = [];
  double averageWaitingTime = 0;
  double averageTurnaroundTime = 0;
  
  bool isRunning = false;
  Timer? _timer;
  int currentTime = 0;
  Process? currentProcess;
  int currentQuantumUsed = 0;
  List<Process> readyQueue = [];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _addProcess() {
    if (_nameController.text.isNotEmpty && _burstTimeController.text.isNotEmpty) {
      setState(() {
        processes.add(
          Process(
            name: _nameController.text,
            burstTime: int.parse(_burstTimeController.text),
          ),
        );
        _nameController.clear();
        _burstTimeController.clear();
      });
    }
  }

  void _startRoundRobin() {
    if (_quantumController.text.isEmpty || processes.isEmpty || isRunning) return;

    setState(() {
      isRunning = true;
      currentTime = 0;
      timelineBlocks = [];
      readyQueue = List.from(processes);
      
      // Reset process states
      for (var process in processes) {
        process.remainingTime = process.burstTime;
        process.waitingTime = 0;
        process.turnaroundTime = 0;
      }
    });

    _timer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      _executeNextTimeSlice();
    });
  }

  void _executeNextTimeSlice() {
    setState(() {
      if (currentProcess == null && readyQueue.isNotEmpty) {
        currentProcess = readyQueue.removeAt(0);
        currentQuantumUsed = 0;
      }

      if (currentProcess != null) {
        currentTime++;
        currentProcess!.remainingTime--;
        currentQuantumUsed++;
        timelineBlocks.add(MapEntry(currentProcess!.name, currentProcess!.color));

        // Update waiting time for processes in ready queue
        for (var process in readyQueue) {
          process.waitingTime++;
        }

        // Check if current process is done or quantum is expired
        if (currentProcess!.remainingTime == 0) {
          currentProcess!.turnaroundTime = currentTime;
          currentProcess = null;
        } else if (currentQuantumUsed == int.parse(_quantumController.text)) {
          readyQueue.add(currentProcess!);
          currentProcess = null;
        }
      }

      // Check if all processes are completed
      if (currentProcess == null && readyQueue.isEmpty) {
        _timer?.cancel();
        isRunning = false;
        _calculateAverages();
      }
    });
  }

  void _calculateAverages() {
    double totalWaiting = 0;
    double totalTurnaround = 0;
    for (var process in processes) {
      totalWaiting += process.waitingTime;
      totalTurnaround += process.turnaroundTime;
    }
    
    setState(() {
      averageWaitingTime = totalWaiting / processes.length;
      averageTurnaroundTime = totalTurnaround / processes.length;
    });
  }

  void _resetSimulation() {
    setState(() {
      _timer?.cancel();
      isRunning = false;
      currentTime = 0;
      currentProcess = null;
      timelineBlocks.clear();
      readyQueue.clear();
      
      for (var process in processes) {
        process.remainingTime = process.burstTime;
        process.waitingTime = 0;
        process.turnaroundTime = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-time Round Robin Scheduler'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Process Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _burstTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Burst Time',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: !isRunning ? _addProcess : null,
                  child: const Text('Add Process'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _quantumController,
              decoration: const InputDecoration(
                labelText: 'Time Quantum',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              enabled: !isRunning,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: !isRunning ? _startRoundRobin : null,
                  child: const Text('Start'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: isRunning ? _resetSimulation : null,
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 60,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: timelineBlocks.isEmpty
                  ? const Center(child: Text('Timeline will appear here'))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: timelineBlocks.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 30,
                          margin: const EdgeInsets.all(2),
                          color: timelineBlocks[index].value,
                          child: Center(
                            child: Text(
                              timelineBlocks[index].key,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  const Text('Processes:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: processes.length,
                    itemBuilder: (context, index) {
                      final process = processes[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: process.color,
                            child: Text(process.name[0]),
                          ),
                          title: Text('Process ${process.name}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Burst Time: ${process.burstTime}'),
                              Text('Remaining Time: ${process.remainingTime}'),
                              Text('Waiting Time: ${process.waitingTime}'),
                              Text('Turnaround Time: ${process.turnaroundTime}'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  if (!isRunning && timelineBlocks.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                        'Average Waiting Time: ${averageWaitingTime.toStringAsFixed(2)}'),
                    Text(
                        'Average Turnaround Time: ${averageTurnaroundTime.toStringAsFixed(2)}'),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}