// --- Code for lib/main.dart ---
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
// 🎯 FIX: This line resolves 'LoginScreen' isn't defined for MyApp
import 'login_screen.dart';

// WARNING FIX: Removed the unused import: 'package:cloud_firestore/cloud_firestore.dart'.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      title: 'Food Runner Customer',
      home: const LoginScreen(),
    );
  }
}