import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:internship/mood_model.dart';
import 'package:internship/moodentryModel.dart';
import 'package:uuid/uuid.dart';
import 'package:internship/firebase_service.dart';

class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key});

  @override
  State<MoodScreen> createState() => _MoodScreen();
}

class _MoodScreen extends State<MoodScreen> {
  final formKey = GlobalKey<FormState>();
  var enteredNote = '';
  double _intensity = 5;
  MoodType? _selectedMood;

  void submitform() async {
    if (!formKey.currentState!.validate() || _selectedMood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all the Necessary Fields")),
      );
      return;
    }

    final shouldSubmit = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("Confirm Submission"),
        content: const Text("Are you sure you want to submit this mood entry?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Submit"),
          ),
        ],
      ),
    );

    if (shouldSubmit != true) return;

    formKey.currentState!.save();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User Not Authenticated")),
      );
      return;
    }

    final newMood = Mood(
      id: const Uuid().v4(),
      mood: _selectedMood!,
      intensity: _intensity.toInt(),
      note: enteredNote,
      timeStamps: DateTime.now(),
      userId: user.uid,
    );

    try {
      final dbRef = moodDbRef;
      final newMoodRef = dbRef.push();
      await newMoodRef.set(newMood.toMap());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mood Entry Submitted Successfully")),
      );

      Navigator.of(context).pop({
        'entry': newMood,
        'dBKey': newMoodRef.key,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to Submit the Data: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "How are you feeling today?",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/xx.jpeg"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Form and Bottom Note
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 60),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white24),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                DropdownButtonFormField<MoodType>(
                                  decoration: InputDecoration(
                                    label: const Text("Mood"),
                                    labelStyle: const TextStyle(color: Colors.white),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.1),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  dropdownColor: Colors.grey[900],
                                  value: _selectedMood,
                                  items: MoodType.values.map((mood) {
                                    return DropdownMenuItem(
                                      value: mood,
                                      child: Text(
                                        mood.name,
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    );
                                  }).toList(),
                                  style: const TextStyle(color: Colors.white),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedMood = value;
                                    });
                                  },
                                  validator: (value) => value == null
                                      ? "Please select your mood"
                                      : null,
                                ),
                                const SizedBox(height: 40),
                                Text(
                                  "Mood Intensity: ${_intensity.toInt()}",
                                  style: const TextStyle(color: Colors.white),
                                ),
                                Slider(
                                  value: _intensity,
                                  min: 1,
                                  max: 10,
                                  divisions: 9,
                                  label: _intensity.toInt().toString(),
                                  activeColor: Colors.white,
                                  inactiveColor: Colors.grey[600],
                                  onChanged: (value) {
                                    setState(() {
                                      _intensity = value;
                                    });
                                  },
                                ),
                                const SizedBox(height: 40),
                                TextFormField(
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    label: const Text("Note"),
                                    labelStyle: const TextStyle(color: Colors.white),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.1),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  maxLines: 3,
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().length < 2 ||
                                        value.trim().length > 100) {
                                      return 'Must be between 2 and 100 characters';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    enteredNote = value!;
                                  },
                                ),
                                const SizedBox(height: 40),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: submitform,
                                  child: const Text("Submit Mood"),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom Note
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "⚠️Note: Your mood entry helps us to Analyse you Better",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
