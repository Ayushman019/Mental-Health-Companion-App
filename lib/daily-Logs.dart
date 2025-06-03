import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:internship/Add_moodScreen.dart';
import 'package:internship/firebase_service.dart';
import 'package:internship/mood_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:internship/dashboard_Screen.dart';
import 'package:internship/routine_Checklist.dart';
import 'package:intl/intl.dart';

class DailyLogsScreen extends StatefulWidget {
  final User user;
  const DailyLogsScreen({super.key, required this.user});

  @override
  State<DailyLogsScreen> createState() => _DailyLogsScreenState();
}

class _DailyLogsScreenState extends State<DailyLogsScreen> {
  late final User _currentUser;
  final Map<String, String> FirebaseKeys = {};
  final List<Mood> _moodEntries = [];
  int _selectedIndex = 0;

  int streakCount = 0;
  bool isStreakLoading = true;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _loadStreak(); // ⬅️ Load streak here
    _migrateOldMoodEntriesIfAny().then((_) {
      _loadMoodsFromFirebase();
    });
  }

  Future<void> _loadStreak() async {
    try {
      final data = await fetchStreak(); // 👈 Use your helper function
      setState(() {
        streakCount = (data['count'] as num?)?.toInt() ?? 0;
        isStreakLoading = false;
      });
    } catch (e) {
      print("❌ Failed to load streak: $e");
      setState(() {
        isStreakLoading = false; // Still stop the spinner
      });
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openMoodScreen() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (context) => MoodScreen()),
    );

    if (result != null && result['entry'] != null && result['dBKey'] != null) {
      final entry = result['entry'] as Mood;
      final dBKey = result['dBKey'] as String;

      setState(() {
        _moodEntries.add(entry);
        FirebaseKeys[entry.id] = dBKey;
      });
    }
  }

  Future<void> _migrateOldMoodEntriesIfAny() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final oldDataSnapshot = await moodDbRef.get();
    if (oldDataSnapshot.exists) {
      final allData = oldDataSnapshot.value as Map<dynamic, dynamic>;

      for (final entry in allData.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value is Map && value['userId'] == user.uid) {
          await moodDbRef.child(user.uid).child(key).set(value);
          await moodDbRef.child(key).remove();
        }
      }
    }
  }

  void _loadMoodsFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final dbRef = moodDbRef.child(user.uid);
      final snapshot = await dbRef.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;

        final loadedMoods = <Mood>[];
        final loadedKeys = <String, String>{};

        data.forEach((key, value) {
          final mood = Mood.fromMap(Map<String, dynamic>.from(value));
          loadedMoods.add(mood);
          loadedKeys[mood.id] = key;
        });

        setState(() {
          _moodEntries.clear();
          _moodEntries.addAll(loadedMoods);
          FirebaseKeys.clear();
          FirebaseKeys.addAll(loadedKeys);
        });
      }
    } catch (e) {
      print("❌ Error loading moods: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading moods: $e")),
      );
    }
  }

  Widget _buildMoodLogView() {
    if (_moodEntries.isEmpty) {
      return const Center(
        child: Text("Start Adding Your Mood by Pressing + on the Top"),
      );
    }

    return ListView.builder(
      itemCount: _moodEntries.length,
      itemBuilder: (ctx, index) {
        final entry = _moodEntries[index];
        return Dismissible(
          key: ValueKey(entry.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: EdgeInsets.all(12),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (direction) async {
            final entryToRemove = _moodEntries[index];
            final dBKey = FirebaseKeys[entryToRemove.id];
            try {
              if (dBKey != null) {
                final dbRef = moodDbRef.child(_currentUser.uid).child(dBKey);
                await dbRef.remove();
                setState(() {
                  _moodEntries.removeAt(index);
                  FirebaseKeys.remove(entryToRemove.id);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Mood Entry Deleted Successfully.")),
                );
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Failed to delete from Firebase: $e")),
              );
            }
          },
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.mood.name.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.note ?? '',
                          style: TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        entry.intensity.toInt().toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${entry.timeStamps.day}/${entry.timeStamps.month}/${entry.timeStamps.year}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white12,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      _buildMoodLogView(),
      const DashboardScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () {}, icon: Icon(Icons.person)),
        title: Text(
          "Hi MindNavigator!",
          style: TextStyle(
            fontSize: 15,
            color: Colors.amber,
          ),
        ),
        actions: [
          InkWell(
            onTap: (){
              Navigator.of(context).push(MaterialPageRoute(builder: (context)=>RoutineChecklistScreen()),)
              .then((_)=>_loadStreak());
            },
            child: Row(
              children: [
                Icon(Icons.local_fire_department_rounded,
                    color: Colors.amberAccent),
                const SizedBox(width: 4),
                isStreakLoading
                    ? const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Text(
                  streakCount.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amberAccent,
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
          IconButton(
            onPressed: _openMoodScreen,
            icon: Icon(Icons.add),
            color: Colors.amber,
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        backgroundColor: Colors.amber,
        selectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Daily Logs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
        ],
      ),
    );
  }
}
