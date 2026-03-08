"""
Register test card 1603310630 and load balance
Run this after starting the backend server
"""
import requests
import json

API_BASE = "http://127.0.0.1:8000"
CARD_UID = "1603310630"

# Test user ID - you can change this to your actual user ID
TEST_USER_EMAIL = "passenger@example.com"  # Or use user ID directly
TEST_INITIAL_BALANCE = 500.00  # ₱500 initial load

def register_card():
    """Register the card with a user"""
    print(f"\n📇 Registering card {CARD_UID}...")
    
    response = requests.post(
        f"{API_BASE}/rfid/cards/register",
        json={
            "user_identifier": TEST_USER_EMAIL,
            "card_uid": CARD_UID,
            "alias": "My Test Card"
        }
    )
    
    if response.status_code == 200:
        data = response.json()
        print(f"✅ Card registered successfully!")
        print(f"   Card UID: {data['card']['card_uid']}")
        print(f"   User: {data['card']['user_email']}")
        print(f"   User ID: {data['card']['user_id']}")
        return data['card']['user_id']
    else:
        print(f"❌ Registration failed: {response.status_code}")
        print(f"   Response: {response.text}")
        return None


def load_balance(user_id):
    """Load initial balance to the user account"""
    print(f"\n💰 Loading ₱{TEST_INITIAL_BALANCE} to user {user_id}...")
    
    response = requests.post(
        f"{API_BASE}/payments/load-balance",
        json={
            "user_id": str(user_id),
            "amount": TEST_INITIAL_BALANCE,
            "payment_method": "admin_nfc",
            "card_id": CARD_UID
        }
    )
    
    if response.status_code == 200:
        data = response.json()
        print(f"✅ Balance loaded successfully!")
        print(f"   Transaction ID: {data.get('transaction_id')}")
        print(f"   Amount: ₱{TEST_INITIAL_BALANCE}")
        return True
    else:
        print(f"❌ Balance load failed: {response.status_code}")
        print(f"   Response: {response.text}")
        return False


def tap_card():
    """Test the card tap endpoint"""
    print(f"\n🔍 Testing card tap for {CARD_UID}...")
    
    response = requests.get(f"{API_BASE}/rfid/cards/tap/{CARD_UID}")
    
    if response.status_code == 200:
        data = response.json()
        print(f"\n✅ Card tap successful!")
        print(f"\n╔══════════════════════════════════════╗")
        print(f"║         CARD TAP RESPONSE            ║")
        print(f"╚══════════════════════════════════════╝")
        print(f"\n📇 Card Information:")
        print(f"   UID: {data['card']['card_uid']}")
        print(f"   Alias: {data['card']['alias']}")
        print(f"   Status: {data['card']['status']}")
        print(f"\n👤 Card Owner:")
        if data.get('user'):
            print(f"   User ID: {data['user']['user_id']}")
            print(f"   Email: {data['user']['email']}")
            print(f"   Name: {data['user']['name']}")
        else:
            print(f"   No user linked")
        print(f"\n💵 Balance:")
        print(f"   Amount: {data['balance']['formatted']}")
        print(f"   Currency: {data['balance']['currency']}")
        print(f"\n")
        return True
    else:
        print(f"❌ Card tap failed: {response.status_code}")
        print(f"   Response: {response.text}")
        return False


def main():
    print("=" * 50)
    print("  RFID CARD REGISTRATION & TEST")
    print("=" * 50)
    
    try:
        # Step 1: Register card
        user_id = register_card()
        if not user_id:
            print("\n❌ Cannot continue without registered card")
            return
        
        # Step 2: Load balance
        if not load_balance(user_id):
            print("\n⚠️ Balance not loaded, but continuing with tap test...")
        
        # Step 3: Test card tap
        tap_card()
        
        print("\n" + "=" * 50)
        print("  TEST COMPLETE")
        print("=" * 50)
        print(f"\n💡 Now you can tap card {CARD_UID} anytime using:")
        print(f"   GET  {API_BASE}/rfid/cards/tap/{CARD_UID}")
        print(f"   POST {API_BASE}/rfid/cards/tap?card_uid={CARD_UID}")
        print("\n")
        
    except requests.exceptions.ConnectionError:
        print("\n❌ ERROR: Cannot connect to backend server")
        print(f"   Make sure the backend is running at {API_BASE}")
        print(f"   Run: python run_server.py")
    except Exception as e:
        print(f"\n❌ ERROR: {e}")


if __name__ == "__main__":
    main()
