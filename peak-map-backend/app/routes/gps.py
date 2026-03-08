from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.gps_log import GPSLog
from app.services.driver_presence import mark_driver_online

router = APIRouter(prefix="/gps", tags=["GPS"])


class GPSUpdate(BaseModel):
    driver_id: int
    latitude: float
    longitude: float
    speed: float = 0


class GPSOut(BaseModel):
    id: int
    driver_id: int
    latitude: float
    longitude: float
    speed: float
    timestamp: str

    class Config:
        from_attributes = True


@router.post("/update", response_model=dict)
def update_gps(data: GPSUpdate, db: Session = Depends(get_db)):
    """Driver sends GPS updates every 3-5 seconds"""
    gps = GPSLog(
        driver_id=data.driver_id,
        latitude=data.latitude,
        longitude=data.longitude,
        speed=data.speed
    )

    db.add(gps)
    db.commit()
    db.refresh(gps)

    # A fresh GPS heartbeat means the driver is actively online.
    mark_driver_online(data.driver_id, source="gps_update")

    return {"status": "GPS updated", "id": gps.id}


@router.get("/latest/{driver_id}", response_model=dict)
def get_latest_gps(driver_id: int, db: Session = Depends(get_db)):
    """Get driver's latest GPS location"""
    gps = (
        db.query(GPSLog)
        .filter(GPSLog.driver_id == driver_id)
        .order_by(GPSLog.timestamp.desc())
        .first()
    )

    if not gps:
        return {"error": "No GPS data"}

    return {
        "id": gps.id,
        "driver_id": gps.driver_id,
        "latitude": gps.latitude,
        "longitude": gps.longitude,
        "speed": gps.speed,
        "timestamp": str(gps.timestamp)
    }
