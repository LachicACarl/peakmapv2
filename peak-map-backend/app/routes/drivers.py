"""Driver management endpoints"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel

from app.database import get_db
from app.models.user import User
from app.models.gps_log import GPSLog

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
            "is_online": getattr(driver, 'is_online', False),
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
    
    return {
        "id": driver.id,
        "full_name": driver.full_name,
        "phone_number": driver.phone_number,
        "role": driver.role,
        "is_online": getattr(driver, 'is_online', False),
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
    
    # Update driver status in database
    if not hasattr(driver, 'is_online'):
        setattr(driver, 'is_online', status.is_online)
    else:
        driver.is_online = status.is_online
    
    db.commit()
    db.refresh(driver)
    
    return {
        "message": "Driver status updated",
        "driver_id": driver.id,
        "is_online": getattr(driver, 'is_online', False),
        "status": "online" if getattr(driver, 'is_online', False) else "offline"
    }
