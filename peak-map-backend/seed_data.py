"""
Test Data Seeding Script
Seeds the database with demo data for testing
"""

import os
import sys
from datetime import datetime, timedelta

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.database import SessionLocal, engine, Base
from app.models.user import User
from app.models.station import Station
from app.models.fare import Fare
from app.models.ride import Ride
from app.models.payment import Payment
from app.models.gps_log import GPSLog

# Create all tables
Base.metadata.create_all(bind=engine)

db = SessionLocal()

def clear_database():
    """Clear existing data"""
    print("Clearing existing data...")
    try:
        # Drop is_online column if it doesn't exist to avoid conflicts
        try:
            db.execute("ALTER TABLE users DROP COLUMN is_online")
            db.commit()
        except:
            pass  # Column doesn't exist or already dropped
        
        db.query(Payment).delete()
        db.query(GPSLog).delete()
        db.query(Ride).delete()
        db.query(Fare).delete()
        db.query(Station).delete()
        db.query(User).delete()
        db.commit()
        print("[OK] Database cleared")
    except Exception as e:
        print(f"[ERROR] Error clearing database: {e}")
        db.rollback()

def seed_stations():
    """Seed station data"""
    print("\n[STATIONS] Seeding stations...")
    
    stations_data = [
        {
            "name": "Quezon Memorial Circle",
            "latitude": 14.6348,
            "longitude": 121.0449,
            "radius": 200
        },
        {
            "name": "Monumento Circle",
            "latitude": 14.6014,
            "longitude": 120.9721,
            "radius": 200
        },
        {
            "name": "Cubao Terminal",
            "latitude": 14.6174,
            "longitude": 121.0597,
            "radius": 200
        },
        {
            "name": "Divisoria Market",
            "latitude": 14.5994,
            "longitude": 120.9742,
            "radius": 200
        },
        {
            "name": "BGC Crescent",
            "latitude": 14.5516,
            "longitude": 121.0436,
            "radius": 200
        },
    ]
    
    for station_data in stations_data:
        station = Station(**station_data)
        db.add(station)
    
    db.commit()
    print(f"[OK] Added {len(stations_data)} stations")
    return db.query(Station).all()

def seed_fares(stations):
    """Seed fare data"""
    print("\n[FARES] Seeding fares...")
    
    fare_routes = [
        {"from_station": 1, "to_station": 2, "amount": 35.0},
        {"from_station": 1, "to_station": 3, "amount": 25.0},
        {"from_station": 1, "to_station": 4, "amount": 45.0},
        {"from_station": 1, "to_station": 5, "amount": 50.0},
        {"from_station": 2, "to_station": 3, "amount": 40.0},
        {"from_station": 3, "to_station": 4, "amount": 35.0},
        {"from_station": 4, "to_station": 5, "amount": 55.0},
    ]
    
    for route in fare_routes:
        fare = Fare(
            from_station=route["from_station"],
            to_station=route["to_station"],
            amount=route["amount"]
        )
        db.add(fare)
    
    db.commit()
    print(f"[OK] Added {len(fare_routes)} fares")

def seed_drivers():
    """Seed driver data"""
    print("\n[DRIVERS] Seeding drivers...")
    
    drivers_data = [
        {
            "full_name": "Juan dela Cruz",
            "phone_number": "09171234567",
            "role": "driver",
        },
        {
            "full_name": "Pedro Santos",
            "phone_number": "09281234567",
            "role": "driver",
        },
        {
            "full_name": "Miguel Reyes",
            "phone_number": "09391234567",
            "role": "driver",
        },
        {
            "full_name": "Carlos Luna",
            "phone_number": "09451234567",
            "role": "driver",
        },
        {
            "full_name": "Antonio Morales",
            "phone_number": "09551234567",
            "role": "driver",
        },
    ]
    
    for driver_data in drivers_data:
        driver = User(**driver_data)
        db.add(driver)
    
    db.commit()
    print(f"[OK] Added {len(drivers_data)} drivers")
    return db.query(User).filter(User.role == "driver").all()

def seed_passengers():
    """Seed passenger data"""
    print("\n[PASSENGERS] Seeding passengers...")
    
    passengers_data = [
        {
            "full_name": "Maria Garcia",
            "phone_number": "09161234567",
            "role": "passenger",
        },
        {
            "full_name": "Rosa Mendoza",
            "phone_number": "09261234567",
            "role": "passenger",
        },
        {
            "full_name": "Ana Rodriguez",
            "phone_number": "09361234567",
            "role": "passenger",
        },
        {
            "full_name": "Carmen Torres",
            "phone_number": "09461234567",
            "role": "passenger",
        },
        {
            "full_name": "Diana Lopez",
            "phone_number": "09561234567",
            "role": "passenger",
        },
    ]
    
    for passenger_data in passengers_data:
        passenger = User(**passenger_data)
        db.add(passenger)
    
    db.commit()
    print(f"[OK] Added {len(passengers_data)} passengers")
    return db.query(User).filter(User.role == "passenger").all()

def seed_rides(drivers, passengers, stations):
    """Seed ride data"""
    print("\n[RIDES] Seeding rides...")
    
    rides_data = [
        {"passenger_id": 6, "driver_id": 1, "station_id": 3, "status": "completed", "fare": 25.0},
        {"passenger_id": 7, "driver_id": 2, "station_id": 4, "status": "completed", "fare": 35.0},
        {"passenger_id": 8, "driver_id": 3, "station_id": 2, "status": "completed", "fare": 40.0},
        {"passenger_id": 9, "driver_id": 4, "station_id": 5, "status": "ongoing", "fare": 50.0},
        {"passenger_id": 10, "driver_id": 5, "station_id": 3, "status": "ongoing", "fare": 25.0},
        {"passenger_id": 6, "driver_id": 1, "station_id": 5, "status": "completed", "fare": 45.0},
        {"passenger_id": 7, "driver_id": 2, "station_id": 2, "status": "completed", "fare": 30.0},
        {"passenger_id": 8, "driver_id": 3, "station_id": 4, "status": "completed", "fare": 35.0},
    ]
    
    for ride_data in rides_data:
        started_at = datetime.utcnow() - timedelta(hours=1 if ride_data["status"] == "completed" else 0)
        ended_at = datetime.utcnow() if ride_data["status"] == "completed" else None
        
        ride = Ride(
            passenger_id=ride_data["passenger_id"],
            driver_id=ride_data["driver_id"],
            station_id=ride_data["station_id"],
            status=ride_data["status"],
            fare_amount=ride_data["fare"],
            started_at=started_at,
            ended_at=ended_at
        )
        db.add(ride)
    
    db.commit()
    print(f"[OK] Added {len(rides_data)} rides")
    return db.query(Ride).all()

def seed_gps_logs(drivers, stations):
    """Seed GPS log data"""
    print("\n[GPS] Seeding GPS logs...")
    
    gps_logs = []
    for i, driver in enumerate(drivers):
        # Add 3 GPS points per driver
        for j in range(3):
            station = stations[i % len(stations)]
            
            # Add slight variation to coordinates
            latitude = station.latitude + (0.0001 * j)
            longitude = station.longitude + (0.0001 * j)
            
            gps_log = GPSLog(
                driver_id=driver.id,
                latitude=latitude,
                longitude=longitude,
                speed=15.5 + j,
                timestamp=datetime.utcnow() - timedelta(minutes=j*5)
            )
            db.add(gps_log)
            gps_logs.append(gps_log)
    
    db.commit()
    print(f"[OK] Added {len(gps_logs)} GPS logs")

def seed_payments(rides):
    """Seed payment data"""
    print("\n[PAYMENTS] Seeding payments...")
    
    payment_methods = ["cash", "gcash", "ewallet"]
    completed_rides = [r for r in rides if r.status == "completed"]
    
    payments = []
    for i, ride in enumerate(completed_rides[:3]):
        payment = Payment(
            ride_id=ride.id,
            amount=ride.fare_amount,
            method=payment_methods[i % len(payment_methods)],
            status="paid"
        )
        db.add(payment)
        payments.append(payment)
    
    db.commit()
    print(f"[OK] Added {len(payments)} payments")

def main():
    """Main seeding function"""
    # Safety check: warn about data loss
    safety_mode = os.getenv("ENABLE_SEEDING") != "true"
    
    if safety_mode:
        print("=" * 60)
        print("⚠️  SEED DATA SAFETY CHECK")
        print("=" * 60)
        print("\nThis script will DELETE ALL existing database data:")
        print("  ❌ All users (drivers & passengers)")
        print("  ❌ All rides")
        print("  ❌ All payments")
        print("  ❌ All GPS logs")
        print("\nTo enable seeding, run:")
        print("  ENABLE_SEEDING=true python seed_data.py")
        print("\nSeeding is for TESTING ONLY.")
        return
    
    print("=" * 60)
    print("PeakMap Database Seeding Script")
    print("=" * 60)
    
    try:
        # Clear existing data
        clear_database()
        
        # Seed data in order
        stations = seed_stations()
        seed_fares(stations)
        drivers = seed_drivers()
        passengers = seed_passengers()
        rides = seed_rides(drivers, passengers, stations)
        seed_gps_logs(drivers, stations)
        seed_payments(rides)
        
        print("\n" + "=" * 60)
        print("DATABASE SEEDING COMPLETE!")
        print("=" * 60)
        print("\nData Summary:")
        print(f"   * Stations: {len(stations)}")
        print(f"   * Drivers: {len(drivers)}")
        print(f"   * Passengers: {len(passengers)}")
        print(f"   * Rides: {len(rides)}")
        print(f"   * Payments: 3")
        print(f"\nBackend is ready for testing!")
        
    except Exception as e:
        print(f"\nERROR: {str(e)}")
        import traceback
        traceback.print_exc()
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    main()
