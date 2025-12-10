// --- Corrected Code for login_screen.dart ---
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'live_tracking_screen.dart'; // Import the corrected screen

// 1. Define the StatefulWidget class
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// 2. Define the State class (where logic resides)
class _LoginScreenState extends State<LoginScreen> {
  // 🎯 FIX: Remove unused warnings by making fields final or private
  final _auth = FirebaseAuth.instance;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;

  // 3. Define the async login function
  Future<void> _login() async {
    // Start Loading State
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Authenticate the User
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Fetch User Role for Role-Based Navigation
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists || userDoc.data() == null) {
        throw Exception("User profile not found. Please contact support.");
      }

      final role = userDoc.data()!['role'] as String;

      // Navigation Logic
      if (role == 'CUSTOMER') {
        // 🎯 FIX: Navigation must use the corrected (non-const) screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LiveTrackingScreen()),
        );
      } else {
        await _auth.signOut();
        throw Exception("Access Denied. Please use the correct application for your role.");
      }

    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Authentication Failed';
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      // Stop Loading State
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 4. Define the mandatory 'build' method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Login')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                const SizedBox(height: 24),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                  ),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _login, // Correctly references the _login method
                  child: const Text('Log In'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}