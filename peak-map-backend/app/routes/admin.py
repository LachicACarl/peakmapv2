from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import datetime, timedelta

from app.database import get_db
from app.models.ride import Ride
from app.models.gps_log import GPSLog
from app.models.payment import Payment
from app.models.user import User
from app.models.station import Station

router = APIRouter(prefix="/admin", tags=["Admin"])


@router.get("/active_rides")
def get_active_rides(db: Session = Depends(get_db)):
    """
    Get all active rides with driver positions.
    
    Returns:
    [
        {
            "ride_id": 1,
            "passenger_id": 2,
            "driver_id": 1,
            "from_station_id": 1,
            "to_station_id": 5,
            "status": "ongoing",
            "fare_amount": 45.0,
            "driver_lat": 14.6199,
            "driver_lng": 121.0540,
            "driver_speed": 15.5,
            "last_update": "2026-02-18T10:30:00"
        }
    ]
    """
    rides = (
        db.query(Ride)
        .filter(Ride.status.in_(["ongoing", "dropped", "missed"]))
        .all()
    )

    ride_data = []
    for ride in rides:
        # Get latest GPS for this driver
        gps = (
            db.query(GPSLog)
            .filter(GPSLog.driver_id == ride.driver_id)
            .order_by(GPSLog.timestamp.desc())
            .first()
        )

        ride_data.append({
            "ride_id": ride.id,
            "passenger_id": ride.passenger_id,
            "driver_id": ride.driver_id,
            "from_station_id": ride.from_station_id,
            "to_station_id": ride.to_station_id,
            "status": ride.status,
            "fare_amount": ride.fare_amount,
            "driver_lat": gps.latitude if gps else None,
            "driver_lng": gps.longitude if gps else None,
            "driver_speed": gps.speed if gps else None,
            "last_update": gps.timestamp.isoformat() if gps else None,
        })

    return ride_data


@router.get("/all_drivers")
def get_all_drivers(db: Session = Depends(get_db)):
    """
    Get all drivers with their latest GPS positions.
    
    Returns:
    [
        {
            "driver_id": 1,
            "username": "driver_juan",
            "latitude": 14.6199,
            "longitude": 121.0540,
            "speed": 15.5,
            "last_update": "2026-02-18T10:30:00",
            "active_rides": 2
        }
    ]
    """
    drivers = db.query(User).filter(User.role == "driver").all()
    
    driver_data = []
    for driver in drivers:
        # Get latest GPS
        gps = (
            db.query(GPSLog)
            .filter(GPSLog.driver_id == driver.id)
            .order_by(GPSLog.timestamp.desc())
            .first()
        )
        
        # Count active rides
        active_rides = (
            db.query(Ride)
            .filter(Ride.driver_id == driver.id)
            .filter(Ride.status == "ongoing")
            .count()
        )
        
        driver_data.append({
            "driver_id": driver.id,
            "username": driver.username,
            "latitude": gps.latitude if gps else None,
            "longitude": gps.longitude if gps else None,
            "speed": gps.speed if gps else None,
            "last_update": gps.timestamp.isoformat() if gps else None,
            "active_rides": active_rides,
        })
    
    return driver_data


@router.get("/payments_summary")
def get_payments_summary(db: Session = Depends(get_db)):
    """
    Get payment statistics.
    
    Returns:
    {
        "total_paid": 450.0,
        "total_pending": 90.0,
        "total_failed": 0.0,
        "total_payments": 12,
        "paid_count": 10,
        "pending_count": 2,
        "failed_count": 0
    }
    """
    payments = db.query(Payment).all()
    
    total_paid = sum(p.amount for p in payments if p.status == "paid")
    total_pending = sum(p.amount for p in payments if p.status == "pending")
    total_failed = sum(p.amount for p in payments if p.status == "failed")
    
    paid_count = sum(1 for p in payments if p.status == "paid")
    pending_count = sum(1 for p in payments if p.status == "pending")
    failed_count = sum(1 for p in payments if p.status == "failed")
    
    return {
        "total_paid": total_paid,
        "total_pending": total_pending,
        "total_failed": total_failed,
        "total_payments": len(payments),
        "paid_count": paid_count,
        "pending_count": pending_count,
        "failed_count": failed_count,
    }


@router.get("/payments_by_method")
def get_payments_by_method(db: Session = Depends(get_db)):
    """
    Get payment breakdown by method (cash, gcash, ewallet).
    
    Returns:
    {
        "cash": {"count": 5, "amount": 225.0},
        "gcash": {"count": 3, "amount": 135.0},
        "ewallet": {"count": 2, "amount": 90.0}
    }
    """
    payments = db.query(Payment).all()
    
    by_method = {}
    for payment in payments:
        method = payment.method
        if method not in by_method:
            by_method[method] = {"count": 0, "amount": 0.0}
        
        by_method[method]["count"] += 1
        by_method[method]["amount"] += payment.amount
    
    return by_method


@router.get("/rides_stats")
def get_rides_stats(db: Session = Depends(get_db)):
    """
    Get ride statistics.
    
    Returns:
    {
        "total_rides": 50,
        "ongoing": 5,
        "completed": 40,
        "dropped": 38,
        "missed": 2,
        "cancelled": 3
    }
    """
    total_rides = db.query(Ride).count()
    
    ongoing = db.query(Ride).filter(Ride.status == "ongoing").count()
    completed = db.query(Ride).filter(Ride.status == "completed").count()
    dropped = db.query(Ride).filter(Ride.status == "dropped").count()
    missed = db.query(Ride).filter(Ride.status == "missed").count()
    cancelled = db.query(Ride).filter(Ride.status == "cancelled").count()
    
    return {
        "total_rides": total_rides,
        "ongoing": ongoing,
        "completed": completed,
        "dropped": dropped,
        "missed": missed,
        "cancelled": cancelled,
    }


@router.get("/recent_activity")
def get_recent_activity(db: Session = Depends(get_db), limit: int = 20):
    """
    Get recent activity (rides created, payments made).
    
    Returns recent rides and payments sorted by timestamp.
    """
    # Get recent rides
    recent_rides = (
        db.query(Ride)
        .order_by(Ride.started_at.desc())
        .limit(limit)
        .all()
    )
    
    # Get recent payments
    recent_payments = (
        db.query(Payment)
        .order_by(Payment.created_at.desc())
        .limit(limit)
        .all()
    )
    
    activity = []
    
    for ride in recent_rides:
        activity.append({
            "type": "ride",
            "id": ride.id,
            "status": ride.status,
            "driver_id": ride.driver_id,
            "passenger_id": ride.passenger_id,
            "timestamp": ride.started_at.isoformat(),
        })
    
    for payment in recent_payments:
        activity.append({
            "type": "payment",
            "id": payment.id,
            "status": payment.status,
            "method": payment.method,
            "amount": payment.amount,
            "ride_id": payment.ride_id,
            "timestamp": payment.created_at.isoformat(),
        })
    
    # Sort by timestamp
    activity.sort(key=lambda x: x["timestamp"], reverse=True)
    
    return activity[:limit]


@router.get("/stations_overview")
def get_stations_overview(db: Session = Depends(get_db)):
    """
    Get statistics per station.
    
    Returns ride counts per station (as origin and destination).
    """
    stations = db.query(Station).all()
    
    station_stats = []
    for station in stations:
        # Count rides starting from this station
        rides_from = (
            db.query(Ride)
            .filter(Ride.from_station_id == station.id)
            .count()
        )
        
        # Count rides ending at this station
        rides_to = (
            db.query(Ride)
            .filter(Ride.to_station_id == station.id)
            .count()
        )
        
        station_stats.append({
            "station_id": station.id,
            "name": station.name,
            "latitude": station.latitude,
            "longitude": station.longitude,
            "rides_from": rides_from,
            "rides_to": rides_to,
            "total_traffic": rides_from + rides_to,
        })
    
    return station_stats


@router.get("/dashboard_overview")
def get_dashboard_overview(db: Session = Depends(get_db)):
    """
    Get complete dashboard overview in one call.
    
    Combines key metrics for admin dashboard.
    """
    # Active rides count
    active_rides = db.query(Ride).filter(Ride.status == "ongoing").count()
    
    # Total drivers
    total_drivers = db.query(User).filter(User.role == "driver").count()
    
    # Total passengers
    total_passengers = db.query(User).filter(User.role == "passenger").count()
    
    # Payment stats
    payments = db.query(Payment).all()
    total_revenue = sum(p.amount for p in payments if p.status == "paid")
    pending_revenue = sum(p.amount for p in payments if p.status == "pending")
    
    # Today's rides
    today_start = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
    today_rides = (
        db.query(Ride)
        .filter(Ride.started_at >= today_start)
        .count()
    )
    
    return {
        "active_rides": active_rides,
        "total_drivers": total_drivers,
        "total_passengers": total_passengers,
        "total_revenue": total_revenue,
        "pending_revenue": pending_revenue,
        "today_rides": today_rides,
    }
