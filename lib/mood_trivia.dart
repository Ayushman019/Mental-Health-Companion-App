import 'package:flutter/material.dart';
class MoodTrivia extends StatelessWidget {
  final String mood;

  const MoodTrivia({super.key, required this.mood});

  String getTriviaText() {
    switch (mood.toLowerCase()) {
      case 'happy':
        return "😊 Smiling, even when you’re not truly happy, can actually trigger your brain to release endorphins...";
      case 'sad':
        return "😢 Crying when you're sad releases stress hormones and toxins from your body...";
      case 'anxious':
        return "😰 The “fight or flight” response that triggers anxiety evolved to help humans react quickly...";
      case 'depressed':
        return "🌞 Sunlight exposure boosts serotonin production in the brain, which is why seasonal affective disorder...";
      case 'tired':
        return "😴 Your body produces a hormone called adenosine throughout the day...";
      case 'excited':
        return "🤩 When you’re excited, your brain releases dopamine, the “reward” neurotransmitter...";
      default:
        return "❓ No trivia available for this mood.";
    }
  }

  @override
  Widget build(BuildContext context) {
    final triviaText = getTriviaText();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber.shade900.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.note, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                "Note",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            triviaText,
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
