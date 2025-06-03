import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:internship/sign_up_Screen.dart';
import 'package:internship/routine_DailYLogsDecider.dart';
class LoginScreen extends StatefulWidget {
  LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signInWithEmail() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Email and password cannot be empty")),
      );
      return;
    }
    try {
      setState(() => _isLoading = true);
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>RoutineCheckScreen(),
        ),
      );
    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Login Failed')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signUpWithEmail() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Email and password cannot be empty")),
      );
      return;
    }
    try {
      setState(() => _isLoading = true);
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RoutineCheckScreen(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Sign up failed')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Google Authentication Failed")),
        );
        return;
      }
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken!,
        idToken: googleAuth.idToken!,
      );
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RoutineCheckScreen(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google Sign-in Failed")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 50),
                  Text(
                    "WELCOME TO MINDLY",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Track Your Mood and Understand Yourself Better!",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
              Column(
                children: [
                  TextField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      label: Text("Email"),
                      labelStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white38),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.amber),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      label: Text("Password"),
                      labelStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white38),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.amber),
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  _isLoading
                      ? CircularProgressIndicator(color: Colors.amber)
                      : ElevatedButton(
                    onPressed: _signInWithEmail,
                    child: const Text("Sign In with Email"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _isLoading
                      ? const SizedBox()
                      : OutlinedButton.icon(
                    onPressed: _signInWithGoogle,
                    icon: Image.asset(
                      'assets/google.png',
                      height: 20,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.error, color: Colors.red);
                      },
                    ),
                    label: const Text("Sign in with Google"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _isLoading
                      ? const SizedBox()
                      : TextButton(
                    onPressed:(){
                      Navigator.push(context, MaterialPageRoute(builder:(context)=>const SignUpScreen()));
                    },
                    child: const Text(
                      "Don't have an account? Sign Up",
                      style: TextStyle(color: Colors.amber),

                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
