"""
Admin Dashboard API Testing Script

This script tests all the backend endpoints used by the admin dashboard
to ensure they are working correctly.
"""

import requests
import json
from datetime import datetime

API_BASE = "http://127.0.0.1:8000"
TEST_USER_ID = "bb6e65b6-1cc5-4b63-8b99-0c80f86e0b9b"

def print_section(title):
    """Print a section header"""
    print("\n" + "="*60)
    print(f"  {title}")
    print("="*60)

def test_endpoint(name, method, url, data=None):
    """Test a single endpoint"""
    print(f"\n🧪 Testing: {name}")
    print(f"   {method} {url}")
    
    try:
        if method == "GET":
            response = requests.get(url)
        elif method == "POST":
            response = requests.post(url, json=data)
        
        print(f"   Status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print(f"   ✅ Success")
            print(f"   Response: {json.dumps(result, indent=2)[:200]}...")
            return result
        else:
            print(f"   ❌ Failed")
            print(f"   Error: {response.text}")
            return None
    except Exception as e:
        print(f"   ❌ Exception: {e}")
        return None

def main():
    print("\n🚀 PEAK MAP - Admin Dashboard API Test Suite")
    print(f"📅 Test Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"🌐 API Base: {API_BASE}")
    
    # Test 1: Dashboard Overview
    print_section("1. DASHBOARD OVERVIEW")
    test_endpoint(
        "Dashboard Overview",
        "GET",
        f"{API_BASE}/admin/dashboard_overview"
    )
    
    # Test 2: Active Rides
    print_section("2. ACTIVE RIDES & GPS")
    test_endpoint(
        "Active Rides with GPS",
        "GET",
        f"{API_BASE}/admin/active_rides"
    )
    
    # Test 3: All Drivers
    print_section("3. DRIVER MANAGEMENT")
    test_endpoint(
        "All Drivers List",
        "GET",
        f"{API_BASE}/admin/all_drivers"
    )
    
    # Test 4: Payment Breakdown
    print_section("4. PAYMENT BREAKDOWN")
    test_endpoint(
        "Payments By Method",
        "GET",
        f"{API_BASE}/admin/payments_by_method"
    )
    
    # Test 5: Ride Statistics
    print_section("5. RIDE STATISTICS")
    test_endpoint(
        "Ride Stats",
        "GET",
        f"{API_BASE}/admin/rides_stats"
    )
    
    # Test 6: Recent Activity
    print_section("6. RECENT ACTIVITY")
    test_endpoint(
        "Recent Activity Feed",
        "GET",
        f"{API_BASE}/admin/recent_activity?limit=10"
    )
    
    # Test 7: NFC Balance Loading
    print_section("7. NFC BALANCE LOADING")
    
    # Test load balance
    load_result = test_endpoint(
        "Load Balance (₱100)",
        "POST",
        f"{API_BASE}/payments/load-balance",
        {
            "user_id": TEST_USER_ID,
            "amount": 100.00,
            "payment_method": "admin_nfc"
        }
    )
    
    # Test get admin transactions
    test_endpoint(
        "Get All NFC Transactions",
        "GET",
        f"{API_BASE}/payments/transactions/admin"
    )
    
    # Test get user balance
    test_endpoint(
        "Get User Balance",
        "GET",
        f"{API_BASE}/payments/balance/{TEST_USER_ID}"
    )
    
    # Test 8: Transaction Refund
    print_section("8. TRANSACTION REFUND")
    
    if load_result and load_result.get("success"):
        transaction_id = load_result.get("transaction_id")
        test_endpoint(
            f"Refund Transaction #{transaction_id}",
            "POST",
            f"{API_BASE}/payments/refund/{transaction_id}",
            {
                "reason": "Test refund",
                "refunded_by": "admin_test"
            }
        )
    else:
        print("⚠️ Skipping refund test (no transaction to refund)")
    
    # Test 9: Card Management
    print_section("9. CARD MANAGEMENT")
    
    # Check card status
    test_endpoint(
        "Check Card Status",
        "GET",
        f"{API_BASE}/payments/card/{TEST_USER_ID}/status"
    )
    
    # Block card
    test_endpoint(
        "Block Card",
        "POST",
        f"{API_BASE}/payments/card/{TEST_USER_ID}/block",
        {
            "status": "blocked",
            "reason": "Test block"
        }
    )
    
    # Request replacement
    test_endpoint(
        "Request Card Replacement",
        "POST",
        f"{API_BASE}/payments/card/{TEST_USER_ID}/replace",
        {
            "status": "pending_replacement",
            "reason": "Test replacement"
        }
    )
    
    # Test 10: Driver Registration
    print_section("10. DRIVER REGISTRATION")
    
    test_user_email = f"test_driver_{int(datetime.now().timestamp())}@example.com"
    test_endpoint(
        "Register New Driver",
        "POST",
        f"{API_BASE}/auth/register",
        {
            "email": test_user_email,
            "password": "testpass123",
            "user_type": "driver",
            "name": "Test Driver"
        }
    )
    
    # Summary
    print_section("✅ TEST SUITE COMPLETED")
    print("\n📊 Summary:")
    print("   - All endpoints tested")
    print("   - Check output above for any failures")
    print("   - If all tests passed, admin dashboard is ready!")
    print("\n🌐 To test manually:")
    print("   1. Open admin_dashboard.html in browser")
    print("   2. Ensure backend is running on port 8000")
    print("   3. Click each button and verify functionality")
    print("\n" + "="*60 + "\n")

if __name__ == "__main__":
    main()
