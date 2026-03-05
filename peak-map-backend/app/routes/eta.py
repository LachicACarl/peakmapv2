from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.gps_log import GPSLog
from app.models.station import Station
from app.services.eta_service import calculate_eta

router = APIRouter(prefix="/eta", tags=["ETA"])


@router.get("/")
def get_eta(driver_id: int, station_id: int, db: Session = Depends(get_db)):
    """
    Calculate ETA from driver's current location to a station
    Uses real-time traffic data from Google Maps
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

    # Calculate ETA using Google Maps
    eta = calculate_eta(
        gps.latitude,
        gps.longitude,
        station.latitude,
        station.longitude
    )

    return {
        **eta,
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
