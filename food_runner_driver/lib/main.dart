// --- Code to Paste (food_runner_driver/lib/main.dart) ---
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Import the driver login screen
import 'driver_login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Uses the SAME Firebase initialization settings as the other two apps
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Runner Driver',
      // Starts with the Driver-specific login screen
      home: const DriverLoginScreen(),
    );
  }
}