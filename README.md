# Food Runner Delivery Optimization System

This repository contains the complete codebase for a real-time food delivery ecosystem. It demonstrates multi-user synchronization, serverless functions, and a sophisticated Vehicle Routing Problem (VRP) optimization backend (your Master's component).

The system consists of three mobile applications (Customer, Restaurant, Driver) built with Flutter, integrated with Google Firebase and a custom Python/Flask microservice for delivery route optimization.

---

## 🛠️ 1. System Components and Architecture

The entire system is connected through real-time communication via Firestore, with the Cloud Function acting as the crucial middleware.

| Component | Technology | Role |
| :--- | :--- | :--- |
| **Mobile Apps (3)** | Flutter / Dart | Real-time user interfaces for each user role. |
| **Database** | Firebase Firestore | Stores all order data, user profiles, and real-time location. |
| **Serverless Function** | Firebase Cloud Functions (Node.js) | Acts as the API Gateway, receiving the "Ready!" trigger and calling the Python service. |
| **Optimization Engine** | Python / Flask | Calculates optimal driver assignment and estimated time of arrival (ETA) using VRP/TSP logic. |

---

## ⚙️ 2. Setup and Installation

### Prerequisites

You must have the following installed locally:

1.  **Flutter SDK** (v3.19+)
2.  **Node.js & npm** (LTS version)
3.  **Python 3.x**
4.  **Firebase CLI** (`npm install -g firebase-tools`)
5.  **A Firebase Project** with **Firestore** and **Authentication** enabled.

### A. Backend Setup (Run First)

The backend requires two separate terminals running simultaneously.

1.  **Install Dependencies:**
    Navigate to the `food_runner_backend` directory and install both Node.js and Python dependencies:

    ```bash
    # Node.js Dependencies (for Cloud Functions)
    cd food_runner_backend/functions
    npm install
    
    # Python Dependencies (for Optimization Engine)
    cd ../ 
    python -m venv venv
    .\venv\Scripts\activate  # <-- Use this on Windows Command Prompt
    # source venv/bin/activate # <-- Use this on macOS/Linux/Git Bash
    pip install Flask requests
    ```

2.  **Start the Emulators and Server (Requires two terminals):**

    * **Terminal 1 (Python Server):**
        ```bash
        # Ensure you are inside the main backend folder with venv activated
        python optimization_engine.py 
        # Expected output: * Running on [http://127.0.0.1:5000](http://127.0.0.1:5000)
        ```

    * **Terminal 2 (Functions Emulator):**
        ```bash
        # Ensure the Python server is running before this step
        firebase emulators:start --only functions,firestore,auth
        ```

### B. Mobile App Setup

1.  **Configuration Files:** Place your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) files into the respective project folders for **all three apps**.
2.  **Install App Dependencies:** Run this command in the root folder of *each* app project:
    ```bash
    flutter pub get
    ```

---

## 3. 🧪 Testing and Usage

The system is tested using three separate emulators/devices running simultaneously.

### Test Accounts

Please use the following accounts (must be created in your Firebase Authentication console):

| Role | Email | Password |
| :--- | :--- | :--- |
| **Customer** | `customer@test.com` | `password` |
| **Restaurant** | `restaurant@test.com` | `password` |
| **Driver** | `driver@test.com` | `password` |

### End-to-End Test Sequence

1.  **Launch All Apps:** Run all three apps and log in with the corresponding user.
2.  **Start Driver Stream:** In the **Driver App**, toggle the status switch to **"ONLINE"** to begin broadcasting its location.
3.  **TRIGGER OPTIMIZATION:** In the **Restaurant App**, click the **"Ready!"** button on the active order.
    * This calls the Cloud Function, which calls your Python server.
4.  **Verification:**
    * **All Apps:** The status instantly updates to **ASSIGNED**, and the **Driver ID** and **Optimized ETA** appear.
5.  **Verify Real-Time Tracking:** In the **Driver's emulator**, use the Extended Controls $\rightarrow$ Location tab to simulate movement. The **Customer App** should immediately display the changing coordinates.
6.  **Final Status Update:** In the **Driver App**, click **"Picked Up"** (status changes to `OUT_FOR_DELIVERY`) and then **"Delivered"** (status changes to `DELIVERED`). All apps synchronize instantly.

---

## 📂 4. Repository Structure

* `food_runner_customer/`: Flutter code for the customer application.
* `food_runner_restaurant/`: Flutter code for the restaurant application.
* `food_runner_driver/`: Flutter code for the driver application.
* `food_runner_backend/`: Contains the microservice and function code:
    * `functions/`: Node.js Cloud Function code (`index.js`).
    * `optimization_engine.py`: Flask application for VRP/TSP calculation.
* `.gitignore`: Ensures files like `node_modules`, `venv`, and `build` are excluded.
