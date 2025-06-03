import 'package:flutter/material.dart';
import 'package:internship/mood_model.dart';

class MoodEntry {
  final MoodType mood;
  final String note;
  final double intensity;
  final DateTime date;

  MoodEntry({
    required this.mood,
    required this.note,
    required this.intensity,
    required this.date,
  });
}
