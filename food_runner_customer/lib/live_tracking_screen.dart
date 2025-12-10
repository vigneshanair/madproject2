// --- Code to Paste (live_tracking_screen.dart) ---
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Renamed constant for style guide compliance
const String kTrackingOrderId = 'test_order_123';

// Removed 'const' because customerId is a runtime value
class LiveTrackingScreen extends StatelessWidget {
  LiveTrackingScreen({super.key});

  final String? customerId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (customerId == null) {
      return const Scaffold(body: Center(child: Text('Error: Customer not logged in.')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Live Order Tracking')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').doc(kTrackingOrderId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Order not found or delivered.'));
          }

          final orderData = snapshot.data!.data() as Map<String, dynamic>;
          final orderStatus = orderData['orderStatus'] as String? ?? 'PLACED';
          final driverId = orderData['driverId'] as String? ?? 'Finding Driver...';
          final eta = orderData['estimatedTimeOfArrival'] as String? ?? 'Calculating...';
          final GeoPoint? driverLocation = orderData['driverLocation'] as GeoPoint?;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Order Status: $orderStatus',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Driver ID: $driverId'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Optimized ETA: $eta'),
              ),
              Expanded(
                child: Center(
                  // Display real-time driver coordinates if available
                  child: driverLocation != null
                      ? Text('Driver Location (Real-Time):\nLat ${driverLocation.latitude.toStringAsFixed(4)}\nLon ${driverLocation.longitude.toStringAsFixed(4)}')
                      : const Text('Awaiting driver assignment/location stream.'),
                ),
              ),
              if (orderStatus == 'ASSIGNED' || orderStatus == 'READY_FOR_PICKUP')
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: LinearProgressIndicator(value: 0.8, color: Colors.deepOrange),
                ),
            ],
          );
        },
      ),
    );
  }
}