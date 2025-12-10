// --- Code to Paste (restaurant_login_screen.dart) ---
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import the restaurant's main screen
import 'restaurant_dashboard_screen.dart';

class RestaurantLoginScreen extends StatefulWidget {
  const RestaurantLoginScreen({super.key});

  @override
  State<RestaurantLoginScreen> createState() => _RestaurantLoginScreenState();
}

class _RestaurantLoginScreenState extends State<RestaurantLoginScreen> {
  final _auth = FirebaseAuth.instance;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists || userDoc.data() == null) {
        throw Exception("User profile not found. Contact Admin.");
      }

      final role = userDoc.data()!['role'] as String;

      // Normalize role to uppercase to prevent case-sensitivity errors (RESTAURANT vs restaurant)
      final normalizedRole = role.toUpperCase();

      // 1. Success: Check for the 'RESTAURANT' role and navigate
      if (normalizedRole == 'RESTAURANT') {
        // Fix 3: Check if the widget is still mounted before navigating
        if (!context.mounted) return;

        // Navigation must use the corrected (non-const) screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => RestaurantDashboardScreen()),
        );
      }
      // 2. Deny: If the user has a role meant for a DIFFERENT app
      else if (normalizedRole == 'CUSTOMER') {
        await _auth.signOut();
        throw Exception("Access Denied. Please use the Customer App.");
      }
      else if (normalizedRole == 'DRIVER') {
        await _auth.signOut();
        throw Exception("Access Denied. Please use the Driver App.");
      }
      // 3. Deny: If the user has an unrecognized/undefined role
      else {
        await _auth.signOut();
        throw Exception("Access Denied. Invalid user role: $role.");
      }

    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Authentication Failed';
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restaurant Login')),
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
                  decoration: const InputDecoration(labelText: 'Restaurant Email'),
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
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: const Text('Restaurant Log In', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}