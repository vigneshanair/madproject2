// --- Code to Paste (food_runner_driver/lib/driver_dashboard_screen.dart) ---
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart'; // <-- Added Geolocation

// Placeholder for the currently assigned order ID (should be set after optimization)
const String kActiveOrderId = 'test_order_124';
const String kDriverId = 'test_driver_1'; // Placeholder driver ID

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  bool _isAvailable = false;
  String _currentOrderStatus = 'Waiting for assignment...';
  StreamSubscription<Position>? _positionStreamSubscription;
  final _auth = FirebaseAuth.instance;

  // --- LOCATION STREAMING LOGIC ---

  Future<void> _checkPermissionAndService() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are permanently denied.');
      }
    }
  }

  void _startLocationStream() async {
    try {
      await _checkPermissionAndService();

      // Configure the stream for continuous, high-accuracy updates
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      );

      _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
          .listen((Position position) {
        // 1. Convert Position to Firestore GeoPoint
        final driverLocation = GeoPoint(position.latitude, position.longitude);

        // 2. Update Firestore document (This is what the customer app reads!)
        FirebaseFirestore.instance
            .collection('orders')
            .doc(kActiveOrderId)
            .update({
          'driverLocation': driverLocation,
          // Optional: Update the driver's location in a separate drivers collection
          // 'lastLocation': driverLocation,
        })
            .catchError((error) => debugPrint("Failed to update driver location: $error"));
      });
      debugPrint('Driver is now AVAILABLE. Location stream STARTED.');

    } catch (e) {
      debugPrint('Location error: $e');
      setState(() {
        _isAvailable = false;
      });
      // Optionally show a SnackBar error to the driver
    }
  }

  void _stopLocationStream() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    debugPrint('Driver is now OFFLINE. Location stream STOPPED.');
  }

  // --- UI/STATE LOGIC ---

  void _toggleAvailability(bool newValue) {
    setState(() {
      _isAvailable = newValue;
    });

    if (newValue) {
      _startLocationStream();
    } else {
      _stopLocationStream();
    }
  }

  void _completeRouteStop(String newStatus) {
    // 1. Update order status in Firestore (This will trigger customer app change)
    FirebaseFirestore.instance
        .collection('orders')
        .doc(kActiveOrderId)
        .update({
      'orderStatus': newStatus,
    })
        .then((_) => debugPrint('Order status updated to $newStatus'))
        .catchError((error) => debugPrint("Failed to update status: $error"));

    setState(() {
      _currentOrderStatus = 'Route stop confirmed: $newStatus. Recalculating...';
    });
  }

  @override
  void dispose() {
    _stopLocationStream();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // NOTE: You will need to replace the placeholders below with the actual implementation
  // from your UI/business logic. This example uses simple placeholders.
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // --- WIDGET BUILD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Operations'),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _stopLocationStream();
              _auth.signOut();
              // TODO: Navigate to Login Screen
            },
          )
        ],
      ),
      body: Column(
        children: [
          // 1. Availability Status Toggle
          Container(
            padding: const EdgeInsets.all(16.0),
            color: _isAvailable ? Colors.green[100] : Colors.red[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isAvailable ? 'STATUS: ONLINE (Streaming Location)' : 'STATUS: OFFLINE',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _isAvailable ? Colors.green[800] : Colors.red[800]),
                ),
                Switch(
                  value: _isAvailable,
                  onChanged: _toggleAvailability,
                  activeColor: Colors.green,
                ),
              ],
            ),
          ),

          // 2. Active Route Display / Status
          Expanded(
            child: Container(
              color: Colors.grey[200],
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Active Order ID: $kActiveOrderId\n\n'
                        'Current Assignment Status: $_currentOrderStatus\n\n'
                        'Driver Location is being sent to Firestore: $_isAvailable',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.blueGrey[800]),
                  ),
                ),
              ),
            ),
          ),

          // 3. Pickup/Delivery Confirmation
          if (_isAvailable)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.store),
                    label: const Text('Picked Up'),
                    onPressed: () => _completeRouteStop('OUT_FOR_DELIVERY'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Delivered'),
                    onPressed: () => _completeRouteStop('DELIVERED'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}