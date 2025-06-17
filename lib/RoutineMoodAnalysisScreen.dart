import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:internship/mood_parser.dart';
import 'package:internship/mood_model.dart';

class RoutineMoodAnalysisScreen extends StatefulWidget {
  @override
  _RoutineMoodAnalysisScreenState createState() => _RoutineMoodAnalysisScreenState();
}

class _RoutineMoodAnalysisScreenState extends State<RoutineMoodAnalysisScreen> {
  final databaseReference = FirebaseDatabase.instance.ref();
  final currentUser = FirebaseAuth.instance.currentUser;

  Map<String, Map<MoodType, int>> moodEntriesByDate = {};
  Map<String, bool> routineCompletedByDate = {};

  final Map<MoodType, Color> moodColors = {
    MoodType.Happy: Colors.green,
    MoodType.Sad: Colors.blue,
    MoodType.Depressed: Colors.red,
    MoodType.Anxious: Colors.orange,
    MoodType.Excited: Colors.yellow,
    MoodType.Tired: Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    fetchMoodData();
  }

  Future<void> fetchMoodData() async {
    if (currentUser == null) return;
    final userId = currentUser!.uid;

    // Fetch moods
    final moodSnapshot = await databaseReference
        .child('Mood_List')
        .child(userId)
        .child('moods')
        .once();
    final parsedMoods = parseMoodSnapshot(moodSnapshot.snapshot);

    // Fetch routines
    final routineSnapshot = await databaseReference
        .child('Mood_List')
        .child(userId)
        .child('routines')
        .once();
    final routineData = routineSnapshot.snapshot.value as Map<dynamic, dynamic>?;

    Map<String, bool> tempRoutineCompletedByDate = {};

    if (routineData != null) {
      routineData.forEach((key, value) {
        final routineMap = Map<String, dynamic>.from(value);
        if (routineMap.containsKey('scheduledDate')) {
          final date = routineMap['scheduledDate'];
          final completed = routineMap['completedToday'] == true;
          tempRoutineCompletedByDate[date] = completed;
        }
      });
    }

    // Ensure all mood dates have routine status
    for (final date in parsedMoods.keys) {
      if (!tempRoutineCompletedByDate.containsKey(date)) {
        tempRoutineCompletedByDate[date] = false;
      }
    }

    setState(() {
      moodEntriesByDate = parsedMoods;
      routineCompletedByDate = tempRoutineCompletedByDate;
    });
  }

  List<BarChartGroupData> buildBarGroups() {
    List<String> sortedDates = moodEntriesByDate.keys.toList()..sort();
    List<BarChartGroupData> barGroups = [];

    for (int i = 0; i < sortedDates.length; i++) {
      final date = sortedDates[i];
      final moodCounts = moodEntriesByDate[date]!;

      double runningTotal = 0;
      List<BarChartRodStackItem> stacks = [];

      moodColors.forEach((mood, color) {
        final count = moodCounts[mood] ?? 0;
        if (count > 0) {
          stacks.add(BarChartRodStackItem(
            runningTotal,
            runningTotal + count.toDouble(),
            color,
          ));
          runningTotal += count;
        }
      });

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: runningTotal,
              rodStackItems: stacks,
              width: 18,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return barGroups;
  }

  Widget buildLegend() {
    return Wrap(
      spacing: 10,
      children: moodColors.entries.map((entry) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 12, color: entry.value),
            const SizedBox(width: 4),
            Text(entry.key.name),
          ],
        );
      }).toList(),
    );
  }

  double calculateMaxY() {
    return moodEntriesByDate.values
        .map((moods) => moods.values.fold<int>(0, (a, b) => a + b))
        .fold<int>(0, (a, b) => a > b ? a : b)
        .toDouble() + 2;
  }

  @override
  Widget build(BuildContext context) {
    final sortedDates = moodEntriesByDate.keys.toList()..sort();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Routine-Mood Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await fetchMoodData();
            },
          ),
        ],
      ),
      body: moodEntriesByDate.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: fetchMoodData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              SizedBox(
                height: 400,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: BarChart(
                    key: UniqueKey(),
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: calculateMaxY(),
                      barGroups: buildBarGroups(),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value < 0 || value >= sortedDates.length) return Container();
                              final dateStr = sortedDates[value.toInt()];
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(
                                  DateFormat('MM-dd').format(DateTime.parse(dateStr)),
                                  style: const TextStyle(fontSize: 10, color: Colors.white),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) => Text(
                              value.toInt().toString(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(show: false),
                    ),
                  ),
                ),
              ),
              buildLegend(),
              const SizedBox(height: 10),
              ...sortedDates.map((date) {
                final moods = moodEntriesByDate[date] ?? {};
                final hasSadOrDepressed = moods.keys.any(
                      (mood) => mood.name.toLowerCase() == 'sad' || mood.name.toLowerCase() == 'depressed',
                );
                final notCompleted = routineCompletedByDate[date] == false;

                if (hasSadOrDepressed && notCompleted) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'On $date: If you haven\'t completed your daily task, that could be one reason you\'re not feeling well.',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              }).toList(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
