import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:internship/login_screen.dart';

final colorScheme=ColorScheme.dark(
  primary:Colors.amber,
  secondary: Colors.amberAccent,
);
final theme= ThemeData().copyWith(
    scaffoldBackgroundColor: Colors.black,
    colorScheme: colorScheme,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.amber),
      bodyMedium: TextStyle(color:Colors.amber),
    ),
  );


void main() async {
  WidgetsFlutterBinding.ensureInitialized();  // Make sure bindings are initialized first
  await Firebase.initializeApp();// Initialize Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget{
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: theme,
        home:LoginScreen(),
    );
  }
}