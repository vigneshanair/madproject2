// --- Code to Paste (food_runner_restaurant/lib/main.dart) ---
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Import the restaurant login screen
import 'restaurant_login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Note: This uses the SAME Firebase initialization settings as the Customer App
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
      title: 'Food Runner Restaurant',
      // Starts with the Restaurant-specific login screen
      home: const RestaurantLoginScreen(),
    );
  }
}