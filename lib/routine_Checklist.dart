import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:internship/routine_log.dart';

class RoutineChecklistScreen extends StatefulWidget {
  const RoutineChecklistScreen({super.key});

  @override
  State<RoutineChecklistScreen> createState() => _RoutineChecklistScreenState();
}

class _RoutineChecklistScreenState extends State<RoutineChecklistScreen> {
  final user = FirebaseAuth.instance.currentUser;
  late DatabaseReference routineRef;
  late DatabaseReference moodRef;
  late DatabaseReference streakRef;

  Map<String, dynamic> routines = {};
  bool isLoading = true;
  int streakCount = 0;
  String lastStreakDate = '';
  String lastRoutineResetDate = '';

  @override
  void initState() {
    super.initState();
    if (user != null) {
      final basePath = 'Mood_List/${user!.uid}';
      routineRef = FirebaseDatabase.instance.ref('$basePath/routines');
      moodRef = FirebaseDatabase.instance.ref('$basePath/moods');
      streakRef = FirebaseDatabase.instance.ref('$basePath/streak');
      _loadInitialData();
    }
  }

  Future<void> _loadInitialData() async {
    if (user == null) return;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final streakSnapshot = await streakRef.get();
    if (streakSnapshot.exists) {
      final streakData = Map<String, dynamic>.from(streakSnapshot.value as Map);
      streakCount = streakData['count'] ?? 0;
      lastStreakDate = streakData['lastUpdated'] ?? '';
      lastRoutineResetDate = streakData['lastRoutineReset'] ?? '';
    }

    if (lastRoutineResetDate != today) {
      final routinesSnapshot = await routineRef.get();
      if (routinesSnapshot.exists) {
        final data = Map<String, dynamic>.from(routinesSnapshot.value as Map);
        final updates = <String, dynamic>{};
        data.forEach((key, value) {
          if (value is Map) {
            final routine = Map<String, dynamic>.from(value);
            if (routine['completedToday'] == true || isScheduledForToday(routine)) {
              updates['$key/completedToday'] = false;
            }
          }
        });
        if (updates.isNotEmpty) {
          await routineRef.update(updates);
        }
      }
      await streakRef.update({'lastRoutineReset': today});
      lastRoutineResetDate = today;
    }

    await _loadRoutines();
  }

  bool isScheduledForToday(Map<String, dynamic> routine) {
    final frequency = (routine['frequency'] ?? 'Daily').toString().toLowerCase();
    final scheduledDateStr = routine['scheduledDate'];
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (frequency == 'daily') return true;
    if (scheduledDateStr == null) return false;
    final scheduled = DateTime.tryParse(scheduledDateStr);
    if (scheduled == null) return false;

    if (frequency == 'weekly') {
      return DateTime.now().weekday == scheduled.weekday &&
          DateTime.now().difference(scheduled).inDays % 7 == 0;
    }

    if (frequency == 'monthly') {
      return scheduled.day == DateTime.now().day;
    }

    return false;
  }

  Future<void> _loadRoutines() async {
    if (user == null) return;

    final routinesSnapshot = await routineRef.get();
    Map<String, dynamic> loadedRoutines = {};

    if (routinesSnapshot.exists) {
      final data = Map<String, dynamic>.from(routinesSnapshot.value as Map);
      data.forEach((key, value) {
        if (value is Map) {
          final mapValue = Map<String, dynamic>.from(value);
          if (isScheduledForToday(mapValue)) {
            loadedRoutines[key] = mapValue;
          }
        }
      });
    }

    final streakSnapshot = await streakRef.get();
    if (streakSnapshot.exists) {
      final streakData = Map<String, dynamic>.from(streakSnapshot.value as Map);
      streakCount = streakData['count'] ?? 0;
      lastStreakDate = streakData['lastUpdated'] ?? '';
      lastRoutineResetDate = streakData['lastRoutineReset'] ?? '';
    }

    setState(() {
      routines = loadedRoutines;
      isLoading = false;
    });
  }

  Future<void> _updateRoutine(String key, bool isChecked) async {
    await routineRef.child(key).update({'completedToday': isChecked});
    setState(() {
      if (routines.containsKey(key)) {
        routines[key]!['completedToday'] = isChecked;
      }
    });
    await _checkAndUpdateStreak();
  }

  Future<void> _checkAndUpdateStreak() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final routinesSnapshot = await routineRef.get();
    Map<String, dynamic> currentScheduledRoutines = {};
    if (routinesSnapshot.exists) {
      final data = Map<String, dynamic>.from(routinesSnapshot.value as Map);
      data.forEach((key, value) {
        if (value is Map) {
          final mapValue = Map<String, dynamic>.from(value);
          if (isScheduledForToday(mapValue)) {
            currentScheduledRoutines[key] = mapValue;
          }
        }
      });
    }

    final allCompleted = currentScheduledRoutines.values.every((r) {
      return (r['completedToday'] == true || r['completedToday'] == 'true');
    });

    final streakSnapshot = await streakRef.get();
    if (streakSnapshot.exists) {
      final streakData = Map<String, dynamic>.from(streakSnapshot.value as Map);
      streakCount = streakData['count'] ?? 0;
      lastStreakDate = streakData['lastUpdated'] ?? '';
    }

    if (allCompleted) {
      if (lastStreakDate != today) {
        streakCount++;
        lastStreakDate = today;
        await streakRef.set({'count': streakCount, 'lastUpdated': today, 'lastRoutineReset': lastRoutineResetDate});
      }
    } else {
      final yesterday = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));
      if (lastStreakDate == yesterday) {
        streakCount = 0;
        await streakRef.set({'count': streakCount, 'lastUpdated': lastStreakDate, 'lastRoutineReset': lastRoutineResetDate});
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Routine Checklist", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/xx.jpeg',
            fit: BoxFit.cover,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Text(
                      'Current Streak: $streakCount days',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Make Streaks to keep Yourself Motivated!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Routine Cards
              Expanded(
                child: routines.isEmpty
                    ? Center(
                  child: Image.asset(
                    'assets/google.png',
                    width: 100,
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: routines.length,
                  itemBuilder: (ctx, index) {
                    final key = routines.keys.elementAt(index);
                    final routine = routines[key];
                    final title = routine['activity'] ?? 'Unnamed';
                    final note = routine['note'] ?? '';
                    final isDone = routine['completedToday'] ?? false;

                    return Card(
                      color: Colors.white.withOpacity(0.8),
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Colors.blueAccent),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        title: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        subtitle: note.isNotEmpty
                            ? Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            note,
                            style: const TextStyle(color: Colors.black87),
                          ),
                        )
                            : null,
                        trailing: Checkbox(
                          value: isDone,
                          onChanged: (val) {
                            if (val != null) {
                              _updateRoutine(key, val);
                            }
                          },
                          activeColor: Colors.blueAccent,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(bottom: 82),
                child:Center(
                  child: Text(
                    "🗓️It takes 21 days to build a habit.Start Today!",
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const RoutineLoggingScreen()));
        },
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 32),
        tooltip: 'Add New Routine',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      ),
    );
  }
}
