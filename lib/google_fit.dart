import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class GoogleFitScreen extends StatefulWidget {
  @override
  _GoogleFitScreenState createState() => _GoogleFitScreenState();
}

class _GoogleFitScreenState extends State<GoogleFitScreen> {
  // Use Health() instead of HealthFactory()
  final Health _health = Health();

  int _steps = 0;

  Future<void> checkPermissions() async {
    // Request required permissions for Android 10+
    if (await Permission.activityRecognition.isDenied) {
      await Permission.activityRecognition.request();
    }
    if (await Permission.sensors.isDenied) {
      await Permission.sensors.request();
    }
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await checkPermissions(); // Wait until permissions are granted
    await fetchStepData();    // Then fetch steps
  }

  Future<void> fetchStepData() async {
    final types = [HealthDataType.STEPS];
    final permissions = [HealthDataAccess.READ];

    // Request authorization with types and permissions
    bool requested = await _health.requestAuthorization(types, permissions: permissions);

    if (requested) {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      try {
        List<HealthDataPoint> healthData =
        await _health.getHealthDataFromTypes(
          startTime: yesterday,
          endTime: now,
          types: types,
        );

        int totalSteps = healthData.fold(0, (sum, dp) {
          if (dp.type == HealthDataType.STEPS && dp.value is int) {
            return sum + (dp.value as int);
          }
          return sum;
        });

        setState(() {
          _steps = totalSteps;
        });
      } catch (e) {
        print("Error fetching health data: $e");
      }
    } else {
      print("Authorization not granted");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Google Fit Steps')),
      body: Center(
        child: Text('Steps in last 24h: $_steps'),
      ),
    );
  }
}
