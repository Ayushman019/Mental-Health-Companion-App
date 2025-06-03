import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum MoodType{
  Happy ,
  Sad,
  Depressed,
  Anxious,
  Excited,
  Tired,
}

class Mood{
    final String id;
    final int intensity;
    final String? note;
    final MoodType mood;
    final DateTime timeStamps;
    final String? userId;

    Mood({
      required this.id,
      required this.intensity,
      required this.mood,
      required this.note,
      required this.timeStamps,
      required this.userId
    });
    //converting the Mood Model into format Suitable for Storing in the Firebase.
  Map<String ,dynamic> toMap(){
    return {
      'id': id,
      'intensity':intensity,
      'mood':mood.name,
      'note':note,
      'timeStamps':timeStamps.toIso8601String(),
      'userId':userId,
    };
  }
  //Converting the Data coming from Firebase to Mood Type.
    factory Mood.fromMap(Map<String, dynamic> map) {
      return Mood(
        id: map['id'] ?? '',
        mood: MoodType.values.firstWhere(
              (e) => e.name.toLowerCase() == (map['mood'] ?? '').toString().toLowerCase(),
          orElse: () => MoodType.Happy,
        ),
        intensity: map['intensity'] ?? 0,
        note: map['note'] ?? '',
        timeStamps: DateTime.tryParse(map['timeStamps'] ?? '') ?? DateTime.now(),
        userId: map['userId'] ?? '',
      );
    }


}
