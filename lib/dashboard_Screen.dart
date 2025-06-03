import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:internship/mood_model.dart';
import 'package:internship/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:internship/mood_trivia.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:internship/google_fit.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, double> moodCounts = {};
  String topMood = '';
  double topMoodCount = 0;

  late DatabaseReference userMoodRef;
  StreamSubscription<DatabaseEvent>? _moodSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchMoods();
    _startListeningToMoodData();
  }
  Future<void> fetchMoods() async {
    final ref = FirebaseDatabase.instance.ref().child("Mood_List");


    final snapshot = await ref.get();

    if (snapshot.exists) {
      final List<Mood> moods = [];

      final data = snapshot.value;

      if (data is Map) {
        for (final entry in data.entries) {
          final value = entry.value;

          // Nested moods under user ID
          if (value is Map) {
            for (final moodEntry in value.entries) {
              final moodData = moodEntry.value;
              if (moodData is Map) {
                try {
                  final mood = Mood.fromMap(Map<String, dynamic>.from(moodData));
                  moods.add(mood);
                  print('Parsed mood name: ${mood.mood}');
                } catch (e) {
                  print('Error parsing mood entry: $e');
                }
              }
            }
          }
          // Flat mood entry (unlikely but safe)
          else if (value is Map) {
            try {
              final mood = Mood.fromMap(Map<String, dynamic>.from(value));
              moods.add(mood);
              print('Parsed mood name: ${mood.mood}');
            } catch (e) {
              print('Error parsing mood entry: $e');
            }
          } else {
            print('Skipping non-map entry: ${entry.key} => ${entry.value}');
          }
        }
      } else {
        print('Snapshot root is not a Map');
      }

      // Do something with moods list here or call setState if needed
      // For example: calculate moodCounts, update UI, etc.

    } else {
      print("No data found.");
    }
  }
  void _startListeningToMoodData() {
    try {
      userMoodRef = moodDbRef;

      _moodSubscription?.cancel();

      _moodSubscription = userMoodRef.onValue.listen((DatabaseEvent event) {
        final snapshot = event.snapshot;
        debugPrint("Snapshot received: ${snapshot.value}");

        if (!snapshot.exists) {
          debugPrint("No data found.");
          setState(() {
            moodCounts = {};
            topMood = '';
            topMoodCount = 0;
          });
          return;
        }

        final moodCounter = <String, double>{};
        final data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          if (value is Map) {
            // Check if value looks like a mood entry (has 'mood' key)
            if (value.containsKey('mood')) {
              try {
                final mood = Mood.fromMap(Map<String, dynamic>.from(value));
                moodCounter[mood.mood.name] = (moodCounter[mood.mood.name] ?? 0) + 1;
              } catch (e) {
                debugPrint("Error parsing mood entry: $e");
              }
            } else {
              // Otherwise, treat as nested user moods map
              final userMoods = Map<dynamic, dynamic>.from(value);
              userMoods.forEach((moodId, moodData) {
                try {
                  final mood = Mood.fromMap(Map<String, dynamic>.from(moodData));
                  moodCounter[mood.mood.name] = (moodCounter[mood.mood.name] ?? 0) + 1;
                } catch (e) {
                  debugPrint("Error parsing nested mood entry: $e");
                }
              });
            }
          } else {
            debugPrint("Skipping non-map entry: $key => $value");
          }
        });


        String mostFrequentMood = '';
        double maxCount = 0;
        moodCounter.forEach((mood, count) {
          if (count > maxCount) {
            mostFrequentMood = mood;
            maxCount = count;
          }
        });

        setState(() {
          moodCounts = moodCounter;
          topMood = mostFrequentMood;
          topMoodCount = maxCount;
        });
      });
    } catch (e) {
      debugPrint("Exception in _startListeningToMoodData: $e");
      setState(() {
        moodCounts = {};
        topMood = '';
        topMoodCount = 0;
      });
    }
  }


  @override
  void dispose() {
    _tabController.dispose();
    _moodSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = moodCounts.values.fold(0.0, (a, b) => a + b);
    final percent = total == 0 ? "0" : (topMoodCount / total * 100).toStringAsFixed(1);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header and Tabs
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12),
              child: Row(
                children: const [
                  Text(
                    "Mood Analysis",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              indicatorColor: Colors.amber,
              labelColor: Colors.amber,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: "Overview"),
                Tab(text: "Google-Fit"),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Overview Tab
                  moodCounts.isEmpty
                      ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                      : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          "Your most frequent mood is $topMood\nwith $percent% of all entries.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(height: 20),
                        PieChart(
                          dataMap: moodCounts,
                          chartType: ChartType.ring,
                          animationDuration: const Duration(seconds: 1),
                          chartRadius: MediaQuery.of(context).size.width / 2.2,
                          legendOptions: const LegendOptions(
                            showLegendsInRow: true,
                            legendPosition: LegendPosition.bottom,
                            legendTextStyle: TextStyle(color: Colors.amber),
                          ),
                          chartValuesOptions: const ChartValuesOptions(
                            showChartValuesInPercentage: true,
                            showChartValueBackground: false,
                            decimalPlaces: 1,
                            chartValueStyle: TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade700,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          onPressed: () {
                            // You can re-start listener manually if needed
                            _startListeningToMoodData();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text("Refresh"),
                        ),
                        const SizedBox(height: 24),
                        MoodTrivia(mood: topMood),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  // History Tab Placeholder
                  GoogleFitScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
