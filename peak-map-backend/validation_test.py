#!/usr/bin/env python3
"""
Validation Fixes Verification Script
Tests all validation constraints added to fares, stations, and payments
"""
import requests
import json
from datetime import datetime

BASE_URL = "http://127.0.0.1:8000"

# ANSI colors
GREEN = '\033[92m'
RED = '\033[91m'
YELLOW = '\033[93m'
BLUE = '\033[94m'
RESET = '\033[0m'

test_results = []

def print_test(test_num, name, status, data=None):
    """Print test result"""
    symbol = f"{GREEN}✅{RESET}" if status == "PASS" else f"{RED}❌{RESET}"
    print(f"\n{symbol} TEST {test_num}: {name}")
    if data:
        print(f"   Response: {json.dumps(data, indent=2)}")
    test_results.append({"num": test_num, "name": name, "status": status})

def test_validation():
    """Run all validation tests"""
    print(f"\n{BLUE}{'='*60}")
    print(f"VALIDATION FIXES VERIFICATION".center(60))
    print(f"{'='*60}{RESET}")
    
    # ============================================
    # FIX #1: FARES VALIDATION
    # ============================================
    print(f"\n{YELLOW}FIX #1: FARES VALIDATION{RESET}")
    print("-" * 60)
    
    # Get existing stations
    try:
        response = requests.get(f"{BASE_URL}/stations/")
        stations = response.json()
        if len(stations) >= 2:
            station_1 = stations[0]["id"]
            station_2 = stations[1]["id"]
        else:
            print(f"{RED}Not enough stations. Creating test stations...{RESET}")
            # Create test stations
            resp1 = requests.post(f"{BASE_URL}/stations/", json={
                "name": "Test Station A",
                "latitude": 14.5790,
                "longitude": 121.0237,
                "radius": 500
            })
            resp2 = requests.post(f"{BASE_URL}/stations/", json={
                "name": "Test Station B",
                "latitude": 14.5500,
                "longitude": 121.0300,
                "radius": 500
            })
            if resp1.status_code == 200 and resp2.status_code == 200:
                station_1 = resp1.json()["id"]
                station_2 = resp2.json()["id"]
            else:
                print(f"{RED}Failed to create test stations{RESET}")
                return test_results
    except Exception as e:
        print(f"{RED}Error getting stations: {e}{RESET}")
        return test_results
    
    # TEST 1.1: Negative amount validation
    print("\n[TEST 1.1] Negative amount validation")
    try:
        response = requests.post(f"{BASE_URL}/fares/", json={
            "from_station": station_1,
            "to_station": station_2,
            "amount": -50
        })
        if response.status_code == 422:  # Validation error
            print_test("1.1", "Reject negative fare amount", "PASS", response.json())
        else:
            print_test("1.1", "Reject negative fare amount", "FAIL", response.json())
    except Exception as e:
        print_test("1.1", "Reject negative fare amount", "FAIL", str(e))
    
    # TEST 1.2: Zero amount - edge case
    print("\n[TEST 1.2] Zero amount validation")
    try:
        response = requests.post(f"{BASE_URL}/fares/", json={
            "from_station": station_1,
            "to_station": station_2,
            "amount": 0
        })
        if response.status_code == 422:
            print_test("1.2", "Reject zero fare amount", "PASS", response.json())
        else:
            print_test("1.2", "Reject zero fare amount", "FAIL", response.json())
    except Exception as e:
        print_test("1.2", "Reject zero fare amount", "FAIL", str(e))
    
    # TEST 1.3: Same station validation
    print("\n[TEST 1.3] Same from/to station validation")
    try:
        response = requests.post(f"{BASE_URL}/fares/", json={
            "from_station": station_1,
            "to_station": station_1,
            "amount": 50
        })
        if response.status_code == 422:
            print_test("1.3", "Reject same from/to stations", "PASS", response.json())
        else:
            print_test("1.3", "Reject same from/to stations", "FAIL", response.json())
    except Exception as e:
        print_test("1.3", "Reject same from/to stations", "FAIL", str(e))
    
    # TEST 1.4: Non-existent station
    print("\n[TEST 1.4] Non-existent station validation")
    try:
        response = requests.post(f"{BASE_URL}/fares/", json={
            "from_station": 99999,
            "to_station": station_2,
            "amount": 50
        })
        if response.status_code == 404:
            print_test("1.4", "Reject non-existent station", "PASS", response.json())
        else:
            print_test("1.4", "Reject non-existent station", "FAIL", response.json())
    except Exception as e:
        print_test("1.4", "Reject non-existent station", "FAIL", str(e))
    
    # TEST 1.5: Valid fare creation
    print("\n[TEST 1.5] Valid fare creation")
    try:
        response = requests.post(f"{BASE_URL}/fares/", json={
            "from_station": station_1,
            "to_station": station_2,
            "amount": 55.50
        })
        if response.status_code == 200:
            fare_data = response.json()
            print_test("1.5", "Create valid fare", "PASS", fare_data)
            test_fare_id = fare_data.get("id")
        else:
            print_test("1.5", "Create valid fare", "FAIL", response.json())
    except Exception as e:
        print_test("1.5", "Create valid fare", "FAIL", str(e))
    
    # TEST 1.6: Duplicate fare route
    print("\n[TEST 1.6] Duplicate fare route validation")
    try:
        response = requests.post(f"{BASE_URL}/fares/", json={
            "from_station": station_1,
            "to_station": station_2,
            "amount": 60.00
        })
        if response.status_code == 400:
            print_test("1.6", "Reject duplicate fare route", "PASS", response.json())
        else:
            print_test("1.6", "Reject duplicate fare route", "FAIL", response.json())
    except Exception as e:
        print_test("1.6", "Reject duplicate fare route", "FAIL", str(e))
    
    # ============================================
    # FIX #2: STATIONS VALIDATION
    # ============================================
    print(f"\n{YELLOW}FIX #2: STATIONS VALIDATION{RESET}")
    print("-" * 60)
    
    # TEST 2.1: Invalid latitude (> 90)
    print("\n[TEST 2.1] Invalid latitude validation")
    try:
        response = requests.post(f"{BASE_URL}/stations/", json={
            "name": "Invalid Lat Station 1",
            "latitude": 95.0,
            "longitude": 120.0,
            "radius": 500
        })
        if response.status_code == 422:
            print_test("2.1", "Reject latitude > 90", "PASS", response.json())
        else:
            print_test("2.1", "Reject latitude > 90", "FAIL", response.json())
    except Exception as e:
        print_test("2.1", "Reject latitude > 90", "FAIL", str(e))
    
    # TEST 2.2: Invalid latitude (< -90)
    print("\n[TEST 2.2] Invalid negative latitude validation")
    try:
        response = requests.post(f"{BASE_URL}/stations/", json={
            "name": "Invalid Lat Station 2",
            "latitude": -95.0,
            "longitude": 120.0,
            "radius": 500
        })
        if response.status_code == 422:
            print_test("2.2", "Reject latitude < -90", "PASS", response.json())
        else:
            print_test("2.2", "Reject latitude < -90", "FAIL", response.json())
    except Exception as e:
        print_test("2.2", "Reject latitude < -90", "FAIL", str(e))
    
    # TEST 2.3: Invalid longitude (> 180)
    print("\n[TEST 2.3] Invalid longitude validation")
    try:
        response = requests.post(f"{BASE_URL}/stations/", json={
            "name": "Invalid Lon Station 1",
            "latitude": 14.5,
            "longitude": 185.0,
            "radius": 500
        })
        if response.status_code == 422:
            print_test("2.3", "Reject longitude > 180", "PASS", response.json())
        else:
            print_test("2.3", "Reject longitude > 180", "FAIL", response.json())
    except Exception as e:
        print_test("2.3", "Reject longitude > 180", "FAIL", str(e))
    
    # TEST 2.4: Invalid radius
    print("\n[TEST 2.4] Invalid radius validation")
    try:
        response = requests.post(f"{BASE_URL}/stations/", json={
            "name": "Invalid Radius Station",
            "latitude": 14.5,
            "longitude": 121.0,
            "radius": -500
        })
        if response.status_code == 422:
            print_test("2.4", "Reject negative radius", "PASS", response.json())
        else:
            print_test("2.4", "Reject negative radius", "FAIL", response.json())
    except Exception as e:
        print_test("2.4", "Reject negative radius", "FAIL", str(e))
    
    # TEST 2.5: Zero radius
    print("\n[TEST 2.5] Zero radius validation")
    try:
        response = requests.post(f"{BASE_URL}/stations/", json={
            "name": "Zero Radius Station",
            "latitude": 14.5,
            "longitude": 121.0,
            "radius": 0
        })
        if response.status_code == 422:
            print_test("2.5", "Reject zero radius", "PASS", response.json())
        else:
            print_test("2.5", "Reject zero radius", "FAIL", response.json())
    except Exception as e:
        print_test("2.5", "Reject zero radius", "FAIL", str(e))
    
    # TEST 2.6: Duplicate station name (create first)
    print("\n[TEST 2.6] Duplicate station name validation")
    try:
        # Create first station
        response1 = requests.post(f"{BASE_URL}/stations/", json={
            "name": "Unique Test Station Name",
            "latitude": 14.6000,
            "longitude": 121.0500,
            "radius": 500
        })
        if response1.status_code == 200:
            # Try to create duplicate
            response2 = requests.post(f"{BASE_URL}/stations/", json={
                "name": "Unique Test Station Name",
                "latitude": 14.6100,  # Different coords
                "longitude": 121.0600,
                "radius": 500
            })
            if response2.status_code == 400:
                print_test("2.6", "Reject duplicate station name", "PASS", response2.json())
            else:
                print_test("2.6", "Reject duplicate station name", "FAIL", response2.json())
        else:
            print_test("2.6", "Reject duplicate station name", "FAIL", "Failed to create first station")
    except Exception as e:
        print_test("2.6", "Reject duplicate station name", "FAIL", str(e))
    
    # ============================================
    # FIX #3: PAYMENTS VALIDATION
    # ============================================
    print(f"\n{YELLOW}FIX #3: PAYMENTS VALIDATION{RESET}")
    print("-" * 60)
    
    # Get a ride
    try:
        response = requests.get(f"{BASE_URL}/rides/")
        rides = response.json()
        if len(rides) > 0:
            test_ride_id = rides[0]["id"]
        else:
            print(f"{YELLOW}No rides available for payment testing{RESET}")
            test_ride_id = None
    except:
        test_ride_id = None
    
    if test_ride_id:
        # TEST 3.1: Invalid payment method
        print("\n[TEST 3.1] Invalid payment method validation")
        try:
            response = requests.post(f"{BASE_URL}/payments/initiate", json={
                "ride_id": test_ride_id,
                "method": "crypto"  # Invalid method
            })
            if response.status_code == 422:
                print_test("3.1", "Reject invalid payment method", "PASS", response.json())
            else:
                print_test("3.1", "Reject invalid payment method", "FAIL", response.json())
        except Exception as e:
            print_test("3.1", "Reject invalid payment method", "FAIL", str(e))
        
        # TEST 3.2: Non-existent ride
        print("\n[TEST 3.2] Non-existent ride validation")
        try:
            response = requests.post(f"{BASE_URL}/payments/initiate", json={
                "ride_id": 99999,
                "method": "cash"
            })
            if response.status_code == 404:
                print_test("3.2", "Reject non-existent ride", "PASS", response.json())
            else:
                print_test("3.2", "Reject non-existent ride", "FAIL", response.json())
        except Exception as e:
            print_test("3.2", "Reject non-existent ride", "FAIL", str(e))
        
        # TEST 3.3: Valid payment creation
        print("\n[TEST 3.3] Valid payment creation")
        test_payment_id = None
        try:
            response = requests.post(f"{BASE_URL}/payments/initiate", json={
                "ride_id": test_ride_id,
                "method": "cash"
            })
            if response.status_code == 200:
                payment_data = response.json()
                print_test("3.3", "Create valid payment", "PASS", payment_data)
                test_payment_id = payment_data.get("payment_id")
            else:
                print_test("3.3", "Create valid payment", "FAIL", response.json())
        except Exception as e:
            print_test("3.3", "Create valid payment", "FAIL", str(e))
        
        if test_payment_id:
            # TEST 3.4: Confirm non-existent payment
            print("\n[TEST 3.4] Confirm non-existent payment")
            try:
                response = requests.post(f"{BASE_URL}/payments/confirm", json={
                    "payment_id": 99999
                })
                if response.status_code == 404:
                    print_test("3.4", "Reject non-existent payment confirm", "PASS", response.json())
                else:
                    print_test("3.4", "Reject non-existent payment confirm", "FAIL", response.json())
            except Exception as e:
                print_test("3.4", "Reject non-existent payment confirm", "FAIL", str(e))
            
            # TEST 3.5: Confirm valid payment
            print("\n[TEST 3.5] Confirm valid payment")
            try:
                response = requests.post(f"{BASE_URL}/payments/confirm", json={
                    "payment_id": test_payment_id
                })
                if response.status_code == 200:
                    print_test("3.5", "Confirm valid payment", "PASS", response.json())
                else:
                    print_test("3.5", "Confirm valid payment", "FAIL", response.json())
            except Exception as e:
                print_test("3.5", "Confirm valid payment", "FAIL", str(e))
            
            # TEST 3.6: Confirm already paid payment
            print("\n[TEST 3.6] Confirm already paid payment")
            try:
                response = requests.post(f"{BASE_URL}/payments/confirm", json={
                    "payment_id": test_payment_id
                })
                if response.status_code == 200 and "already confirmed" in response.json().get("message", ""):
                    print_test("3.6", "Handle idempotent confirm", "PASS", response.json())
                else:
                    print_test("3.6", "Handle idempotent confirm", "FAIL", response.json())
            except Exception as e:
                print_test("3.6", "Handle idempotent confirm", "FAIL", str(e))
    
    else:
        print(f"\n{YELLOW}Skipping payment tests - no rides available{RESET}")
    
    # Print summary
    print(f"\n{BLUE}{'='*60}")
    print(f"TEST SUMMARY".center(60))
    print(f"{'='*60}{RESET}")
    
    passed = sum(1 for t in test_results if t["status"] == "PASS")
    failed = sum(1 for t in test_results if t["status"] == "FAIL")
    total = len(test_results)
    
    for test in test_results:
        symbol = f"{GREEN}✅{RESET}" if test["status"] == "PASS" else f"{RED}❌{RESET}"
        print(f"{symbol} {test['num']}: {test['name']} - {test['status']}")
    
    print(f"\n{BLUE}{'='*60}{RESET}")
    print(f"TOTAL: {total} tests | {GREEN}{passed} PASSED{RESET} | {RED}{failed} FAILED{RESET}")
    print(f"Success Rate: {(passed/total*100):.1f}%")
    print(f"{BLUE}{'='*60}{RESET}\n")
    
    return test_results

if __name__ == "__main__":
    print(f"\n{BLUE}Starting validation tests...{RESET}")
    print(f"API URL: {BASE_URL}")
    print(f"Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    test_validation()
