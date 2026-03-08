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
from app.models.route_segment import RouteSegment

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
        db.query(RouteSegment).delete()
        db.query(Fare).delete()
        db.query(Station).delete()
        db.query(User).delete()
        db.commit()
        print("[OK] Database cleared")
    except Exception as e:
        print(f"[ERROR] Error clearing database: {e}")
        db.rollback()

def seed_stations():
    """Seed station data - Real EDSA Bus Carousel Route (Monumento to PITX)"""
    print("\n[STATIONS] Seeding stations...")
    
    stations_data = [
        # Northbound stations (Order 1-22)
        {
            "name": "Monumento",
            "latitude": 14.6542,
            "longitude": 120.9844,
            "radius": 200,
            "order": 1
        },
        {
            "name": "Bagong Barrio",
            "latitude": 14.6480,
            "longitude": 120.9870,
            "radius": 200,
            "order": 2
        },
        {
            "name": "Balintawak",
            "latitude": 14.6390,
            "longitude": 120.9920,
            "radius": 200,
            "order": 3
        },
        {
            "name": "Kaingin",
            "latitude": 14.6310,
            "longitude": 120.9980,
            "radius": 200,
            "order": 4
        },
        {
            "name": "Roosevelt",
            "latitude": 14.6250,
            "longitude": 121.0020,
            "radius": 200,
            "order": 5
        },
        {
            "name": "North Avenue",
            "latitude": 14.6199,
            "longitude": 121.0244,
            "radius": 200,
            "order": 6
        },
        {
            "name": "Quezon Avenue",
            "latitude": 14.6119,
            "longitude": 121.0350,
            "radius": 200,
            "order": 7
        },
        {
            "name": "Kamuning",
            "latitude": 14.6040,
            "longitude": 121.0420,
            "radius": 200,
            "order": 8
        },
        {
            "name": "Nepa Q-Mart",
            "latitude": 14.5990,
            "longitude": 121.0460,
            "radius": 200,
            "order": 9
        },
        {
            "name": "Main Avenue (Cubao)",
            "latitude": 14.6180,
            "longitude": 121.0540,
            "radius": 200,
            "order": 10
        },
        {
            "name": "Santolan",
            "latitude": 14.6100,
            "longitude": 121.0560,
            "radius": 200,
            "order": 11
        },
        {
            "name": "Ortigas",
            "latitude": 14.5850,
            "longitude": 121.0560,
            "radius": 200,
            "order": 12
        },
        {
            "name": "Guadalupe",
            "latitude": 14.5650,
            "longitude": 121.0430,
            "radius": 200,
            "order": 13
        },
        {
            "name": "Buendia",
            "latitude": 14.5560,
            "longitude": 121.0320,
            "radius": 200,
            "order": 14
        },
        {
            "name": "Ayala",
            "latitude": 14.5470,
            "longitude": 121.0280,
            "radius": 200,
            "order": 15
        },
        {
            "name": "Tramo",
            "latitude": 14.5380,
            "longitude": 121.0190,
            "radius": 200,
            "order": 16
        },
        {
            "name": "Taft Avenue",
            "latitude": 14.5380,
            "longitude": 121.0010,
            "radius": 200,
            "order": 17
        },
        {
            "name": "Roxas Boulevard",
            "latitude": 14.5350,
            "longitude": 120.9940,
            "radius": 200,
            "order": 18
        },
        {
            "name": "SM Mall of Asia",
            "latitude": 14.5350,
            "longitude": 120.9820,
            "radius": 200,
            "order": 19
        },
        {
            "name": "DFA Aseana",
            "latitude": 14.5290,
            "longitude": 120.9880,
            "radius": 200,
            "order": 20
        },
        {
            "name": "Ayala Malls Manila Bay",
            "latitude": 14.5230,
            "longitude": 120.9920,
            "radius": 200,
            "order": 21
        },
        {
            "name": "PITX",
            "latitude": 14.5194,
            "longitude": 121.0017,
            "radius": 200,
            "order": 22
        },
    ]
    
    for station_data in stations_data:
        station = Station(**station_data)
        db.add(station)
    
    db.commit()
    print(f"[OK] Added {len(stations_data)} stations")
    return db.query(Station).all()

def seed_route_segments(stations):
    """Seed route segments with travel times between consecutive stations"""
    print("\n[ROUTE SEGMENTS] Seeding station-to-station segments...")
    
    # Create station lookup by order
    station_by_order = {s.order: s for s in stations if s.order is not None}
    
    # Real EDSA Carousel segment data (order, distance_km, avg_time_minutes)
    # Based on 23.8 km total distance, 60-75 min total time
    segments_data = [
        # From -> To: distance (km), time (minutes)
        (1, 2, 1.5, 3),    # Monumento -> Bagong Barrio
        (2, 3, 1.8, 4),    # Bagong Barrio -> Balintawak
        (3, 4, 1.5, 3),    # Balintawak -> Kaingin
        (4, 5, 1.2, 3),    # Kaingin -> Roosevelt
        (5, 6, 1.0, 2),    # Roosevelt -> North Avenue
        (6, 7, 1.5, 4),    # North Avenue -> Quezon Avenue
        (7, 8, 1.0, 3),    # Quezon Avenue -> Kamuning
        (8, 9, 0.8, 2),    # Kamuning -> Nepa Q-Mart
        (9, 10, 1.2, 3),   # Nepa Q-Mart -> Cubao
        (10, 11, 1.0, 3),  # Cubao -> Santolan
        (11, 12, 2.0, 5),  # Santolan -> Ortigas
        (12, 13, 2.5, 6),  # Ortigas -> Guadalupe
        (13, 14, 1.5, 4),  # Guadalupe -> Buendia
        (14, 15, 1.2, 3),  # Buendia -> Ayala
        (15, 16, 1.5, 4),  # Ayala -> Tramo
        (16, 17, 1.0, 3),  # Tramo -> Taft Avenue
        (17, 18, 0.8, 2),  # Taft Avenue -> Roxas Blvd
        (18, 19, 1.2, 3),  # Roxas Blvd -> SM Mall of Asia
        (19, 20, 0.8, 2),  # SM MOA -> DFA Aseana
        (20, 21, 1.0, 2),  # DFA Aseana -> Ayala Manila Bay
        (21, 22, 0.8, 2),  # Ayala Manila Bay -> PITX
    ]
    
    segments = []
    for from_order, to_order, distance_km, avg_time_minutes in segments_data:
        from_station = station_by_order.get(from_order)
        to_station = station_by_order.get(to_order)
        
        if from_station and to_station:
            segment = RouteSegment(
                from_station_id=from_station.id,
                to_station_id=to_station.id,
                distance_km=distance_km,
                avg_time_minutes=avg_time_minutes,
                stop_delay_seconds=30  # 30 seconds per station stop
            )
            db.add(segment)
            segments.append(segment)
    
    db.commit()
    print(f"[OK] Added {len(segments)} route segments")
    return segments

def seed_fares(stations):
    """Seed fare data using user-provided per-station table."""
    print("\n[FARES] Seeding fares...")

    minimum_fare = 15.0
    station_id_by_name = {station.name: station.id for station in stations}

    north_bound = [
        ("PITX", 0.0),
        ("City of Dreams", 15.0),
        ("DFA", 15.0),
        ("Roxas Boulevard", 15.0),
        ("Taft Avenue", 15.0),
        ("Ayala", 24.0),
        ("Buendia", 26.5),
        ("Guadalupe", 31.5),
        ("Ortigas", 38.0),
        ("Santolan", 44.75),
        ("Main Avenue", 46.5),
        ("Nepa Q. Mart", 51.25),
        ("Quezon Avenue", 55.5),
        ("North Avenue", 59.0),
        ("Roosevelt", 63.5),
        ("Kaingin", 65.75),
        ("Balintawak", 67.75),
        ("Bagong Barrio", 69.5),
        ("Monumento", 73.0),
    ]

    south_bound = [
        ("Monumento", 0.0),
        ("Bagong Barrio", 15.0),
        ("Balintawak", 15.0),
        ("Kaingin", 15.0),
        ("Roosevelt", 15.0),
        ("North Avenue", 15.75),
        ("Quezon Avenue", 19.25),
        ("Nepa Q. Mart", 23.5),
        ("Main Avenue", 28.0),
        ("Santolan", 29.75),
        ("Ortigas", 36.5),
        ("Guadalupe", 42.75),
        ("Buendia", 48.0),
        ("One Ayala", 50.25),
        ("Tramo", 58.75),
        ("Taft Avenue", 59.5),
        ("Roxas Boulevard", 62.0),
        ("MoA", 64.25),
        ("DFA", 68.0),
        ("Ayala Malls Manila Bay", 71.75),
        ("PITX", 75.5),
    ]

    fare_routes = {}

    def add_direction_fares(route):
        for start_index, (from_name, from_cumulative) in enumerate(route[:-1]):
            from_station_id = station_id_by_name.get(from_name)
            if from_station_id is None:
                continue

            for to_name, to_cumulative in route[start_index + 1:]:
                to_station_id = station_id_by_name.get(to_name)
                if to_station_id is None:
                    continue

                computed_fare = max(to_cumulative - from_cumulative, minimum_fare)
                fare_routes[(from_station_id, to_station_id)] = round(computed_fare, 2)

    add_direction_fares(north_bound)
    add_direction_fares(south_bound)

    for (from_station_id, to_station_id), amount in fare_routes.items():
        fare = Fare(
            from_station=from_station_id,
            to_station=to_station_id,
            amount=amount,
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
        route_segments = seed_route_segments(stations)
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
        print(f"   * Route Segments: {len(route_segments)}")
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
