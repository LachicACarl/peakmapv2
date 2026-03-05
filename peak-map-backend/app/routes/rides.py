from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.gps_log import GPSLog
from app.models.ride import Ride
from app.models.station import Station
from app.models.user import User
from app.services.dropoff_service import check_dropoff
from app.utils.geo import distance_in_meters

router = APIRouter(prefix="/rides", tags=["Rides"])


class RideCreate(BaseModel):
    passenger_id: int
    driver_id: int | None = None
    station_id: int


class RideOut(BaseModel):
    id: int
    passenger_id: int
    driver_id: int
    station_id: int
    status: str
    started_at: str
    ended_at: str | None

    class Config:
        from_attributes = True


@router.post("/", response_model=dict)
def create_ride(ride: RideCreate, db: Session = Depends(get_db)):
    """Create a new ride when passenger boards the bus"""
    # Validate passenger exists
    passenger = db.query(User).filter(User.id == ride.passenger_id).first()
    if not passenger:
        raise HTTPException(status_code=404, detail="Passenger not found")

    # Validate station exists
    station = db.query(Station).filter(Station.id == ride.station_id).first()
    if not station:
        raise HTTPException(status_code=404, detail="Station not found")

    # Driver can be provided explicitly, otherwise we auto-pick one
    driver_id = ride.driver_id
    if driver_id is None:
        selected_driver = (
            db.query(User)
            .filter(User.role == "driver")
            .order_by(User.id.asc())
            .first()
        )
        if not selected_driver:
            raise HTTPException(status_code=400, detail="No drivers available")
        driver_id = selected_driver.id
    else:
        driver = (
            db.query(User)
            .filter(User.id == driver_id, User.role == "driver")
            .first()
        )
        if not driver:
            raise HTTPException(status_code=404, detail="Driver not found")

    # Calculate fare
    from app.services.fare_service import get_fare
    fare_amount = get_fare(db, from_station_id=1, to_station_id=ride.station_id)
    
    new_ride = Ride(
        passenger_id=ride.passenger_id,
        driver_id=driver_id,
        station_id=ride.station_id,
        fare_amount=fare_amount if fare_amount else 0.0,
        status="ongoing"
    )
    
    db.add(new_ride)
    db.commit()
    db.refresh(new_ride)
    
    return {
        "message": "Ride started",
        "id": new_ride.id,
        "ride_id": new_ride.id,
        "passenger_id": new_ride.passenger_id,
        "driver_id": new_ride.driver_id,
        "station_id": new_ride.station_id,
        "fare_amount": new_ride.fare_amount,
        "status": new_ride.status
    }


@router.get("/{ride_id}", response_model=dict)
def get_ride(ride_id: int, db: Session = Depends(get_db)):
    """Get ride details"""
    ride = db.query(Ride).filter(Ride.id == ride_id).first()
    
    if not ride:
        return {"error": "Ride not found"}
    
    station = db.query(Station).filter(Station.id == ride.station_id).first()
    
    return {
        "id": ride.id,
        "passenger_id": ride.passenger_id,
        "driver_id": ride.driver_id,
        "station_id": ride.station_id,
        "station_name": station.name if station else "Unknown",
        "status": ride.status,
        "started_at": str(ride.started_at),
        "ended_at": str(ride.ended_at) if ride.ended_at else None
    }


@router.post("/check/{ride_id}", response_model=dict)
def check_ride_status(ride_id: int, db: Session = Depends(get_db)):
    """
    Check if passenger has been dropped off or missed their station.
    This should be called periodically (every GPS update).
    """
    ride = db.query(Ride).filter(Ride.id == ride_id).first()
    
    if not ride:
        return {"error": "Ride not found"}
    
    if ride.status != "ongoing":
        return {
            "status": ride.status,
            "message": f"Ride already {ride.status}",
            "ended_at": str(ride.ended_at)
        }
    
    station = db.query(Station).filter(Station.id == ride.station_id).first()
    
    if not station:
        return {"error": "Station not found"}
    
    # Get last 2 GPS logs to detect movement pattern
    gps_logs = (
        db.query(GPSLog)
        .filter(GPSLog.driver_id == ride.driver_id)
        .order_by(GPSLog.timestamp.desc())
        .limit(2)
        .all()
    )

    if len(gps_logs) < 1:
        return {"status": "waiting", "message": "No GPS data available"}
    
    current = gps_logs[0]

    # DROP-OFF CHECK
    # If driver is within station radius, passenger has arrived
    if check_dropoff(current.latitude, current.longitude, station):
        ride.status = "dropped"
        ride.ended_at = datetime.utcnow()
        db.commit()
        
        return {
            "status": "dropped",
            "message": "Passenger has arrived at station",
            "station_name": station.name,
            "ended_at": str(ride.ended_at)
        }

    # MISSED CHECK
    # Only check if we have 2 GPS points to compare
    if len(gps_logs) >= 2:
        previous = gps_logs[1]
        
        prev_dist = distance_in_meters(
            previous.latitude, previous.longitude,
            station.latitude, station.longitude
        )

        curr_dist = distance_in_meters(
            current.latitude, current.longitude,
            station.latitude, station.longitude
        )
        
        # If distance is increasing (moving away) without entering radius
        # Add 20m buffer to avoid false positives
        if curr_dist > prev_dist + 20:
            ride.status = "missed"
            ride.ended_at = datetime.utcnow()
            db.commit()
            
            return {
                "status": "missed",
                "message": "⚠️ Passenger missed their stop!",
                "station_name": station.name,
                "ended_at": str(ride.ended_at),
                "distance_from_station": round(curr_dist, 2)
            }

    # Still on the way
    curr_dist = distance_in_meters(
        current.latitude, current.longitude,
        station.latitude, station.longitude
    )
    
    return {
        "status": "ongoing",
        "message": "On the way to station",
        "station_name": station.name,
        "distance_to_station": round(curr_dist, 2),
        "driver_speed": current.speed
    }


@router.get("/", response_model=list[dict])
def get_rides(driver_id: int | None = None, passenger_id: int | None = None, 
              status: str | None = None, db: Session = Depends(get_db)):
    """Get all rides with optional filters"""
    query = db.query(Ride)
    
    if driver_id:
        query = query.filter(Ride.driver_id == driver_id)
    if passenger_id:
        query = query.filter(Ride.passenger_id == passenger_id)
    if status:
        query = query.filter(Ride.status == status)
    
    rides = query.all()
    
    result = []
    for ride in rides:
        station = db.query(Station).filter(Station.id == ride.station_id).first()
        result.append({
            "id": ride.id,
            "passenger_id": ride.passenger_id,
            "driver_id": ride.driver_id,
            "station_id": ride.station_id,
            "station_name": station.name if station else "Unknown",
            "status": ride.status,
            "started_at": str(ride.started_at),
            "ended_at": str(ride.ended_at) if ride.ended_at else None
        })
    
    return result


@router.put("/{ride_id}", response_model=dict)
def update_ride(ride_id: int, ride_update: dict, db: Session = Depends(get_db)):
    """Update ride status (e.g., mark as completed)"""
    ride = db.query(Ride).filter(Ride.id == ride_id).first()
    
    if not ride:
        return {"error": "Ride not found"}
    
    # Update status if provided
    if "status" in ride_update:
        ride.status = ride_update["status"]
        
        # If marking as completed/ended, set the ended_at timestamp
        if ride_update["status"] in ["completed", "dropped", "missed", "cancelled"]:
            ride.ended_at = datetime.utcnow()
    
    db.commit()
    db.refresh(ride)
    
    station = db.query(Station).filter(Station.id == ride.station_id).first()
    
    return {
        "message": "Ride updated",
        "id": ride.id,
        "status": ride.status,
        "station_name": station.name if station else "Unknown",
        "ended_at": str(ride.ended_at) if ride.ended_at else None
    }
