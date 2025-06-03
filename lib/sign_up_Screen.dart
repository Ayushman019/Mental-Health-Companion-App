import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Add intl to your pubspec.yaml
import 'package:internship/daily-Logs.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:internship/routine_DailYLogsDecider.dart';
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  DateTime? _selectedDob;
  bool _isLoading = false;
  Future<void> registerUser(String email, String password, String name) async {
    try {
      final UserCredential userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      print("✅ User registered");
    } catch (e) {
      print("❌ Registration error: $e");
    }
  }


  int? get _calculatedAge {
    if (_selectedDob == null) return null;
    final today = DateTime.now();
    int age = today.year - _selectedDob!.year;
    if (today.month < _selectedDob!.month ||
        (today.month == _selectedDob!.month && today.day < _selectedDob!.day)) {
      age--;
    }
    return age;
  }
  Future<void> saveUserProfile({
    required String uid,
    required String name,
    required String email,
    required DateTime dob,
    required int age,
  }) async {
    final userRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://moodtracker-74086-default-rtdb.asia-southeast1.firebasedatabase.app/',
    ).ref("Users/$uid");

    await userRef.set({
      "name": name,
      "email": email,
      "dob": dob.toIso8601String(),
      "age": age,
    });
  }




  Future<void> _selectDob() async {
    final now = DateTime.now();
    final initialDate = DateTime(now.year - 18);
    final firstDate = DateTime(1900);
    final lastDate = now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.amber,
            onPrimary: Colors.black,
            surface: Colors.black,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() => _selectedDob = picked);
    }
  }

  Future<void> _signUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || _selectedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);
      await registerUser(email, password, name);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RoutineCheckScreen(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration failed: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final formattedDob = _selectedDob != null ? DateFormat('dd MMM yyyy').format(_selectedDob!) : "Select Date of Birth";


    return Scaffold(
      backgroundColor: Colors.black54,
      appBar: AppBar(
        title: const Text("Create Account", style: TextStyle(color: Colors.amber)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.amber),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  labelStyle: TextStyle(color: Colors.white70),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.amber),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _selectDob,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.centerLeft,
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.amber)),
                  ),
                  child: Text(
                    formattedDob,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Email",
                  labelStyle: TextStyle(color: Colors.white70),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.amber),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Password",
                  labelStyle: TextStyle(color: Colors.white70),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.amber),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? const CircularProgressIndicator(color: Colors.amber)
                  : ElevatedButton(
                onPressed: _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                ),
                child: const Text("Sign Up", style: TextStyle(fontSize: 16),),
              ),
            ],
          ),
        ),
      ),
    );
  }
}