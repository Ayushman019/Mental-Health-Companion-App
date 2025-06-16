import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
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
      final uid = userCred.user!.uid;
      await saveUserProfile(
        uid: uid,
        name: name,
        email: email,
        dob: _selectedDob!,
        age: _calculatedAge!,
      );
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
      databaseURL:
      'https://moodtracker-74086-default-rtdb.asia-southeast1.firebasedatabase.app/',
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
    final formattedDob = _selectedDob != null
        ? DateFormat('dd MMM yyyy').format(_selectedDob!)
        : "Select Date of Birth";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sign Up to Mindly", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Image
          SizedBox.expand(
            child: Image.asset(
              'assets/LandingPage.png',
              fit: BoxFit.cover,
            ),
          ),

          // Darker overlay for better readability
          Container(
            color: Colors.black.withOpacity(0.5),
          ),

          // Form Content
          SingleChildScrollView(
            padding: const EdgeInsets.only(top: 200, left: 24, right: 24, bottom: 24),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Full Name
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: "Full Name",
                        border: UnderlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // DOB
                    GestureDetector(
                      onTap: _selectDob,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey)),
                        ),
                        child: Text(
                          formattedDob,
                          style: const TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Email
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        border: UnderlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Password
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "Password",
                        border: UnderlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Create Account Button
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                      onPressed: _signUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white24,
                        foregroundColor: Colors.amber,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Create Account", style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
