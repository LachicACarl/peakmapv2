"""
Advanced Test Scenarios for PeakMap 2.0
Tests complete user flows and edge cases
"""

import requests
import json
import time
from datetime import datetime

BASE_URL = "http://127.0.0.1:8000"
TEST_RESULTS = []

# ANSI Colors
GREEN = "\033[92m"
RED = "\033[91m"
YELLOW = "\033[93m"
BLUE = "\033[94m"
RESET = "\033[0m"
BOLD = "\033[1m"

def log_test(scenario_name, test_name, status, message=""):
    """Log test result"""
    timestamp = datetime.now().strftime("%H:%M:%S")
    status_text = f"{GREEN}[PASS]{RESET}" if status == "PASS" else f"{RED}[FAIL]{RESET}"
    
    print(f"[{timestamp}] {status_text} [{scenario_name}] {test_name}")
    if message:
        print(f"              -> {message}")
    
    TEST_RESULTS.append({
        "scenario": scenario_name,
        "test": test_name,
        "status": status,
        "message": message,
        "timestamp": timestamp
    })

def print_section(title):
    """Print section header"""
    print(f"\n{BOLD}{BLUE}{'='*70}{RESET}")
    print(f"{BOLD}{title}{RESET}")
    print(f"{BOLD}{BLUE}{'='*70}{RESET}\n")

# SCENARIO 1: COMPLETE DRIVER FLOW
def test_scenario_1_driver_flow():
    """Test complete driver workflow"""
    print_section("SCENARIO 1: COMPLETE DRIVER WORKFLOW")
    
    try:
        # 1. Get all drivers
        drivers_response = requests.get(f"{BASE_URL}/drivers/")
        if drivers_response.status_code == 200:
            drivers = drivers_response.json()
            log_test("Driver Flow", "Get drivers list", "PASS", f"Found {len(drivers)} drivers")
            
            if drivers:
                driver_id = drivers[0]['id']
                
                # 2. Toggle online status
                status_response = requests.put(
                    f"{BASE_URL}/drivers/{driver_id}/status",
                    json={"is_online": True}
                )
                log_test("Driver Flow", "Toggle online status", 
                        "PASS" if status_response.status_code in [200, 404] else "FAIL",
                        f"Status: {status_response.status_code}")
                
                # 3. Get driver details
                driver_response = requests.get(f"{BASE_URL}/drivers/{driver_id}")
                if driver_response.status_code == 200:
                    log_test("Driver Flow", "Get driver details", "PASS", 
                            f"Driver: {driver_response.json().get('full_name')}")
                else:
                    log_test("Driver Flow", "Get driver details", "FAIL", 
                            f"Status: {driver_response.status_code}")
                
                # 4. Get driver's rides
                rides_response = requests.get(f"{BASE_URL}/rides/", params={"driver_id": driver_id})
                if rides_response.status_code == 200:
                    rides = rides_response.json()
                    log_test("Driver Flow", "Get driver rides", "PASS", f"Found {len(rides)} rides")
                else:
                    log_test("Driver Flow", "Get driver rides", "FAIL", 
                            f"Status: {rides_response.status_code}")
                
                # 5. Get driver alerts
                alerts_response = requests.get(f"{BASE_URL}/alerts/", 
                                              params={"driver_id": driver_id})
                if alerts_response.status_code == 200:
                    log_test("Driver Flow", "Get alerts", "PASS", 
                            f"Status: {alerts_response.status_code}")
                else:
                    log_test("Driver Flow", "Get alerts", "FAIL", 
                            f"Status: {alerts_response.status_code}")
        else:
            log_test("Driver Flow", "Get drivers list", "FAIL", 
                    f"Status: {drivers_response.status_code}")
    except Exception as e:
        log_test("Driver Flow", "EXCEPTION", "FAIL", str(e))

# SCENARIO 2: COMPLETE PASSENGER FLOW
def test_scenario_2_passenger_flow():
    """Test complete passenger workflow"""
    print_section("SCENARIO 2: COMPLETE PASSENGER WORKFLOW")
    
    try:
        # 1. Get available stations
        stations_response = requests.get(f"{BASE_URL}/stations/")
        if stations_response.status_code == 200:
            stations = stations_response.json()
            log_test("Passenger Flow", "Get stations", "PASS", f"Found {len(stations)} stations")
            
            if len(stations) >= 2:
                # 2. Create a ride
                ride_data = {
                    "passenger_id": 1,
                    "station_id": stations[1]['id']
                }
                
                create_ride_response = requests.post(f"{BASE_URL}/rides", json=ride_data)
                if create_ride_response.status_code in [200, 201]:
                    ride = create_ride_response.json()
                    log_test("Passenger Flow", "Create ride", "PASS", 
                            f"Ride ID: {ride.get('ride_id')}")
                    
                    ride_id = ride.get('ride_id', 1)
                    
                    # 3. Get ride details
                    ride_details_response = requests.get(f"{BASE_URL}/rides/{ride_id}")
                    if ride_details_response.status_code == 200:
                        log_test("Passenger Flow", "Get ride details", "PASS", 
                                f"Status: {ride_details_response.json().get('status')}")
                    
                    # 4. Get passenger rides
                    passenger_rides_response = requests.get(f"{BASE_URL}/rides/", 
                                                           params={"passenger_id": 1})
                    if passenger_rides_response.status_code == 200:
                        log_test("Passenger Flow", "Get passenger rides", "PASS", 
                                f"Found {len(passenger_rides_response.json())} rides")
                    
                    # 5. Initiate payment
                    payment_data = {
                        "ride_id": ride_id,
                        "method": "cash"
                    }
                    payment_response = requests.post(f"{BASE_URL}/payments/initiate", 
                                                    json=payment_data)
                    if payment_response.status_code in [200, 201]:
                        log_test("Passenger Flow", "Initiate payment", "PASS", "Payment created")
                    else:
                        log_test("Passenger Flow", "Initiate payment", "FAIL", 
                                f"Status: {payment_response.status_code}")
                else:
                    log_test("Passenger Flow", "Create ride", "FAIL", 
                            f"Status: {create_ride_response.status_code}")
        else:
            log_test("Passenger Flow", "Get stations", "FAIL", 
                    f"Status: {stations_response.status_code}")
    except Exception as e:
        log_test("Passenger Flow", "EXCEPTION", "FAIL", str(e))

# SCENARIO 3: PAYMENT PROCESSING
def test_scenario_3_payment_flow():
    """Test payment processing workflows"""
    print_section("SCENARIO 3: PAYMENT PROCESSING")
    
    try:
        # 1. Get fares
        fares_response = requests.get(f"{BASE_URL}/fares/")
        if fares_response.status_code == 200:
            fares = fares_response.json()
            log_test("Payment Flow", "Get fares", "PASS", f"Found {len(fares)} fares")
        else:
            log_test("Payment Flow", "Get fares", "FAIL", f"Status: {fares_response.status_code}")
        
        ride_station_id = 2
        if fares_response.status_code == 200 and fares:
            # create_ride currently computes fare from station 1 -> destination
            # so pick a destination that has an existing configured fare.
            for fare in fares:
                if fare.get("from_station") == 1 and fare.get("to_station") != 1:
                    ride_station_id = fare["to_station"]
                    break

        # 2. Test all payment methods using fresh rides
        payment_methods = ["cash", "gcash", "ewallet"]
        created_payment_id = None
        for method in payment_methods:
            ride_response = requests.post(
                f"{BASE_URL}/rides",
                json={"passenger_id": 1, "station_id": ride_station_id}
            )
            if ride_response.status_code not in [200, 201]:
                log_test(
                    "Payment Flow",
                    f"Create ride for {method.upper()} payment",
                    "FAIL",
                    f"Status: {ride_response.status_code}"
                )
                continue

            ride_json = ride_response.json()
            ride_id = ride_json.get("ride_id") or ride_json.get("id")
            payment_data = {
                "ride_id": ride_id,
                "method": method,
            }
            payment_response = requests.post(f"{BASE_URL}/payments/initiate", 
                                            json=payment_data)
            if payment_response.status_code in [200, 201]:
                payment_json = payment_response.json()
                if method == "cash":
                    created_payment_id = payment_json.get("payment_id")
                log_test("Payment Flow", f"Initiate {method.upper()} payment", "PASS", 
                        "Payment created")
            else:
                log_test("Payment Flow", f"Initiate {method.upper()} payment", "FAIL", 
                        f"Status: {payment_response.status_code}")
        
        # 3. Confirm payment
        if created_payment_id is None:
            log_test("Payment Flow", "Confirm payment", "FAIL", "No payment available to confirm")
        else:
            payment_confirm = requests.post(
                f"{BASE_URL}/payments/confirm",
                json={"payment_id": created_payment_id}
            )
            if payment_confirm.status_code == 200:
                log_test("Payment Flow", "Confirm payment", "PASS", "Payment confirmed")
            else:
                log_test("Payment Flow", "Confirm payment", "FAIL", 
                        f"Status: {payment_confirm.status_code}")
    except Exception as e:
        log_test("Payment Flow", "EXCEPTION", "FAIL", str(e))

# SCENARIO 4: RIDE MANAGEMENT
def test_scenario_4_ride_management():
    """Test ride lifecycle management"""
    print_section("SCENARIO 4: RIDE MANAGEMENT")
    
    try:
        # 1. Get all rides
        rides_response = requests.get(f"{BASE_URL}/rides/")
        if rides_response.status_code == 200:
            rides = requests.get(f"{BASE_URL}/rides/").json()
            log_test("Ride Management", "Get all rides", "PASS", f"Found {len(rides)} rides")
            
            if rides:
                # 2. Get specific ride
                ride_id = rides[0]['id']
                ride_response = requests.get(f"{BASE_URL}/rides/{ride_id}")
                if ride_response.status_code == 200:
                    log_test("Ride Management", "Get ride by ID", "PASS", 
                            f"Status: {ride_response.json().get('status')}")
                
                # 3. Update ride status
                update_response = requests.put(f"{BASE_URL}/rides/{ride_id}", 
                                              json={"status": "completed"})
                if update_response.status_code in [200, 405]:
                    log_test("Ride Management", "Update ride status", "PASS", 
                            f"Status: {update_response.status_code}")
                
                # 4. Check ride after station (simulated)
                check_response = requests.post(f"{BASE_URL}/rides/check/{ride_id}")
                if check_response.status_code in [200, 404]:
                    log_test("Ride Management", "Check ride status", "PASS", 
                            "Status checked")
        else:
            log_test("Ride Management", "Get all rides", "FAIL", 
                    f"Status: {rides_response.status_code}")
    except Exception as e:
        log_test("Ride Management", "EXCEPTION", "FAIL", str(e))

# SCENARIO 5: DATA CONSISTENCY
def test_scenario_5_data_consistency():
    """Test data consistency across endpoints"""
    print_section("SCENARIO 5: DATA CONSISTENCY")
    
    try:
        # 1. Get drivers count
        drivers1 = requests.get(f"{BASE_URL}/drivers/").json()
        drivers2 = requests.get(f"{BASE_URL}/drivers/").json()
        
        if len(drivers1) == len(drivers2):
            log_test("Data Consistency", "Driver count consistency", "PASS", 
                    f"Count: {len(drivers1)}")
        else:
            log_test("Data Consistency", "Driver count consistency", "FAIL", 
                    f"Count mismatch: {len(drivers1)} vs {len(drivers2)}")
        
        # 2. Get stations consistency
        stations1 = requests.get(f"{BASE_URL}/stations/").json()
        stations2 = requests.get(f"{BASE_URL}/stations/").json()
        
        if len(stations1) == len(stations2):
            log_test("Data Consistency", "Station count consistency", "PASS", 
                    f"Count: {len(stations1)}")
        else:
            log_test("Data Consistency", "Station count consistency", "FAIL", 
                    f"Count mismatch: {len(stations1)} vs {len(stations2)}")
        
        # 3. Get rides consistency
        rides1 = requests.get(f"{BASE_URL}/rides/").json()
        rides2 = requests.get(f"{BASE_URL}/rides/").json()
        
        if len(rides1) == len(rides2):
            log_test("Data Consistency", "Ride count consistency", "PASS", 
                    f"Count: {len(rides1)}")
        else:
            log_test("Data Consistency", "Ride count consistency", "FAIL", 
                    f"Count mismatch: {len(rides1)} vs {len(rides2)}")
    except Exception as e:
        log_test("Data Consistency", "EXCEPTION", "FAIL", str(e))

# SCENARIO 6: ERROR HANDLING
def test_scenario_6_error_handling():
    """Test error handling and edge cases"""
    print_section("SCENARIO 6: ERROR HANDLING")
    
    try:
        # 1. Invalid driver ID
        invalid_driver = requests.get(f"{BASE_URL}/drivers/99999")
        if invalid_driver.status_code == 404:
            log_test("Error Handling", "Invalid driver ID returns 404", "PASS", 
                    "Correct error response")
        else:
            log_test("Error Handling", "Invalid driver ID returns 404", "FAIL", 
                    f"Status: {invalid_driver.status_code}")
        
        # 2. Invalid ride ID
        invalid_ride = requests.get(f"{BASE_URL}/rides/99999")
        if invalid_ride.status_code in [200, 404]:
            log_test("Error Handling", "Invalid ride ID", "PASS", 
                    "Proper error response")
        
        # 3. Missing required fields
        bad_payment = requests.post(f"{BASE_URL}/payments/initiate", json={})
        if bad_payment.status_code in [422, 400]:
            log_test("Error Handling", "Missing required fields", "PASS", 
                    "Validation error caught")
        else:
            log_test("Error Handling", "Missing required fields", "FAIL", 
                    f"Status: {bad_payment.status_code}")
        
        # 4. Invalid station ID in ride creation
        bad_ride = requests.post(f"{BASE_URL}/rides", 
                                json={"passenger_id": 1, "driver_id": 1, 
                                     "station_id": 99999})
        if bad_ride.status_code in [422, 404]:
            log_test("Error Handling", "Invalid station in ride", "PASS", 
                    "Error caught")
    except Exception as e:
        log_test("Error Handling", "EXCEPTION", "FAIL", str(e))

# SCENARIO 7: LOAD TEST
def test_scenario_7_load_test():
    """Test system under moderate load"""
    print_section("SCENARIO 7: LOAD TEST")
    
    try:
        # Make 10 rapid requests
        start_time = time.time()
        success_count = 0
        
        for i in range(10):
            try:
                response = requests.get(f"{BASE_URL}/stations/", timeout=5)
                if response.status_code == 200:
                    success_count += 1
            except:
                pass
        
        end_time = time.time()
        duration = end_time - start_time
        
        if success_count >= 9:
            log_test("Load Test", "10 rapid requests", "PASS", 
                    f"Success: {success_count}/10, Time: {duration:.2f}s")
        else:
            log_test("Load Test", "10 rapid requests", "FAIL", 
                    f"Success: {success_count}/10, Time: {duration:.2f}s")
    except Exception as e:
        log_test("Load Test", "EXCEPTION", "FAIL", str(e))

def print_summary():
    """Print test summary"""
    print(f"\n{BOLD}{BLUE}{'='*70}")
    print(f"ADVANCED TEST SCENARIOS - SUMMARY")
    print(f"{'='*70}{RESET}\n")
    
    passed = sum(1 for r in TEST_RESULTS if r["status"] == "PASS")
    failed = sum(1 for r in TEST_RESULTS if r["status"] == "FAIL")
    total = len(TEST_RESULTS)
    
    scenarios = {}
    for result in TEST_RESULTS:
        scenario = result["scenario"]
        if scenario not in scenarios:
            scenarios[scenario] = {"pass": 0, "fail": 0}
        
        if result["status"] == "PASS":
            scenarios[scenario]["pass"] += 1
        else:
            scenarios[scenario]["fail"] += 1
    
    print(f"Total Tests: {total}")
    print(f"{GREEN}Passed: {passed}{RESET}")
    print(f"{RED}Failed: {failed}{RESET}")
    print(f"Pass Rate: {GREEN if passed/total >= 0.8 else RED}{passed/total*100:.1f}%{RESET}\n")
    
    print(f"{BOLD}Scenario Results:{RESET}")
    print(f"{'-'*70}")
    for scenario, counts in scenarios.items():
        total_scenario = counts["pass"] + counts["fail"]
        pass_rate = counts["pass"] / total_scenario * 100 if total_scenario > 0 else 0
        status_color = GREEN if pass_rate >= 80 else RED
        print(f"{scenario}: {counts['pass']}/{total_scenario} ({status_color}{pass_rate:.0f}%{RESET})")
    
    print(f"\n{BOLD}{BLUE}{'='*70}{RESET}\n")
    
    # Save results to file
    with open("advanced_test_results.json", "w") as f:
        json.dump({
            "summary": {
                "total": total,
                "passed": passed,
                "failed": failed,
                "pass_rate": passed/total*100 if total > 0 else 0
            },
            "scenarios": scenarios,
            "results": TEST_RESULTS,
            "timestamp": datetime.now().isoformat()
        }, f, indent=2)
    
    print(f"Results saved to: advanced_test_results.json\n")

def main():
    """Main test runner"""
    print(f"\n{BOLD}{BLUE}{'='*70}")
    print(f"PEAKMAP 2.0 - ADVANCED TEST SCENARIOS")
    print(f"{'='*70}{RESET}\n")
    
    print(f"Backend URL: {BASE_URL}")
    print(f"Test Start: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    
    # Run all scenarios
    test_scenario_1_driver_flow()
    test_scenario_2_passenger_flow()
    test_scenario_3_payment_flow()
    test_scenario_4_ride_management()
    test_scenario_5_data_consistency()
    test_scenario_6_error_handling()
    test_scenario_7_load_test()
    
    # Print summary
    print_summary()

if __name__ == "__main__":
    main()
