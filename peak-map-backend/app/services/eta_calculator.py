"""
ETA Calculation Service for EDSA Bus Carousel
Calculates Estimated Time of Arrival based on station-to-station segments
"""
from typing import Optional
from sqlalchemy.orm import Session
from app.models.station import Station
from app.models.route_segment import RouteSegment
from app.models.gps_log import GPSLog
import math


def calculate_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Calculate distance between two points using Haversine formula
    Returns distance in kilometers
    """
    R = 6371  # Earth's radius in kilometers
    
    lat1_rad = math.radians(lat1)
    lat2_rad = math.radians(lat2)
    delta_lat = math.radians(lat2 - lat1)
    delta_lon = math.radians(lon2 - lon1)
    
    a = math.sin(delta_lat/2)**2 + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(delta_lon/2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
    
    return R * c


def find_nearest_station(latitude: float, longitude: float, db: Session) -> Optional[Station]:
    """Find the nearest station to given GPS coordinates"""
    stations = db.query(Station).all()
    
    if not stations:
        return None
    
    nearest_station = None
    min_distance = float('inf')
    
    for station in stations:
        distance = calculate_distance(latitude, longitude, station.latitude, station.longitude)
        if distance < min_distance:
            min_distance = distance
            nearest_station = station
    
    return nearest_station


def calculate_eta_minutes(
    bus_latitude: float,
    bus_longitude: float,
    destination_station_id: int,
    db: Session,
    traffic_factor: float = 1.0
) -> dict:
    """
    Calculate ETA from bus current position to destination station
    
    Args:
        bus_latitude: Current bus latitude
        bus_longitude: Current bus longitude
        destination_station_id: ID of destination station
        db: Database session
        traffic_factor: Multiplier for traffic (1.0 = normal, 1.2 = heavy traffic)
    
    Returns:
        dict with:
        - eta_minutes: Estimated time in minutes
        - eta_text: Formatted ETA text (e.g., "12 min")
        - stops_remaining: Number of stops between current and destination
        - distance_km: Total distance to travel
        - current_station: Name of nearest station to bus
        - segments: List of segment details
    """
    # Find nearest station to bus
    current_station = find_nearest_station(bus_latitude, bus_longitude, db)
    if not current_station:
        return {
            "eta_minutes": 0,
            "eta_text": "Unknown",
            "stops_remaining": 0,
            "distance_km": 0,
            "current_station": "Unknown",
            "segments": []
        }
    
    # Get destination station
    destination_station = db.query(Station).filter(Station.id == destination_station_id).first()
    if not destination_station:
        return {
            "eta_minutes": 0,
            "eta_text": "Invalid destination",
            "stops_remaining": 0,
            "distance_km": 0,
            "current_station": current_station.name,
            "segments": []
        }
    
    # If already at destination
    if current_station.id == destination_station.id:
        return {
            "eta_minutes": 0,
            "eta_text": "Arrived",
            "stops_remaining": 0,
            "distance_km": 0,
            "current_station": current_station.name,
            "segments": []
        }
    
    # Get route segments between current and destination
    # Assuming stations are ordered
    if current_station.order is None or destination_station.order is None:
        # Fallback to simple calculation if no order
        distance = calculate_distance(
            bus_latitude, bus_longitude,
            destination_station.latitude, destination_station.longitude
        )
        eta_minutes = (distance / 22) * 60 * traffic_factor  # Assume 22 km/h average
        
        return {
            "eta_minutes": round(eta_minutes, 1),
            "eta_text": f"{int(eta_minutes)} min",
            "stops_remaining": 1,
            "distance_km": round(distance, 2),
            "current_station": current_station.name,
            "segments": []
        }
    
    # Calculate based on route segments
    total_time_minutes = 0
    total_distance_km = 0
    stops_remaining = 0
    segments_info = []
    
    # Determine direction (forward or backward)
    if current_station.order < destination_station.order:
        # Going forward (toward PITX)
        for order in range(current_station.order, destination_station.order):
            segment = db.query(RouteSegment).join(
                Station, RouteSegment.from_station_id == Station.id
            ).filter(Station.order == order).first()
            
            if segment:
                total_time_minutes += segment.avg_time_minutes
                total_distance_km += segment.distance_km
                stops_remaining += 1
                segments_info.append({
                    "from_station": segment.from_station.name,
                    "to_station": segment.to_station.name,
                    "distance_km": segment.distance_km,
                    "time_minutes": segment.avg_time_minutes
                })
    else:
        # Going backward (toward Monumento)
        for order in range(current_station.order - 1, destination_station.order - 1, -1):
            segment = db.query(RouteSegment).join(
                Station, RouteSegment.from_station_id == Station.id
            ).filter(Station.order == order).first()
            
            if segment:
                total_time_minutes += segment.avg_time_minutes
                total_distance_km += segment.distance_km
                stops_remaining += 1
                segments_info.append({
                    "from_station": segment.to_station.name,  # Reversed
                    "to_station": segment.from_station.name,
                    "distance_km": segment.distance_km,
                    "time_minutes": segment.avg_time_minutes
                })
    
    # Add stop delays (30 seconds per stop)
    stop_delay_minutes = (stops_remaining * 30) / 60  # Convert seconds to minutes
    total_time_minutes += stop_delay_minutes
    
    # Apply traffic factor
    total_time_minutes *= traffic_factor
    
    eta_minutes = round(total_time_minutes, 1)
    
    return {
        "eta_minutes": eta_minutes,
        "eta_text": f"{int(eta_minutes)} min" if eta_minutes >= 1 else "< 1 min",
        "stops_remaining": stops_remaining,
        "distance_km": round(total_distance_km, 2),
        "current_station": current_station.name,
        "destination_station": destination_station.name,
        "segments": segments_info
    }


def calculate_eta_for_ride(ride_id: int, db: Session) -> dict:
    """
    Calculate ETA for a specific ride
    Gets bus position from latest GPS log
    """
    from app.models.ride import Ride
    
    ride = db.query(Ride).filter(Ride.id == ride_id).first()
    if not ride:
        return {"error": "Ride not found"}
    
    # Get latest GPS position for driver
    gps = db.query(GPSLog).filter(
        GPSLog.driver_id == ride.driver_id
    ).order_by(GPSLog.timestamp.desc()).first()
    
    if not gps:
        return {"error": "No GPS data available"}
    
    # Get destination station from ride
    destination_station_id = getattr(ride, 'to_station_id', None) or getattr(ride, 'station_id', None)
    if not destination_station_id:
        return {"error": "No destination station"}
    
    return calculate_eta_minutes(
        gps.latitude,
        gps.longitude,
        destination_station_id,
        db,
        traffic_factor=1.0  # Can be adjusted based on time of day or real traffic data
    )
