import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:internship/mood_model.dart';
import 'package:internship/moodentryModel.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import 'package:internship/firebase_service.dart';
class MoodScreen extends StatefulWidget{
  const MoodScreen({super.key});
  @override
  State<MoodScreen> createState(){
    return _MoodScreen();
  }
}
class _MoodScreen extends State<MoodScreen> {
  final formKey = GlobalKey<FormState>();
  var enteredNote = '';
  double _intensity = 5;
  MoodType? _selectedMood;

  void submitform() async {
    if (!formKey.currentState!.validate() || _selectedMood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all the Necessary Fields")),);
      return;
    }
    final shouldSubmit = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) =>
          CupertinoAlertDialog(
            title: const Text("Confirm Submission"),
            content: const Text(
                "Are you sure you want to submit this mood entry?"),
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

    // If user cancels, do nothing
    if (shouldSubmit != true) return;

    formKey.currentState!.save();
    final user = FirebaseAuth.instance.currentUser!;
    if(user==null){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User Not Authenticated")),
      );
      return;
    }
    final newMood=Mood(
      id: const Uuid().v4(),
      mood: _selectedMood!,
      intensity: _intensity.toInt(),
      note: enteredNote.toString(),
      timeStamps: DateTime.now(),
      userId:user.uid,
    );
    try{
      final dbRef=moodDbRef;

      print("Attempting to write new mood entry to Firebase...");
      final newMoodRef= dbRef.push();
      await newMoodRef.set(newMood.toMap());
      print("Write to Firebase succeeded!");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Mood Entry Submitted Successfully",style:TextStyle(color: Colors.black))),
          );
      final newEntry=newMood;
      Navigator.of(context).pop({
        'entry': newMood,
        'dBKey': newMoodRef.key,
      });
    }
    catch (e, stacktrace){
      print("Failed to submit mood entry: $e");
      print("Stacktrace: $stacktrace");
      ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to Submit the Data $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Enter Your Today's Mood"),
      ),
      body: Padding(padding: EdgeInsets.all(12),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              DropdownButtonFormField<MoodType>(
                decoration: InputDecoration(
                  label: Text("Select your Mood", style: TextStyle(color: Colors.amber),),
                ),
                value: _selectedMood,
                dropdownColor: Colors.black,
                style: const TextStyle(
                  color: Colors.white,
                ),
                items: MoodType.values.map((mood) {
                  return DropdownMenuItem(
                    child: Text(mood.name, style: TextStyle(color: Colors
                        .white),),
                    value: mood,
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMood = value;
                  });
                },
                validator: (value) =>
                value == null
                    ? "Please Select Your Mood"
                    : null,
              ),
              const SizedBox(height: 26,),
              Align(
                alignment: Alignment.centerLeft,
                child: Text("Mood Intensity: $_intensity",
                  style: TextStyle(fontSize: 16),
                ),),
              const SizedBox(height: 15,),
              Slider(value: _intensity,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: _intensity.toInt().toString(),
                  onChanged: (value) {
                    setState(() {
                      _intensity = value;
                    });
                  }),
              const SizedBox(height: 16,),
              TextFormField(
                decoration: InputDecoration(
                  label: Text("Note"),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty || value
                      .trim()
                      .length <= 1 || value
                      .trim()
                      .length > 100) {
                    return 'Must be Between 1 and 100 characters';
                  }
                  return null;
                },
                onSaved: (value) {
                  enteredNote = value!;
                },
              ),
              const SizedBox(height: 35),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      submitform();
                    },
                    child: const Text("Submit Data"),
                  ),
                ],
              )
            ],),
        ),
      ),
    );
  }
}

