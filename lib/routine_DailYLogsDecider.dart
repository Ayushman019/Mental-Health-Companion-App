import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:internship/daily-Logs.dart';
import 'package:internship/routine_Log.dart';
import 'package:internship/firebase_service.dart';
class RoutineCheckScreen extends StatefulWidget {
  const RoutineCheckScreen({super.key});

  @override
  _RoutineCheckScreenState createState() => _RoutineCheckScreenState();
}

class _RoutineCheckScreenState extends State<RoutineCheckScreen> {
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkForRoutineData();
  }

  Future<void> _checkForRoutineData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Not logged in, maybe redirect to login screen or handle accordingly
      setState(() => _checking = false);
      return;
    }

    final userId = user.uid;
    final snapshot = await FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://moodtracker-74086-default-rtdb.asia-southeast1.firebasedatabase.app',
    ).ref('Mood_List/${user.uid}/routines').get();
    if (snapshot.exists && snapshot.children.isNotEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => DailyLogsScreen(user: user!)),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RoutineLoggingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _checking
            ? const CircularProgressIndicator()
            : const Text('Error loading data'),
      ),
    );
  }
}
