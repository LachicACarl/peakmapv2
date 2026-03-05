from app.models.station import Station
from app.utils.geo import distance_in_meters


def check_dropoff(driver_lat: float, driver_lng: float, station: Station) -> bool:
    """
    Check if driver is within the station's radius for drop-off.
    
    Args:
        driver_lat: Driver's current latitude
        driver_lng: Driver's current longitude
        station: Station object with latitude, longitude, and radius
    
    Returns:
        True if driver is within station radius, False otherwise
    """
    distance = distance_in_meters(
        driver_lat,
        driver_lng,
        station.latitude,
        station.longitude
    )

    return distance <= station.radius
