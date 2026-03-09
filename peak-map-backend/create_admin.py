"""
Script to create an admin user in the system.
Run this once to setup your first admin account.
"""
try:
    import requests
except ImportError:
    print("❌ Error: 'requests' module not installed!")
    print("   Install it with: pip install requests")
    print("   OR use the API call method in ADMIN_SETUP_GUIDE.md")
    import sys
    sys.exit(1)
import sys

API_BASE = "http://127.0.0.1:8000"

def create_admin():
    print("=" * 50)
    print("PEAKMAP ADMIN USER CREATOR")
    print("=" * 50)
    print()
    
    # Get admin details
    print("Enter admin details:")
    email = input("Email: ").strip()
    name = input("Name: ").strip()
    password = input("Password (min 6 characters): ").strip()
    
    if not email or not name or not password:
        print("\n❌ Error: All fields are required!")
        return
    
    if len(password) < 6:
        print("\n❌ Error: Password must be at least 6 characters!")
        return
    
    # Confirm
    print(f"\n📋 Creating admin user:")
    print(f"   Email: {email}")
    print(f"   Name: {name}")
    confirm = input("\nProceed? (yes/no): ").strip().lower()
    
    if confirm not in ['yes', 'y']:
        print("❌ Cancelled.")
        return
    
    try:
        # Call admin registration endpoint
        response = requests.post(
            f"{API_BASE}/admin/register",
            json={
                "email": email,
                "password": password,
                "name": name
            },
            timeout=10
        )
        
        data = response.json()
        
        if response.status_code == 200 and data.get("success"):
            print("\n" + "=" * 50)
            print("✅ ADMIN USER CREATED SUCCESSFULLY!")
            print("=" * 50)
            print(f"   User ID: {data.get('user_id')}")
            print(f"   Email: {data.get('email')}")
            print(f"\n🔒 You can now login at: http://127.0.0.1:8000/admin_dashboard.html")
            print("=" * 50)
        else:
            print(f"\n❌ Error: {data.get('detail') or data.get('message') or 'Registration failed'}")
            
    except requests.exceptions.ConnectionError:
        print("\n❌ Error: Cannot connect to backend server!")
        print("   Make sure the backend is running at http://127.0.0.1:8000")
    except Exception as e:
        print(f"\n❌ Error: {str(e)}")

if __name__ == "__main__":
    try:
        create_admin()
    except KeyboardInterrupt:
        print("\n\n❌ Cancelled by user.")
        sys.exit(0)
