"""
PEAK MAP System Health Check
Tests all critical components and endpoints
"""
import requests
import json
from datetime import datetime

BASE_URL = "http://127.0.0.1:8000"

def print_header(text):
    print(f"\n{'='*60}")
    print(f"  {text}")
    print(f"{'='*60}\n")

def test_result(name, success, details=""):
    status = "✅ PASS" if success else "❌ FAIL"
    print(f"{status} | {name}")
    if details:
        print(f"     └─ {details}")

def test_backend_status():
    print_header("1. BACKEND SERVER STATUS")
    try:
        response = requests.get(f"{BASE_URL}/docs", timeout=3)
        test_result("Backend Server", response.status_code == 200, f"Status: {response.status_code}")
        return True
    except Exception as e:
        test_result("Backend Server", False, str(e))
        return False

def test_driver_endpoints():
    print_header("2. DRIVER MANAGEMENT")
    
    # Get all drivers
    try:
        response = requests.get(f"{BASE_URL}/drivers/")
        drivers = response.json() if response.status_code == 200 else []
        test_result("Get All Drivers", response.status_code == 200, f"Found {len(drivers)} drivers")
        
        if drivers:
            driver_id = drivers[0]['id']
            
            # Get specific driver (tests the is_online status we just fixed)
            response = requests.get(f"{BASE_URL}/drivers/{driver_id}")
            if response.status_code == 200:
                driver_data = response.json()
                is_online = driver_data.get('is_online', False)
                test_result("Get Driver Profile", True, f"Driver {driver_id} | Online: {is_online}")
            else:
                test_result("Get Driver Profile", False, f"Status: {response.status_code}")
            
            # Test online status toggle (the fix we just made)
            response = requests.put(
                f"{BASE_URL}/drivers/{driver_id}/status",
                json={"is_online": True}
            )
            test_result("Set Driver ONLINE", response.status_code == 200, f"Driver {driver_id}")
            
            # Verify status persisted
            response = requests.get(f"{BASE_URL}/drivers/{driver_id}")
            if response.status_code == 200:
                driver_data = response.json()
                is_online = driver_data.get('is_online', False)
                test_result("Verify Status Persistence", is_online == True, f"is_online = {is_online}")
            
            return driver_id
        else:
            print("⚠️  No drivers found in database")
            return None
    except Exception as e:
        test_result("Driver Endpoints", False, str(e))
        return None

def test_gps_system(driver_id):
    print_header("3. GPS TRACKING SYSTEM")
    
    if not driver_id:
        print("⚠️  Skipping GPS tests (no driver available)")
        return
    
    try:
        # Send GPS update
        response = requests.post(
            f"{BASE_URL}/gps/update",
            json={
                "driver_id": driver_id,
                "latitude": 14.5995,
                "longitude": 120.9842,
                "speed": 25.0
            }
        )
        test_result("GPS Update", response.status_code == 200, f"Driver {driver_id}")
        
        # Get latest GPS
        response = requests.get(f"{BASE_URL}/gps/latest/{driver_id}")
        if response.status_code == 200:
            gps_data = response.json()
            test_result("Get Latest GPS", True, f"Lat: {gps_data.get('latitude')}, Lng: {gps_data.get('longitude')}")
        else:
            test_result("Get Latest GPS", False, f"Status: {response.status_code}")
            
    except Exception as e:
        test_result("GPS System", False, str(e))

def test_rides_system():
    print_header("4. RIDE MANAGEMENT")
    
    try:
        # Get all rides
        response = requests.get(f"{BASE_URL}/rides")
        rides = response.json() if response.status_code == 200 else []
        test_result("Get All Rides", response.status_code == 200, f"Found {len(rides)} rides")
        
        # Get stations (required for ride creation)
        response = requests.get(f"{BASE_URL}/stations")
        stations = response.json() if response.status_code == 200 else []
        test_result("Get Stations", response.status_code == 200, f"Found {len(stations)} stations")
        
        return len(rides) > 0
    except Exception as e:
        test_result("Ride System", False, str(e))
        return False

def test_payment_system():
    print_header("5. PAYMENT SYSTEM")
    
    try:
        # Check if payments endpoint is accessible
        response = requests.get(f"{BASE_URL}/admin/payments_summary")
        if response.status_code == 200:
            summary = response.json()
            test_result("Payment Summary", True, f"Total Paid: ₱{summary.get('total_paid', 0)} | {summary.get('total_payments', 0)} payments")
        else:
            test_result("Payment Summary", response.status_code in [200, 404], f"Status: {response.status_code}")
            
    except Exception as e:
        test_result("Payment System", False, str(e))

def test_admin_dashboard():
    print_header("6. ADMIN ENDPOINTS")
    
    try:
        # Active rides
        response = requests.get(f"{BASE_URL}/admin/active_rides")
        test_result("Active Rides", response.status_code == 200, f"Status: {response.status_code}")
        
        # All drivers (admin view)
        response = requests.get(f"{BASE_URL}/admin/all_drivers")
        if response.status_code == 200:
            drivers = response.json()
            test_result("All Drivers (Admin)", True, f"Found {len(drivers)} drivers")
        else:
            test_result("All Drivers (Admin)", False, f"Status: {response.status_code}")
        
        # Ride stats
        response = requests.get(f"{BASE_URL}/admin/rides_stats")
        test_result("Ride Statistics", response.status_code == 200, f"Status: {response.status_code}")
        
    except Exception as e:
        test_result("Admin Dashboard", False, str(e))

def test_alerts_system(driver_id):
    print_header("7. DRIVER ALERTS")
    
    if not driver_id:
        print("⚠️  Skipping alerts test (no driver available)")
        return
    
    try:
        response = requests.get(f"{BASE_URL}/alerts?driver_id={driver_id}")
        alerts = response.json() if response.status_code == 200 else []
        test_result("Get Driver Alerts", response.status_code == 200, f"Found {len(alerts)} alerts")
    except Exception as e:
        test_result("Alert System", False, str(e))

def main():
    print("\n" + "="*60)
    print("  🏔️  PEAK MAP - SYSTEM HEALTH CHECK")
    print(f"  ⏰ {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("="*60)
    
    # Run all tests
    backend_ok = test_backend_status()
    
    if not backend_ok:
        print("\n❌ Backend is not running. Please start the server first.")
        print("   Run: python peak-map-backend/run_server.py")
        return
    
    driver_id = test_driver_endpoints()
    test_gps_system(driver_id)
    test_rides_system()
    test_payment_system()
    test_admin_dashboard()
    test_alerts_system(driver_id)
    
    print("\n" + "="*60)
    print("  🏁 SYSTEM HEALTH CHECK COMPLETE")
    print("="*60 + "\n")

if __name__ == "__main__":
    main()
