// --- Code to Paste (food_runner_backend/functions/index.js) ---
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios'); // HTTP client for calling the Optimization Engine

admin.initializeApp();
const db = admin.firestore();

// 🎯 Optimization Engine's Local URL (Running in your Python terminal)
const OPTIMIZATION_ENGINE_URL = 'http://127.0.0.1:5000/optimize'; 

// --- Trigger: Manual Optimization Trigger (HTTPS Callable) ---
// This function is called directly by the Restaurant App when the order is "Ready!"
exports.manualOptimizationTrigger = functions.https.onCall(async (data, context) => {
    
    // 1. Authentication Check (Crucial for security)
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'The function must be called while authenticated.');
    }
    
    const { orderId, type } = data; // Expecting orderId and the optimization type

    console.log(`[HTTPS TRIGGER] Received request for Order ${orderId}, Type: ${type} by user: ${context.auth.uid}`);

    // 2. Fetch necessary data from Firestore
    const orderDoc = await db.collection('orders').doc(orderId).get();
    if (!orderDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Order not found.');
    }
    const orderData = orderDoc.data();

    // 3. Prepare payload and call the external Python Optimization Engine
    const optimizationPayload = {
        orderId: orderId,
        type: type,
        data: orderData
    };

    try {
        const response = await axios.post(OPTIMIZATION_ENGINE_URL, optimizationPayload);
        const result = response.data;
        
        // 4. Update Firestore with the Optimizer's result
        await db.collection('orders').doc(orderId).update({
            driverId: result.optimalDriverId,
            estimatedTimeOfArrival: result.estimatedTimeOfArrival,
            // Only update status to ASSIGNED if it's the initial call
            orderStatus: type === 'INITIAL_ASSIGNMENT' ? 'ASSIGNED' : orderData.orderStatus 
        });
        
        return { success: true, message: "Optimization complete.", driverId: result.optimalDriverId };
    } catch (error) {
        console.error('Optimizer call failed:', error.message);
        throw new functions.https.HttpsError('internal', `Optimization engine failed to respond. Error: ${error.message}`);
    }
});