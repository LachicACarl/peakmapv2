"""Driver management endpoints"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel

from app.database import get_db
from app.models.user import User
from app.models.gps_log import GPSLog
from app.models.payment import Payment
from app.services.driver_presence import get_driver_online_state, set_driver_online_state

router = APIRouter(prefix="/drivers", tags=["Drivers"])


class DriverStatus(BaseModel):
    is_online: bool


class DriverOut(BaseModel):
    id: int
    full_name: str
    phone_number: str
    role: str
    is_online: bool = False
    latitude: float | None = None
    longitude: float | None = None
    speed: float | None = None
    
    class Config:
        from_attributes = True


@router.get("/", response_model=list[dict])
def get_drivers(db: Session = Depends(get_db)):
    """Get all drivers with their current status"""
    drivers = db.query(User).filter(User.role == "driver").all()
    
    driver_data = []
    for driver in drivers:
        presence_state = get_driver_online_state(driver.id)
        # Get latest GPS
        gps = (
            db.query(GPSLog)
            .filter(GPSLog.driver_id == driver.id)
            .order_by(GPSLog.timestamp.desc())
            .first()
        )
        
        driver_data.append({
            "id": driver.id,
            "full_name": driver.full_name,
            "phone_number": driver.phone_number,
            "role": driver.role,
            "is_online": presence_state if presence_state is not None else bool(getattr(driver, "is_online", False)),
            "latitude": gps.latitude if gps else None,
            "longitude": gps.longitude if gps else None,
            "speed": gps.speed if gps else None,
            "last_update": gps.timestamp.isoformat() if gps else None,
        })
    
    return driver_data


@router.get("/{driver_id}", response_model=dict)
def get_driver(driver_id: int, db: Session = Depends(get_db)):
    """Get specific driver details"""
    driver = db.query(User).filter(User.id == driver_id, User.role == "driver").first()
    
    if not driver:
        raise HTTPException(status_code=404, detail="Driver not found")
    
    # Get latest GPS
    gps = (
        db.query(GPSLog)
        .filter(GPSLog.driver_id == driver_id)
        .order_by(GPSLog.timestamp.desc())
        .first()
    )
    presence_state = get_driver_online_state(driver.id)
    
    return {
        "id": driver.id,
        "full_name": driver.full_name,
        "phone_number": driver.phone_number,
        "role": driver.role,
        "is_online": presence_state if presence_state is not None else bool(getattr(driver, "is_online", False)),
        "latitude": gps.latitude if gps else None,
        "longitude": gps.longitude if gps else None,
        "speed": gps.speed if gps else None,
        "last_update": gps.timestamp.isoformat() if gps else None,
    }


@router.put("/{driver_id}/status", response_model=dict)
def update_driver_status(driver_id: int, status: DriverStatus, db: Session = Depends(get_db)):
    """Update driver online/offline status"""
    driver = db.query(User).filter(User.id == driver_id, User.role == "driver").first()
    
    if not driver:
        raise HTTPException(status_code=404, detail="Driver not found")
    
    # Persist status only when schema supports it; always keep runtime presence in sync.
    if hasattr(User, 'is_online'):
        driver.is_online = status.is_online
        db.commit()
        db.refresh(driver)

    set_driver_online_state(driver.id, status.is_online, source="driver_toggle")

    current_state = get_driver_online_state(driver.id)
    is_online = current_state if current_state is not None else bool(getattr(driver, 'is_online', False))
    
    return {
        "message": "Driver status updated",
        "driver_id": driver.id,
        "is_online": is_online,
        "status": "online" if is_online else "offline"
    }


@router.get("/{driver_id}/passenger-count", response_model=dict)
def get_driver_passenger_count(driver_id: int, db: Session = Depends(get_db)):
    """Get current passenger count for a driver (passengers who tapped in but haven't tapped out)"""
    driver = db.query(User).filter(User.id == driver_id, User.role == "driver").first()
    
    if not driver:
        raise HTTPException(status_code=404, detail="Driver not found")
    
    # Count all pending tap-ins (open trips) for this driver
    # These are passengers who tapped in but haven't tapped out yet
    open_trips = db.query(Payment).filter(
        Payment.method == "tap_in_nfc",
        Payment.status == "pending",  # pending means they haven't tapped out
        Payment.reference.like(f"%{driver_id}%")  # reference format: TAPIN-{user_id}-{bus_id}-{station_id}-{timestamp}
    ).all()
    
    # Extract passenger details from open trips
    passengers = []
    for trip in open_trips:
        # Parse reference to get boarding station
        ref_parts = trip.reference.split("-") if trip.reference else []
        station_id = ref_parts[3] if len(ref_parts) >= 4 else "unknown"
        
        passengers.append({
            "user_id": trip.user_id,
            "tap_in_time": trip.created_at.isoformat() if trip.created_at else None,
            "boarding_station_id": station_id,
            "trip_reference": trip.reference,
        })
    
    return {
        "driver_id": driver_id,
        "passenger_count": len(open_trips),
        "passengers": passengers,
        "timestamp": __import__("datetime").datetime.utcnow().isoformat(),
    }
