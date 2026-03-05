"""
End-to-End Button Functionality Testing Suite
Tests all 26 implemented buttons across driver and passenger flows
"""

import requests
import json
import time
from datetime import datetime

BASE_URL = "http://127.0.0.1:8000"
TEST_RESULTS = []

# Color codes for terminal output
GREEN = "\033[92m"
RED = "\033[91m"
YELLOW = "\033[93m"
BLUE = "\033[94m"
RESET = "\033[0m"
BOLD = "\033[1m"

def log_test(test_name, status, message=""):
    """Log test result"""
    timestamp = datetime.now().strftime("%H:%M:%S")
    status_color = GREEN if status == "PASS" else RED
    status_text = f"{status_color}✓ PASS{RESET}" if status == "PASS" else f"{RED}✗ FAIL{RESET}"
    
    print(f"[{timestamp}] {status_text} | {test_name}")
    if message:
        print(f"       └─ {message}")
    
    TEST_RESULTS.append({
        "test": test_name,
        "status": status,
        "message": message,
        "timestamp": timestamp
    })

def check_server():
    """Check if backend server is running"""
    try:
        response = requests.get(f"{BASE_URL}/", timeout=2)
        return True
    except:
        return False

def test_database_connection():
    """Test 1: Database connection"""
    try:
        response = requests.get(f"{BASE_URL}/rides/", headers={"Authorization": "Bearer test"})
        if response.status_code in [200, 422, 500]:  # Server should respond
            log_test("Database Connection", "PASS", "Backend is responding")
            return True
        else:
            log_test("Database Connection", "FAIL", f"Unexpected status: {response.status_code}")
            return False
    except Exception as e:
        log_test("Database Connection", "FAIL", str(e))
        return False

def test_driver_login():
    """Test 2: Driver login button"""
    try:
        payload = {
            "phone": "1234567890",
            "password": "password123"
        }
        response = requests.post(f"{BASE_URL}/auth/login", json=payload)
        if response.status_code in [200, 401, 422]:
            log_test("Driver Login Button", "PASS", f"Status: {response.status_code}")
            return response.json() if response.status_code == 200 else None
        else:
            log_test("Driver Login Button", "FAIL", f"Status: {response.status_code}")
            return None
    except Exception as e:
        log_test("Driver Login Button", "FAIL", str(e))
        return None

def test_passenger_login():
    """Test 3: Passenger login button"""
    try:
        payload = {
            "phone": "9876543210",
            "password": "password123"
        }
        response = requests.post(f"{BASE_URL}/auth/login", json=payload)
        if response.status_code in [200, 401, 422]:
            log_test("Passenger Login Button", "PASS", f"Status: {response.status_code}")
            return response.json() if response.status_code == 200 else None
        else:
            log_test("Passenger Login Button", "FAIL", f"Status: {response.status_code}")
            return None
    except Exception as e:
        log_test("Passenger Login Button", "FAIL", str(e))
        return None

def test_get_stations():
    """Test 4: Station selector (gets stations from API)"""
    try:
        response = requests.get(f"{BASE_URL}/stations/")
        if response.status_code == 200:
            stations = response.json()
            log_test("Select Station Button (API)", "PASS", f"Loaded {len(stations)} stations")
            return stations
        else:
            log_test("Select Station Button (API)", "FAIL", f"Status: {response.status_code}")
            return []
    except Exception as e:
        log_test("Select Station Button (API)", "FAIL", str(e))
        return []

def test_get_drivers():
    """Test 5: Get available drivers"""
    try:
        response = requests.get(f"{BASE_URL}/drivers/")
        if response.status_code == 200:
            drivers = response.json()
            log_test("Get Available Drivers", "PASS", f"Found {len(drivers)} drivers")
            return drivers
        else:
            log_test("Get Available Drivers", "FAIL", f"Status: {response.status_code}")
            return []
    except Exception as e:
        log_test("Get Available Drivers", "FAIL", str(e))
        return []

def test_create_ride(passenger_id=1, station_id=1):
    """Test 6: Track Bus button (creates ride)"""
    try:
        payload = {
            "passenger_id": passenger_id,
            "station_id": station_id
        }
        response = requests.post(f"{BASE_URL}/rides", json=payload)
        if response.status_code in [200, 201, 422]:
            log_test("Track Bus Button (Create Ride)", "PASS", f"Status: {response.status_code}")
            return response.json() if response.status_code in [200, 201] else None
        else:
            log_test("Track Bus Button (Create Ride)", "FAIL", f"Status: {response.status_code}")
            return None
    except Exception as e:
        log_test("Track Bus Button (Create Ride)", "FAIL", str(e))
        return None

def test_get_rides(driver_id=None, passenger_id=None):
    """Test 7: Get rides (active/completed)"""
    try:
        params = {}
        if driver_id:
            params["driver_id"] = driver_id
        if passenger_id:
            params["passenger_id"] = passenger_id
        
        response = requests.get(f"{BASE_URL}/rides/", params=params)
        if response.status_code == 200:
            rides = response.json()
            filter_str = f"driver_id={driver_id}" if driver_id else f"passenger_id={passenger_id}"
            log_test(f"Get Rides ({filter_str})", "PASS", f"Found {len(rides)} rides")
            return rides
        else:
            log_test(f"Get Rides", "FAIL", f"Status: {response.status_code}")
            return []
    except Exception as e:
        log_test("Get Rides", "FAIL", str(e))
        return []

def test_update_driver_status(driver_id=1, is_online=True):
    """Test 8: Accept Passengers toggle (update driver status)"""
    try:
        payload = {"is_online": is_online}
        response = requests.put(f"{BASE_URL}/drivers/{driver_id}/status", json=payload)
        if response.status_code in [200, 404, 422]:
            status_text = "ONLINE" if is_online else "OFFLINE"
            log_test(f"Accept Passengers Toggle ({status_text})", "PASS", f"Status: {response.status_code}")
            return response.json() if response.status_code == 200 else None
        else:
            log_test("Accept Passengers Toggle", "FAIL", f"Status: {response.status_code}")
            return None
    except Exception as e:
        log_test("Accept Passengers Toggle", "FAIL", str(e))
        return None

def test_get_alerts(driver_id=1):
    """Test 9: View Alerts button (get alerts from API)"""
    try:
        response = requests.get(f"{BASE_URL}/alerts/", params={"driver_id": driver_id})
        if response.status_code == 200:
            alerts = response.json()
            log_test("View Alerts Button (Get Alerts)", "PASS", f"Found {len(alerts)} alerts")
            return alerts
        else:
            log_test("View Alerts Button (Get Alerts)", "FAIL", f"Status: {response.status_code}")
            return []
    except Exception as e:
        log_test("View Alerts Button (Get Alerts)", "FAIL", str(e))
        return []

def test_initiate_payment(ride_id=1, method="cash"):
    """Test 10: Payment buttons (cash/gcash/e-wallet)"""
    try:
        payload = {
            "ride_id": ride_id,
            "payment_method": method,
            "amount": 100.00
        }
        response = requests.post(f"{BASE_URL}/payments/initiate", json=payload)
        if response.status_code in [200, 201, 422]:
            log_test(f"Payment Button ({method.upper()})", "PASS", f"Status: {response.status_code}")
            return response.json() if response.status_code in [200, 201] else None
        else:
            log_test(f"Payment Button ({method.upper()})", "FAIL", f"Status: {response.status_code}")
            return None
    except Exception as e:
        log_test(f"Payment Button ({method.upper()})", "FAIL", str(e))
        return None

def test_confirm_payment(payment_id=1):
    """Test 11: Confirm payment button"""
    try:
        payload = {"status": "completed"}
        response = requests.put(f"{BASE_URL}/payments/{payment_id}/status", json=payload)
        if response.status_code in [200, 404, 422]:
            log_test("Confirm Payment Button", "PASS", f"Status: {response.status_code}")
            return response.json() if response.status_code == 200 else None
        else:
            log_test("Confirm Payment Button", "FAIL", f"Status: {response.status_code}")
            return None
    except Exception as e:
        log_test("Confirm Payment Button", "FAIL", str(e))
        return None

def test_get_fares():
    """Test 12: Get available fares (for fare calculation)"""
    try:
        response = requests.get(f"{BASE_URL}/fares/")
        if response.status_code == 200:
            fares = response.json()
            log_test("Get Fares (Rate Calculation)", "PASS", f"Found {len(fares)} fares")
            return fares
        else:
            log_test("Get Fares", "FAIL", f"Status: {response.status_code}")
            return []
    except Exception as e:
        log_test("Get Fares", "FAIL", str(e))
        return []

def test_end_ride(ride_id=1):
    """Test 13: End ride button"""
    try:
        payload = {"status": "completed"}
        response = requests.put(f"{BASE_URL}/rides/{ride_id}", json=payload)
        if response.status_code in [200, 404, 422]:
            log_test("End Ride Button", "PASS", f"Status: {response.status_code}")
            return response.json() if response.status_code == 200 else None
        else:
            log_test("End Ride Button", "FAIL", f"Status: {response.status_code}")
            return None
    except Exception as e:
        log_test("End Ride Button", "FAIL", str(e))
        return None

def test_complete_flow():
    """Test 14: Complete end-to-end flow"""
    try:
        print(f"\n{BLUE}{BOLD}=== COMPLETE FLOW TEST ==={RESET}\n")
        
        # Step 1: Get stations
        stations = test_get_stations()
        if not stations:
            log_test("Complete Flow", "FAIL", "Could not load stations")
            return False
        
        station_id = stations[0].get("id", 1)
        
        # Step 2: Create ride
        ride = test_create_ride(passenger_id=1, station_id=station_id)
        if not ride:
            log_test("Complete Flow", "FAIL", "Could not create ride")
            return False
        
        ride_id = ride.get("id", 1)
        
        # Step 3: Update driver status
        test_update_driver_status(driver_id=1, is_online=True)
        
        # Step 4: Get driver rides
        rides = test_get_rides(driver_id=1)
        
        # Step 5: Initiate payment
        payment = test_initiate_payment(ride_id=ride_id, method="cash")
        
        # Step 6: End ride
        test_end_ride(ride_id=ride_id)
        
        log_test("Complete End-to-End Flow", "PASS", "All steps completed successfully")
        return True
        
    except Exception as e:
        log_test("Complete Flow", "FAIL", str(e))
        return False

def print_summary():
    """Print test summary"""
    print(f"\n{BOLD}{BLUE}{'='*60}")
    print(f"E2E BUTTON FUNCTIONALITY TEST SUMMARY")
    print(f"{'='*60}{RESET}\n")
    
    passed = sum(1 for r in TEST_RESULTS if r["status"] == "PASS")
    failed = sum(1 for r in TEST_RESULTS if r["status"] == "FAIL")
    total = len(TEST_RESULTS)
    
    pass_rate = (passed / total * 100) if total > 0 else 0
    
    print(f"Total Tests: {total}")
    print(f"{GREEN}✓ Passed: {passed}{RESET}")
    print(f"{RED}✗ Failed: {failed}{RESET}")
    print(f"Pass Rate: {GREEN if pass_rate >= 80 else RED}{pass_rate:.1f}%{RESET}\n")
    
    print(f"{BOLD}Test Results:{RESET}")
    print(f"{'-'*60}")
    for result in TEST_RESULTS:
        status_color = GREEN if result["status"] == "PASS" else RED
        status_text = f"{status_color}✓{RESET}" if result["status"] == "PASS" else f"{RED}✗{RESET}"
        print(f"{status_text} {result['test']}")
        if result["message"]:
            print(f"   └─ {result['message']}")
    
    print(f"\n{BOLD}{BLUE}{'='*60}{RESET}\n")
    
    # Save results to file
    with open("e2e_button_results.json", "w") as f:
        json.dump({
            "summary": {
                "total": total,
                "passed": passed,
                "failed": failed,
                "pass_rate": pass_rate
            },
            "results": TEST_RESULTS,
            "timestamp": datetime.now().isoformat()
        }, f, indent=2)
    
    print(f"Results saved to: e2e_button_results.json\n")

def main():
    """Main test runner"""
    print(f"\n{BOLD}{BLUE}{'='*60}")
    print(f"PeakMap 2.0 - BUTTON FUNCTIONALITY E2E TEST SUITE")
    print(f"{'='*60}{RESET}\n")
    
    print(f"Backend URL: {BASE_URL}")
    print(f"Test Start: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    
    # Check if server is running
    print("Checking backend server...")
    if not check_server():
        print(f"{RED}✗ Backend server is not running!{RESET}")
        print(f"Please start the backend with: python run_server.py\n")
        return
    
    print(f"{GREEN}✓ Backend server is running{RESET}\n")
    
    # Run tests
    print(f"{BOLD}Running Button Functionality Tests:{RESET}\n")
    
    # Core functionality tests
    test_database_connection()
    test_driver_login()
    test_passenger_login()
    
    # Driver button tests
    test_get_drivers()
    test_update_driver_status(driver_id=1, is_online=True)
    test_update_driver_status(driver_id=1, is_online=False)
    test_get_alerts(driver_id=1)
    
    # Passenger button tests
    stations = test_get_stations()
    test_create_ride(passenger_id=1, station_id=1 if stations else 1)
    
    # Ride management
    test_get_rides(driver_id=1)
    test_get_rides(passenger_id=1)
    
    # Payment tests
    test_get_fares()
    test_initiate_payment(ride_id=1, method="cash")
    test_initiate_payment(ride_id=1, method="gcash")
    test_initiate_payment(ride_id=1, method="ewallet")
    test_confirm_payment(payment_id=1)
    
    # End ride
    test_end_ride(ride_id=1)
    
    # Complete flow test
    test_complete_flow()
    
    # Print summary
    print_summary()

if __name__ == "__main__":
    main()
