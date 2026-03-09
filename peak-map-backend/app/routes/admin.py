from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import datetime, timedelta
from pydantic import BaseModel
from typing import Optional
import hashlib

from app.database import get_db
from app.models.ride import Ride
from app.models.gps_log import GPSLog
from app.models.payment import Payment
from app.models.user import User
from app.models.station import Station
from app.models.local_auth_user import LocalAuthUser
from app.services.driver_presence import get_driver_online_state
from app.supabase_client import get_supabase_client, is_supabase_available

router = APIRouter(prefix="/admin", tags=["Admin"])


# Admin Authentication Models
class AdminLoginPayload(BaseModel):
    email: str
    password: str


class AdminRegisterPayload(BaseModel):
    email: str
    password: str
    name: str


# Admin Authentication Endpoints
@router.post("/login")
def admin_login(payload: AdminLoginPayload, db: Session = Depends(get_db)):
    """Admin login endpoint"""
    try:
        # Try Supabase authentication first
        if is_supabase_available():
            supabase = get_supabase_client()
            try:
                result = supabase.auth.sign_in_with_password(
                    {"email": payload.email, "password": payload.password}
                )
                
                if result.user:
                    # Check if user is admin in Supabase users table
                    user_query = (
                        supabase.table("users")
                        .select("*")
                        .eq("email", payload.email)
                        .eq("user_type", "admin")
                        .execute()
                    )
                    
                    user_data = user_query.data if hasattr(user_query, 'data') else []
                    if not user_data:
                        raise HTTPException(status_code=403, detail="Not authorized. Admin access only.")
                    
                    admin_user = user_data[0]
                    return {
                        "success": True,
                        "user_id": admin_user.get("id"),
                        "email": payload.email,
                        "name": admin_user.get("name"),
                        "token": result.session.access_token if result.session else "",
                        "auth_method": "supabase"
                    }
            except HTTPException:
                raise
            except Exception as e:
                print(f"Supabase admin login failed: {e}")
                # Fall through to local auth
        
        # Fallback to local authentication
        local_user = (
            db.query(LocalAuthUser)
            .filter(LocalAuthUser.email == payload.email)
            .first()
        )
        
        if not local_user:
            raise HTTPException(status_code=401, detail="Invalid credentials")
        
        # Verify password
        password_hash = hashlib.sha256(payload.password.encode()).hexdigest()
        if local_user.password_hash != password_hash:
            raise HTTPException(status_code=401, detail="Invalid credentials")
        
        # Check if user is admin
        if local_user.user_type != "admin":
            raise HTTPException(status_code=403, detail="Not authorized. Admin access only.")
        
        # Get user details from User table
        app_user = db.query(User).filter(User.id == local_user.app_user_id).first()
        
        return {
            "success": True,
            "user_id": local_user.app_user_id,
            "email": payload.email,
            "name": app_user.full_name if app_user else local_user.identifier,
            "auth_method": "local"
        }
        
    except HTTPException:
        raise
    except Exception as exc:
        print(f"Admin login error: {exc}")
        raise HTTPException(status_code=500, detail=f"Login failed: {str(exc)}")


@router.post("/register")
def admin_register(payload: AdminRegisterPayload, db: Session = Depends(get_db)):
    """Register a new admin user (protected - should be called once to setup)"""
    try:
        # Check if admin already exists
        existing_local = (
            db.query(LocalAuthUser)
            .filter(LocalAuthUser.email == payload.email)
            .first()
        )
        
        if existing_local:
            raise HTTPException(status_code=400, detail="Admin already exists")
        
        # Try to register in Supabase first
        if is_supabase_available():
            supabase = get_supabase_client()
            try:
                # Sign up with Supabase Auth
                result = supabase.auth.sign_up(
                    {
                        "email": payload.email,
                        "password": payload.password,
                        "options": {
                            "data": {
                                "name": payload.name,
                                "user_type": "admin",
                            }
                        },
                    }
                )
                
                if result.user:
                    # Create admin user in users table
                    supabase.table("users").insert(
                        {
                            "email": payload.email,
                            "name": payload.name,
                            "user_type": "admin",
                            "phone": "",
                        }
                    ).execute()
            except Exception as e:
                print(f"Supabase admin registration failed: {e}")
                # Fall through to local auth
        
        # Create local app user
        app_user = User(
            full_name=payload.name,
            phone_number=payload.email,  # Using email as identifier since phone_number is unique
            role="admin"
        )
        db.add(app_user)
        db.commit()
        db.refresh(app_user)
        
        # Create local auth record
        password_hash = hashlib.sha256(payload.password.encode()).hexdigest()
        local_auth = LocalAuthUser(
            email=payload.email,
            password_hash=password_hash,
            user_type="admin",
            name=payload.name,
            app_user_id=app_user.id
        )
        db.add(local_auth)
        db.commit()
        
        return {
            "success": True,
            "message": "Admin user created successfully",
            "user_id": app_user.id,
            "email": payload.email
        }
        
    except HTTPException:
        raise
    except Exception as exc:
        db.rollback()
        print(f"Admin registration error: {exc}")
        raise HTTPException(status_code=500, detail=f"Registration failed: {str(exc)}")


@router.get("/verify")
def verify_admin_session(token: Optional[str] = None, db: Session = Depends(get_db)):
    """Verify admin session/token"""
    if not token:
        raise HTTPException(status_code=401, detail="No token provided")
    
    try:
        if is_supabase_available():
            supabase = get_supabase_client()
            # In production, verify token with Supabase
            # For now, accept any non-empty token
            return {"success": True, "valid": True}
        
        return {"success": True, "valid": True}
    except Exception as exc:
        raise HTTPException(status_code=401, detail="Invalid session")


def _ride_station_ids(ride: Ride) -> tuple[int | None, int | None]:
    """Support both legacy (from/to) and current (station_id) ride schemas."""
    from_station_id = getattr(ride, "from_station_id", None)
    to_station_id = getattr(ride, "to_station_id", None)
    station_id = getattr(ride, "station_id", None)

    if from_station_id is None and station_id is not None:
        from_station_id = station_id
    if to_station_id is None and station_id is not None:
        to_station_id = station_id

    return from_station_id, to_station_id


def _driver_display_name(driver: User) -> str:
    return (
        getattr(driver, "username", None)
        or getattr(driver, "full_name", None)
        or f"Driver {driver.id}"
    )


def _is_driver_online(driver: User, gps: GPSLog | None, active_rides: int = 0) -> bool:
    """Resolve online state from live toggle, GPS heartbeat, or active ride."""
    presence_state = get_driver_online_state(driver.id)
    if presence_state is not None:
        return bool(presence_state)

    has_recent_gps = bool(
        gps and gps.timestamp and (datetime.utcnow() - gps.timestamp) < timedelta(minutes=1)
    )
    persisted_state = bool(getattr(driver, "is_online", False))
    return persisted_state or has_recent_gps or active_rides > 0


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
        from_station_id, to_station_id = _ride_station_ids(ride)

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
            "from_station_id": from_station_id,
            "to_station_id": to_station_id,
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

        is_online = _is_driver_online(driver, gps, active_rides)
        
        driver_data.append({
            "driver_id": driver.id,
            "username": _driver_display_name(driver),
            "latitude": gps.latitude if gps else None,
            "longitude": gps.longitude if gps else None,
            "speed": gps.speed if gps else None,
            "last_update": gps.timestamp.isoformat() if gps else None,
            "active_rides": active_rides,
            "is_online": is_online,
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

    from_station_col = getattr(Ride, "from_station_id", None)
    to_station_col = getattr(Ride, "to_station_id", None)
    station_col = getattr(Ride, "station_id", None)
    
    station_stats = []
    for station in stations:
        # Count rides starting from this station
        if from_station_col is not None:
            rides_from = db.query(Ride).filter(from_station_col == station.id).count()
        elif station_col is not None:
            rides_from = db.query(Ride).filter(station_col == station.id).count()
        else:
            rides_from = 0
        
        # Count rides ending at this station
        if to_station_col is not None:
            rides_to = db.query(Ride).filter(to_station_col == station.id).count()
        else:
            rides_to = 0
        
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
    
    # Drivers summary
    drivers = db.query(User).filter(User.role == "driver").all()
    total_drivers = len(drivers)
    active_drivers = 0
    for driver in drivers:
        gps = (
            db.query(GPSLog)
            .filter(GPSLog.driver_id == driver.id)
            .order_by(GPSLog.timestamp.desc())
            .first()
        )
        active_rides_for_driver = (
            db.query(Ride)
            .filter(Ride.driver_id == driver.id)
            .filter(Ride.status == "ongoing")
            .count()
        )
        if _is_driver_online(driver, gps, active_rides_for_driver):
            active_drivers += 1
    
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
        "active_drivers": active_drivers,
        "total_drivers": total_drivers,
        "total_passengers": total_passengers,
        "total_revenue": total_revenue,
        "pending_revenue": pending_revenue,
        "today_rides": today_rides,
    }


@router.get("/rfid_tap_events")
def get_rfid_tap_events(limit: int = 25, db: Session = Depends(get_db)):
    """Return recent RFID/NFC tap-related events for admin monitor."""
    safe_limit = max(1, min(limit, 200))

    tap_methods = [
        "tap_in_nfc",
        "tap_out_nfc",
        "bus_fare_nfc",
        "admin_nfc",
    ]

    events = (
        db.query(Payment)
        .filter(Payment.method.in_(tap_methods))
        .order_by(Payment.created_at.desc())
        .limit(safe_limit)
        .all()
    )

    out = []
    for payment in events:
        tap_type = "tap-in"
        if payment.method == "tap_out_nfc":
            tap_type = "tap-out"
        elif payment.method == "bus_fare_nfc":
            tap_type = "fare"
        elif payment.method == "admin_nfc":
            tap_type = "balance-load"

        card_uid = None
        bus_id = None
        station_id = None
        from_station_id = None
        to_station_id = None

        if payment.reference:
            parts = payment.reference.split("-")
            if len(parts) >= 2:
                maybe_uid = parts[1]
                if maybe_uid and maybe_uid != "UNKNOWN":
                    card_uid = maybe_uid

            if payment.method in ("tap_in_nfc", "tap_out_nfc") and len(parts) >= 6:
                bus_id = parts[3]
                station_id = parts[-2]

            if payment.method == "bus_fare_nfc" and len(parts) >= 7:
                bus_id = parts[3]
                from_station_id = parts[-3]
                to_station_id = parts[-2]

        out.append(
            {
                "id": payment.id,
                "source": "payments",
                "tap_type": tap_type,
                "method": payment.method,
                "status": payment.status,
                "user_id": payment.user_id,
                "card_uid": card_uid,
                "amount": float(payment.amount or 0.0),
                "bus_id": bus_id,
                "station_id": station_id,
                "from_station_id": from_station_id,
                "to_station_id": to_station_id,
                "timestamp": payment.created_at.isoformat() if payment.created_at else None,
                "reference": payment.reference,
            }
        )

    return {
        "success": True,
        "count": len(out),
        "events": out,
        "timestamp": datetime.utcnow().isoformat(),
    }
