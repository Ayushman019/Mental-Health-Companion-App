import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:internship/mood_model.dart'; // For MoodType enum

Map<String, Map<MoodType, int>> parseMoodSnapshot(DataSnapshot snapshot) {
  Map<String, Map<MoodType, int>> moodCounts = {};

  if (snapshot.value is Map<dynamic, dynamic>) {
    final data = snapshot.value as Map<dynamic, dynamic>;

    data.forEach((userId, userMoods) {
      if (userMoods is Map<dynamic, dynamic>) {
        userMoods.forEach((moodId, moodData) {
          if (moodData is Map<dynamic, dynamic>) {
            final timestamp = moodData['timeStamps']?.toString();
            final moodStrRaw = moodData['mood']?.toString();

            if (timestamp == null || moodStrRaw == null) return;

            final date = DateTime.tryParse(timestamp);
            if (date == null) return;

            final mood = _parseMood(moodStrRaw);
            if (mood == null) return;

            final dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

            moodCounts.putIfAbsent(dateKey, () => {});
            moodCounts[dateKey]![mood] = (moodCounts[dateKey]![mood] ?? 0) + 1;

            print("✅ Parsed mood name: $mood");
          }
        });
      }
    });
  }

  print("✅ Final Parsed Moods: $moodCounts");
  return moodCounts;
}

MoodType? _parseMood(String moodStrRaw) {
  final moodStr = moodStrRaw.trim().toLowerCase();

  try {
    return MoodType.values.firstWhere(
          (e) => e.name.toLowerCase() == moodStr,
    );
  } catch (e) {
    print("❌ Invalid mood string: $moodStrRaw");
    return null;
  }
}

