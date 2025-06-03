import 'package:flutter/material.dart';
import 'package:health/health.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Health health = Health();
  String status = "Checking...";

  @override
  void initState() {
    super.initState();
    checkHealthPermission();
  }

  Future<void> checkHealthPermission() async {
    await health.configure(); // Required setup for v11.0.0

    bool granted = await health.requestAuthorization([HealthDataType.STEPS]);

    setState(() {
      status = granted ? "Permission Granted 👍" : "Permission Denied 👎";
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Health Plugin Test')),
        body: Center(child: Text(status)),
      ),
    );
  }
}
