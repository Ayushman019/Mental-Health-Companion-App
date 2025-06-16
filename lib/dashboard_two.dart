import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class RoutineMoodAnalysisScreen extends StatelessWidget {
  const RoutineMoodAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Routine-Mood Analysis")),
      body: FutureBuilder(
        future: _fetchAndProcessData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final processedData = snapshot.data as List<BarChartGroupData>;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: BarChart(
              BarChartData(
                barGroups: processedData,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        return Text(["Incomplete", "Complete"][index]);
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<List<BarChartGroupData>> _fetchAndProcessData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final db = FirebaseDatabase.instance.ref();

    // Fetch moods
    final moodsSnapshot = await db.child("moods/$uid").get();
    final moodMap = <String, String>{}; // date -> mood

    for (final mood in moodsSnapshot.children) {
      final timeStr = mood.child("timeStamps").value.toString();
      final date = DateFormat('yyyy-MM-dd').format(DateTime.parse(timeStr));
      final moodText = mood.child("mood").value.toString();
      moodMap[date] = moodText; // Only last mood per day
    }

    // Fetch routine completions
    final routineSnapshot = await db.child("routines").get();
    final completedMap = <String, bool>{}; // date -> true/false

    for (final routine in routineSnapshot.children) {
      final compDates = routine.child("completedOnDates");
      for (final entry in compDates.children) {
        final date = entry.key!;
        final done = entry.value == true;
        if (!completedMap.containsKey(date)) {
          completedMap[date] = done;
        } else {
          completedMap[date] = completedMap[date]! && done;
        }
      }
    }

    // Analyze
    int lowMoodWithIncomplete = 0;
    int lowMoodWithComplete = 0;
    final lowMoods = {"Sad", "Depressed"};

    moodMap.forEach((date, mood) {
      if (lowMoods.contains(mood)) {
        if (completedMap[date] == false || !completedMap.containsKey(date)) {
          lowMoodWithIncomplete++;
        } else {
          lowMoodWithComplete++;
        }
      }
    });

    return [
      BarChartGroupData(x: 0, barRods: [
        BarChartRodData(toY: lowMoodWithIncomplete.toDouble(), color: Colors.red)
      ]),
      BarChartGroupData(x: 1, barRods: [
        BarChartRodData(toY: lowMoodWithComplete.toDouble(), color: Colors.green)
      ]),
    ];
  }
}
