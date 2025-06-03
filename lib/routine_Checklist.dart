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

  @override
  void initState() {
    super.initState();
    if (user != null) {
      final basePath = 'Mood_List/${user!.uid}';
      routineRef = FirebaseDatabase.instance.ref('$basePath/routines');
      moodRef = FirebaseDatabase.instance.ref('$basePath/moods');
      streakRef = FirebaseDatabase.instance.ref('$basePath/streak');
      _loadRoutines();
    }
  }

  bool isScheduledForToday(Map<String, dynamic> routine) {
    final frequency = (routine['frequency'] ?? 'Daily').toString().toLowerCase();
    final scheduledDateStr = routine['scheduledDate'];
    if (frequency == 'daily') return true;
    if (scheduledDateStr == null) return false; // after 'daily' check

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (frequency == 'daily') return true;

    if (frequency == 'weekly') {
      final scheduled = DateTime.tryParse(scheduledDateStr);
      return scheduled != null &&
          DateTime.now().difference(scheduled).inDays % 7 == 0;
    }

    if (frequency == 'monthly') {
      final scheduled = DateTime.tryParse(scheduledDateStr);
      return scheduled != null &&
          scheduled.day == DateTime.now().day;
    }

    return false;
  }

  Future<void> _loadRoutines() async {
    if (user == null) return;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final routinesSnapshot = await routineRef.get();
    final streakSnapshot = await streakRef.get();

    Map<String, dynamic> loadedRoutines = {};
    if (routinesSnapshot.exists) {
      final data = Map<String, dynamic>.from(routinesSnapshot.value as Map);
      data.forEach((key, value) {
        if (value is Map) {
          final mapValue = Map<String, dynamic>.from(value);
          final scheduled = isScheduledForToday(mapValue);
          print('Routine $key scheduled today: $scheduled');
          if (scheduled) {
            loadedRoutines[key] = mapValue;
          }
        }
      });
    }

    // Filter routines scheduled for today
    final todayKeys = loadedRoutines.entries
        .where((e) => isScheduledForToday(e.value))
        .map((e) => e.key)
        .toList();

    final todayRoutines = {
      for (var key in todayKeys) key: loadedRoutines[key]!,
    };

    // Fetch current streak data
    if (streakSnapshot.exists) {
      final streakData = Map<String, dynamic>.from(streakSnapshot.value as Map);
      streakCount = streakData['count'] ?? 0;
      lastStreakDate = streakData['lastUpdated'] ?? '';
    }

    print('--- Routine Completion Status ---');
    final allCompleted = todayRoutines.values.every((r) {
      final val = r['completedToday'];
      print('${r['activity']} - completedToday: $val');
      return val == true || val == 'true';
    });


    print('--- Streak Debug Info ---');
    print('Today: $today');
    print('Last streak date: $lastStreakDate');
    print('Current streak count: $streakCount');
    print('All completed today: $allCompleted');

    if (allCompleted) {
      if (lastStreakDate != today) {
        streakCount++;
        lastStreakDate = today;
        await streakRef.set({'count': streakCount, 'lastUpdated': today});
        print('✅ Streak incremented to $streakCount');
      } else if (streakCount == 0) {
        // Fix case: streak date was updated but count wasn't
        streakCount = 1;
        await streakRef.set({'count': streakCount, 'lastUpdated': today});
        print('⚠️ Fixed zero-count bug. Streak updated to 1');
      } else {
        print('ℹ️ Already updated streak today.');
      }
    }

    else {
  final yesterday = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));
  if (lastStreakDate == yesterday) {
  streakCount = 0;
  await streakRef.set({'count': streakCount, 'lastUpdated': lastStreakDate});
  print('❌ Missed today. Streak reset to 0');
  } else {
  print('ℹ️ No change to streak.');
  }
  }



  setState(() {
      routines = todayRoutines;
      isLoading = false;
    });
  }

  Future<void> _updateRoutine(String key, bool isChecked) async {
    await routineRef.child(key).update({'completedToday': isChecked});
    await _loadRoutines(); // Reload to update streak if needed
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Routine Checklist",
          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.amber),
      ),
      body: routines.isEmpty
          ? const Center(
        child: Text(
          "No routines yet.\nTap + to add a new routine!",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      )
          : ListView.builder(
        itemCount: routines.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (ctx, index) {
          final key = routines.keys.elementAt(index);
          final routine = routines[key];
          final title = routine['activity'] ?? 'Unnamed';
          final note = routine['note'] ?? '';
          final isDone = routine['completedToday'] ?? false;

          return Card(
            color: Colors.grey[900],
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.amber),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              title: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              subtitle: note.isNotEmpty
                  ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  note,
                  style: const TextStyle(color: Colors.white70),
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
                activeColor: Colors.amber,
                checkColor: Colors.black,
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const RoutineLoggingScreen()));
        },
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add, size: 32),
        tooltip: 'Add New Routine',
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        ),
      ),
    );
  }
}
