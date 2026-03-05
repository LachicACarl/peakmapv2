from sqlalchemy.orm import Session

from app.models.fare import Fare


def get_fare(db: Session, from_station_id: int, to_station_id: int) -> float | None:
    """
    Get fare amount between two stations.
    Fare is locked when ride starts and never changes mid-ride.
    
    Args:
        db: Database session
        from_station_id: Starting station ID
        to_station_id: Destination station ID
    
    Returns:
        Fare amount or None if not found
    """
    fare = db.query(Fare).filter(
        Fare.from_station == from_station_id,
        Fare.to_station == to_station_id
    ).first()

    return fare.amount if fare else None


def calculate_ride_fare(db: Session, ride_id: int) -> float | None:
    """
    Calculate fare for a ride based on stations.
    Uses the ride's station_id as destination.
    
    Args:
        db: Database session
        ride_id: Ride ID
    
    Returns:
        Fare amount or None
    """
    from app.models.ride import Ride
    from app.models.gps_log import GPSLog
    
    ride = db.query(Ride).filter(Ride.id == ride_id).first()
    if not ride:
        return None
    
    # Get driver's starting location (first GPS log for this ride)
    # For now, we'll use a default starting station
    # In production, you'd track which station the passenger boarded at
    
    # For simplicity, assume fare is based on destination station
    # You can enhance this by tracking boarding station
    
    return get_fare(db, 1, ride.station_id)  # TODO: Track actual boarding station
