from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.gps_log import GPSLog
from app.models.station import Station
from app.services.eta_calculator import calculate_eta_minutes, calculate_eta_for_ride

router = APIRouter(prefix="/eta", tags=["ETA"])


@router.get("/")
def get_eta(driver_id: int, station_id: int, db: Session = Depends(get_db)):
    """
    Calculate ETA from driver's current location to a station
    Uses EDSA Bus Carousel route segments for accurate calculation
    """
    # Get driver's latest GPS location
    gps = (
        db.query(GPSLog)
        .filter(GPSLog.driver_id == driver_id)
        .order_by(GPSLog.timestamp.desc())
        .first()
    )

    # Get destination station
    station = db.query(Station).filter(Station.id == station_id).first()

    if not gps:
        return {"error": "No GPS data found for this driver"}

    if not station:
        return {"error": "Station not found"}

    # Calculate ETA using route segments
    eta_data = calculate_eta_minutes(
        gps.latitude,
        gps.longitude,
        station_id,
        db,
        traffic_factor=1.0  # Can be adjusted based on time of day
    )

    return {
        **eta_data,
        "driver_id": driver_id,
        "station_id": station_id,
        "station_name": station.name,
        "driver_location": {
            "latitude": gps.latitude,
            "longitude": gps.longitude,
            "speed": gps.speed,
            "last_update": str(gps.timestamp)
        }
    }


@router.get("/ride/{ride_id}")
def get_ride_eta(ride_id: int, db: Session = Depends(get_db)):
    """
    Calculate ETA for a specific ride
    Returns estimated time to passenger's destination
    """
    eta_data = calculate_eta_for_ride(ride_id, db)
    
    if "error" in eta_data:
        raise HTTPException(status_code=404, detail=eta_data["error"])
    
    return eta_data
