import os

import requests


def calculate_eta(origin_lat: float, origin_lng: float, dest_lat: float, dest_lng: float) -> dict:
    """
    Calculate ETA using Google Maps Distance Matrix API
    Returns traffic-aware ETA based on current GPS location
    """
    GOOGLE_API_KEY = os.getenv("GOOGLE_MAPS_API_KEY")
    
    if not GOOGLE_API_KEY:
        return {
            "error": "Google Maps API key not configured",
            "distance": "N/A",
            "duration": "N/A",
            "seconds": 0
        }

    url = "https://maps.googleapis.com/maps/api/distancematrix/json"

    params = {
        "origins": f"{origin_lat},{origin_lng}",
        "destinations": f"{dest_lat},{dest_lng}",
        "departure_time": "now",
        "traffic_model": "best_guess",
        "key": GOOGLE_API_KEY
    }

    try:
        response = requests.get(url, params=params, timeout=10)
        response.raise_for_status()
        data = response.json()

        if data["status"] != "OK":
            return {
                "error": f"Google Maps API error: {data['status']}",
                "distance": "N/A",
                "duration": "N/A",
                "seconds": 0
            }

        element = data["rows"][0]["elements"][0]
        
        if element["status"] != "OK":
            return {
                "error": f"Route not found: {element['status']}",
                "distance": "N/A",
                "duration": "N/A",
                "seconds": 0
            }

        return {
            "distance": element["distance"]["text"],
            "duration": element.get("duration_in_traffic", element["duration"])["text"],
            "seconds": element.get("duration_in_traffic", element["duration"])["value"]
        }

    except requests.exceptions.RequestException as e:
        return {
            "error": f"Request failed: {str(e)}",
            "distance": "N/A",
            "duration": "N/A",
            "seconds": 0
        }
