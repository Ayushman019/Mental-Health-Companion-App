import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

// Mood reference under: Mood_List/<uid>/moods
DatabaseReference get moodDbRef {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw FirebaseAuthException(
      code: 'no-user',
      message: 'No user currently signed in.',
    );
  }

  return FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://moodtracker-74086-default-rtdb.asia-southeast1.firebasedatabase.app/',
  ).ref().child("Mood_List").child(user.uid).child("moods");
}

// Routine reference under: Mood_List/<uid>/routines
DatabaseReference get routineDbRef {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw FirebaseAuthException(
      code: 'no-user',
      message: 'No user currently signed in.',
    );
  }

  return FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://moodtracker-74086-default-rtdb.asia-southeast1.firebasedatabase.app/',
  ).ref().child("Mood_List").child(user.uid).child("routines");
}

// ==========================
// 👇 STREAK: Mood_List/<uid>/streak
// ==========================

DatabaseReference get streakDbRef {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw FirebaseAuthException(
      code: 'no-user',
      message: 'No user currently signed in.',
    );
  }

  return FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://moodtracker-74086-default-rtdb.asia-southeast1.firebasedatabase.app/',
  ).ref().child("Mood_List").child(user.uid).child("streak");
}

// Fetch current streak
Future<Map<String, dynamic>> fetchStreak() async {
  final snapshot = await streakDbRef.get();
  if (!snapshot.exists) return {"count": 0, "lastUpdated": ""};

  final value = snapshot.value;
  if (value is Map<Object?, Object?>) {
    final map = Map<String, dynamic>.from(
      value.map((key, value) => MapEntry(key.toString(), value)),
    );
    return {
      "count": (map['count'] as num?)?.toInt() ?? 0,
      "lastUpdated": map['lastUpdated'] ?? ""
    };
  }

  return {"count": 0, "lastUpdated": ""}; // fallback
}
// Update streak with new count and last updated date
Future<void> updateStreak({required int count, required String lastUpdated}) async {
  await streakDbRef.set({
    'count': count,
    'lastUpdated': lastUpdated,
  });
}

// ==========================
// 👤 Save user profile
// ==========================

Future<void> saveUserProfile({required String name, required int age}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw FirebaseAuthException(code: 'no-user', message: 'No user signed in.');
  }

  final userRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://moodtracker-74086-default-rtdb.asia-southeast1.firebasedatabase.app/',
  ).ref("users/${user.uid}");

  await userRef.set({
    "name": name,
    "email": user.email,
    "age": age,
  });
}

