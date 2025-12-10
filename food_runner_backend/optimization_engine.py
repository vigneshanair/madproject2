# --- Code to Paste (optimization_engine.py) ---
from flask import Flask, request, jsonify
from ortools.constraint_solver import routing_enums_pb2
from ortools.constraint_solver import pywrapcp
import math

app = Flask(__name__)

# --- 1. CONFIGURATION (Empirical Weights for Optimization) ---
W1_TIME = 0.5   
W2_EARNINGS = 0.4 
W3_FAIRNESS = 0.1 

# --- 2. DYNAMIC COST FUNCTION (C_total) ---
def calculate_dynamic_cost(
    start_loc, end_loc, T_prep, 
    traffic_factor=1.5,
    weather_factor=0.2, 
    priority_weight=0.1
):
    """
    C_total = C_traffic * (1 + W_weather + W_priority) + T_prep
    """
    C_base_time = 10 

    C_traffic = C_base_time * traffic_factor
    
    weighted_penalty = 1 + weather_factor + priority_weight
    
    C_total = (C_traffic * weighted_penalty) + T_prep
    return C_total

# --- 3. COMPOSITE FITNESS FUNCTION (F) ---
def calculate_composite_fitness(T_total, E_normalized, D_fairness):
    """
    F = w1 * (1/T_total) + w2 * E_normalized - w3 * D_fairness
    """
    objective_time = 1.0 / T_total

    F_score = (W1_TIME * objective_time) + \
              (W2_EARNINGS * E_normalized) - \
              (W3_FAIRNESS * D_fairness)
              
    return F_score

# --- 4. OPTIMIZATION API ENDPOINT ---
@app.route('/optimize', methods=['POST'])
def optimize_assignment():
    data = request.json
    
    T_total_example = 30.0 
    E_normalized_example = 0.95 
    D_fairness_example = 0.15 
    T_prep_example = 5.0 

    cost_time = calculate_dynamic_cost(
        start_loc='R1', 
        end_loc='C1', 
        T_prep=T_prep_example
    )

    final_fitness_score = calculate_composite_fitness(
        T_total_example, 
        E_normalized_example, 
        D_fairness_example
    )

    return jsonify({
        "status": "Optimization Complete",
        "orderId": data.get('orderId'),
        "optimalDriverId": "driver_X1",
        "compositeFitnessScore": final_fitness_score,
        "estimatedTimeOfArrival": T_total_example + cost_time,
        "dynamicCostTime": cost_time
    })

if __name__ == '__main__':
    print("Starting Optimization Engine on port 5000...")
    app.run(debug=True, port=5000)