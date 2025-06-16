import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:internship/Add_moodScreen.dart';
import 'package:internship/firebase_service.dart';
import 'package:internship/mood_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:internship/dashboard_Screen.dart';
import 'package:internship/routine_Checklist.dart';

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
    _loadStreak();
    _migrateOldMoodEntriesIfAny().then((_) {
      _loadMoodsFromFirebase();
    });
  }

  Future<void> _loadStreak() async {
    try {
      final data = await fetchStreak();
      setState(() {
        streakCount = (data['count'] as num?)?.toInt() ?? 0;
        isStreakLoading = false;
      });
    } catch (e) {
      print("❌ Failed to load streak: $e");
      setState(() {
        isStreakLoading = false;
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
      return Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + kToolbarHeight + 24,
        ),
        child: const Center(
          child: Text("Start Adding Your Mood by Pressing + on the Top"),
        ),
      );
    }

    _moodEntries.sort((a, b) => b.timeStamps.compareTo(a.timeStamps));

    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + kToolbarHeight + 24,
      ),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
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
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue.shade700, width: 1.2),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white70,
              ),
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
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.note ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        entry.intensity.toInt().toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${entry.timeStamps.day}/${entry.timeStamps.month}/${entry.timeStamps.year}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      _buildMoodLogView(),
      const DashboardScreen(),
    ];

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.person, color: Colors.white),
        title: const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Text(
            "Hi MindNavigator!",
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          InkWell(
            onTap: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (context) => RoutineChecklistScreen()))
                  .then((_) => _loadStreak());
            },
            child: Row(
              children: [
                const Icon(Icons.local_fire_department_rounded, color: Colors.amberAccent),
                const SizedBox(width: 4),
                isStreakLoading
                    ? const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
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
            icon: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/xy.jpeg',
              fit: BoxFit.cover,
            ),
          ),
          _screens[_selectedIndex],
        ],
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onTabTapped,
          backgroundColor: Colors.blue,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.grey[300],
          unselectedItemColor: Colors.yellow[500],
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
      ),
    );
  }
}