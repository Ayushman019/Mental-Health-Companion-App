import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:internship/firebase_service.dart';
import 'package:internship/daily-Logs.dart';

class RoutineLoggingScreen extends StatefulWidget {
  const RoutineLoggingScreen({super.key});

  @override
  State<RoutineLoggingScreen> createState() => _RoutineLoggingScreenState();
}

class _RoutineLoggingScreenState extends State<RoutineLoggingScreen> {
  List<_RoutineFormData> _routineForms = [_RoutineFormData()];

  final List<String> _frequencies = [
    'Daily',
    'Weekly',
    'Monthly',
    'Semi-Monthly'
  ];

  Future<void> _pickTime(int index) async {
    final time = await showTimePicker(
      context: context,
      initialTime: _routineForms[index].selectedTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _routineForms[index].selectedTime = time);
    }
  }

  Future<void> _pickDate(int index) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: _routineForms[index].scheduledDate ?? DateTime.now(),
    );
    if (date != null) {
      setState(() => _routineForms[index].scheduledDate = date);
    }
  }

  void _addRoutineForm() {
    setState(() {
      _routineForms.add(_RoutineFormData());
    });
  }

  void _removeRoutineForm(int index) {
    if (_routineForms.length > 1) {
      setState(() {
        _routineForms.removeAt(index);
      });
    }
  }

  void _submitRoutine() async {
    for (var form in _routineForms) {
      if (form.activityController.text.trim().isEmpty ||
          form.selectedTime == null ||
          form.scheduledDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please fill all required fields in every activity')),
        );
        return;
      }
    }

    try {
      for (var form in _routineForms) {
        final activity = form.activityController.text.trim();
        final note = form.noteController.text.trim();
        final time = form.selectedTime!;
        final date = form.scheduledDate!;
        final frequency = form.selectedFrequency;

        final formattedTime = time.format(context);
        final formattedDate = DateFormat('yyyy-MM-dd').format(date);

        final routineData = {
          'activity': activity,
          'note': note,
          'time': formattedTime,
          'scheduledDate': formattedDate,
          'frequency': frequency,
          'createdAt': DateTime.now().toIso8601String(),
          'completedToday': false,
        };

        final newRoutineRef = routineDbRef.push();
        await newRoutineRef.set(routineData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All routines saved successfully')),
      );

      setState(() {
        _routineForms = [_RoutineFormData()];
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              DailyLogsScreen(user: FirebaseAuth.instance.currentUser!),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save routines: $e')),
      );
    }
  }

  @override
  void dispose() {
    for (var form in _routineForms) {
      form.activityController.dispose();
      form.noteController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Your Activities!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.amber,
      ),
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _routineForms.length,
                itemBuilder: (context, index) {
                  final form = _routineForms[index];
                  final timeText = form.selectedTime != null
                      ? form.selectedTime!.format(context)
                      : 'Select Time';
                  final dateText = form.scheduledDate != null
                      ? DateFormat('dd MMM yyyy').format(form.scheduledDate!)
                      : 'Select Date';

                  return Card(
                    color: Colors.grey[900],
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.amber),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Activity ${index + 1}",
                                  style: const TextStyle(
                                      color: Colors.amber,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                              ),
                              if (_routineForms.length > 1)
                                IconButton(
                                  onPressed: () => _removeRoutineForm(index),
                                  icon: const Icon(Icons.delete,
                                      color: Colors.redAccent),
                                ),
                            ],
                          ),
                          TextField(
                            controller: form.activityController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Activity',
                              labelStyle: TextStyle(color: Colors.white70),
                              enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.amber)),
                              focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.amber)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: form.noteController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Note (Optional)',
                              labelStyle: TextStyle(color: Colors.white70),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            title: Text('Time: $timeText',
                                style: const TextStyle(color: Colors.white70)),
                            trailing: const Icon(Icons.access_time,
                                color: Colors.amber),
                            onTap: () => _pickTime(index),
                            contentPadding: EdgeInsets.zero,
                          ),
                          ListTile(
                            title: Text('Scheduled Date: $dateText',
                                style: const TextStyle(color: Colors.white70)),
                            trailing: const Icon(Icons.calendar_today,
                                color: Colors.amber),
                            onTap: () => _pickDate(index),
                            contentPadding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            dropdownColor: Colors.black,
                            value: form.selectedFrequency,
                            decoration: const InputDecoration(
                              labelText: "Frequency",
                              labelStyle: TextStyle(color: Colors.white70),
                              enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.amber)),
                            ),
                            items: _frequencies
                                .map((f) => DropdownMenuItem(
                              value: f,
                              child: Text(f,
                                  style: const TextStyle(
                                      color: Colors.white)),
                            ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() =>
                                form.selectedFrequency = value);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber,
        onPressed: _addRoutineForm,
        child: const Icon(Icons.add, color: Colors.black),
        tooltip: 'Add another activity',
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: ElevatedButton(
          onPressed: _submitRoutine,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
            padding:
            const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          ),
          child: const Text("Save All Activities"),
        ),
      ),
    );
  }
}

class _RoutineFormData {
  final TextEditingController activityController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  TimeOfDay? selectedTime;
  DateTime? scheduledDate;
  String selectedFrequency = 'Daily';
}
