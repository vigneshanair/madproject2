// --- Code to Paste (food_runner_restaurant/lib/restaurant_dashboard_screen.dart) ---
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

// Renamed constant for style guide compliance
const String kRestaurantId = 'test_restaurant_1';

// Removed 'const' because managerUid is a runtime value
class RestaurantDashboardScreen extends StatelessWidget {
  RestaurantDashboardScreen({super.key});

  final String? managerUid = FirebaseAuth.instance.currentUser?.uid;

  // --- FUNCTION TO UPDATE ORDER STATUS AND TRIGGER OPTIMIZATION ---
  Future<void> _updateOrderStatus(BuildContext context, String orderId, String newStatus) async {
    // Check if the widget is still mounted before accessing context
    if (!context.mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      // 1. Update status in Firestore
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'orderStatus': newStatus,
      });

      // 2. If READY_FOR_PICKUP, call the HTTPS function to trigger optimization
      if (newStatus == 'READY_FOR_PICKUP') {
        final callable = FirebaseFunctions.instance.httpsCallable('manualOptimizationTrigger');

        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Triggering Optimization Engine...')),
        );

        final result = await callable.call({
          'orderId': orderId,
          'type': 'FINAL_ROUTE_CALCULATION',
        });

        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Optimization Success! Driver: ${result.data['driverId']}')),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      debugPrint('Error updating status or calling optimizer: $e');
    }
  }
  // --- END FUNCTION ---

  Widget _buildOrderCard(BuildContext context, String orderId, Map<String, dynamic> order) {
    final status = order['orderStatus'] ?? 'UNKNOWN';

    Color getColor(String s) {
      switch (s) {
        case 'PLACED': return Colors.blue;
        case 'PREPARING': return Colors.orange;
        case 'READY_FOR_PICKUP': return Colors.green;
        case 'ASSIGNED': return Colors.purple;
        default: return Colors.grey;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: getColor(status),
          child: Text(status[0], style: const TextStyle(color: Colors.white)),
        ),
        title: Text('Order ID: $orderId'),
        subtitle: Text('Status: $status | ETA: ${order['estimatedTimeOfArrival'] ?? 'TBD'}'),
        trailing: Wrap(
          spacing: 8.0,
          children: [
            if (status == 'PLACED')
              ElevatedButton(
                onPressed: () => _updateOrderStatus(context, orderId, 'PREPARING'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Start Prep'),
              ),
            if (status == 'PREPARING')
              ElevatedButton(
                onPressed: () => _updateOrderStatus(context, orderId, 'READY_FOR_PICKUP'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Ready!'), // <-- Triggers Optimization Engine
              ),
            if (status == 'READY_FOR_PICKUP' || status == 'ASSIGNED')
              const Text('Awaiting/Assigned Driver', style: TextStyle(color: Colors.purple)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (managerUid == null) {
      return const Scaffold(body: Center(child: Text('Error: Manager not logged in.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Order Queue'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Live Orders',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('restaurantId', isEqualTo: kRestaurantId)
                  .where('orderStatus', whereIn: ['PLACED', 'PREPARING', 'READY_FOR_PICKUP', 'ASSIGNED'])
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  // If the index is missing, the error often prints here
                  return Center(child: Text('Error loading orders: ${snapshot.error.toString()}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No active orders right now.'));
                }

                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    final orderData = doc.data() as Map<String, dynamic>;
                    return _buildOrderCard(context, doc.id, orderData);
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}