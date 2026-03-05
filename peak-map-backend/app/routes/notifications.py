"""
Notifications API Endpoints

Endpoints for testing and managing push notifications from the admin panel.
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.services.fcm_notifications import (
    NotificationService,
    RideNotifications,
    PaymentNotifications,
    DriverNotifications,
)

router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.post("/test/topic")
def send_test_notification_to_topic(
    topic: str,
    title: str,
    body: str,
    db: Session = Depends(get_db),
):
    """
    Send a test notification to a topic (admin only)
    
    Examples:
    - topic: "driver_1" (sends to driver 1)
    - topic: "ride_5" (sends to ride 5 passengers)
    - topic: "passenger_3" (sends to passenger 3)
    """
    success = NotificationService.send_to_topic(
        topic=topic,
        title=title,
        body=body,
    )
    
    if success:
        return {
            "status": "success",
            "message": f"Notification sent to topic '{topic}'",
            "topic": topic,
            "title": title,
            "body": body,
        }
    else:
        raise HTTPException(status_code=500, detail="Failed to send notification")


@router.post("/test/device")
def send_test_notification_to_device(
    token: str,
    title: str,
    body: str,
    db: Session = Depends(get_db),
):
    """
    Send a test notification to a specific device token
    
    Args:
        token: FCM device token from mobile app
        title: Notification title
        body: Notification body text
    """
    success = NotificationService.send_to_device(
        token=token,
        title=title,
        body=body,
    )
    
    if success:
        return {
            "status": "success",
            "message": "Notification sent to device",
            "token": token[:10] + "...",  # Hide token in response
            "title": title,
            "body": body,
        }
    else:
        raise HTTPException(status_code=500, detail="Failed to send notification")


@router.post("/tests/ride_started/{ride_id}")
def test_ride_started(ride_id: int, eta_minutes: int = 15):
    """Test: Send 'Ride Started' notification"""
    RideNotifications.ride_started(ride_id, eta_minutes)
    return {
        "status": "success",
        "notification": "ride_started",
        "ride_id": ride_id,
        "eta_minutes": eta_minutes,
    }


@router.post("/tests/approaching_station/{ride_id}")
def test_approaching_station(ride_id: int, station_name: str = "Ayala Station"):
    """Test: Send 'Approaching Station' notification"""
    RideNotifications.approaching_station(ride_id, station_name)
    return {
        "status": "success",
        "notification": "approaching_station",
        "ride_id": ride_id,
        "station_name": station_name,
    }


@router.post("/tests/dropped_off/{ride_id}")
def test_dropped_off(ride_id: int, fare_amount: float = 45.0):
    """Test: Send 'Dropped Off' notification"""
    RideNotifications.dropped_off(ride_id, fare_amount)
    return {
        "status": "success",
        "notification": "dropped_off",
        "ride_id": ride_id,
        "fare_amount": fare_amount,
    }


@router.post("/tests/missed_stop/{ride_id}")
def test_missed_stop(ride_id: int):
    """Test: Send 'Missed Stop' notification"""
    RideNotifications.missed_stop(ride_id)
    return {
        "status": "success",
        "notification": "missed_stop",
        "ride_id": ride_id,
    }


@router.post("/tests/payment_successful/{ride_id}")
def test_payment_successful(
    ride_id: int,
    method: str = "GCash",
    amount: float = 45.0,
):
    """Test: Send 'Payment Successful' notification"""
    PaymentNotifications.payment_successful(ride_id, method, amount)
    return {
        "status": "success",
        "notification": "payment_successful",
        "ride_id": ride_id,
        "method": method,
        "amount": amount,
    }


@router.post("/tests/payment_failed/{ride_id}")
def test_payment_failed(
    ride_id: int,
    method: str = "GCash",
    reason: str = "Insufficient balance",
):
    """Test: Send 'Payment Failed' notification"""
    PaymentNotifications.payment_failed(ride_id, method, reason)
    return {
        "status": "success",
        "notification": "payment_failed",
        "ride_id": ride_id,
        "method": method,
        "reason": reason,
    }


@router.post("/tests/cash_received/{driver_id}")
def test_cash_received(driver_id: int, ride_id: int = 1, amount: float = 45.0):
    """Test: Send 'Cash Received' notification to driver"""
    PaymentNotifications.cash_received(driver_id, ride_id, amount)
    return {
        "status": "success",
        "notification": "cash_received",
        "driver_id": driver_id,
        "ride_id": ride_id,
        "amount": amount,
    }


@router.post("/tests/passenger_boarded/{driver_id}")
def test_passenger_boarded(
    driver_id: int,
    ride_id: int = 1,
    passenger_name: str = "Juan Dela Cruz",
):
    """Test: Send 'Passenger Boarded' notification to driver"""
    DriverNotifications.passenger_boarded(driver_id, ride_id, passenger_name)
    return {
        "status": "success",
        "notification": "passenger_boarded",
        "driver_id": driver_id,
        "ride_id": ride_id,
        "passenger_name": passenger_name,
    }


@router.post("/tests/passenger_dropped/{driver_id}")
def test_passenger_dropped(driver_id: int, ride_id: int = 1):
    """Test: Send 'Passenger Dropped' notification to driver"""
    DriverNotifications.passenger_dropped(driver_id, ride_id)
    return {
        "status": "success",
        "notification": "passenger_dropped",
        "driver_id": driver_id,
        "ride_id": ride_id,
    }


@router.get("/fcm_setup")
def get_fcm_setup_instructions():
    """Get Firebase setup instructions"""
    return {
        "status": "FCM Setup Guide",
        "steps": [
            "1. Go to Firebase Console (console.firebase.google.com)",
            "2. Select your project or create a new one",
            "3. Go to Project Settings -> Cloud Messaging tab",
            "4. Copy Server Key (authorization header value)",
            "5. Export FCM_SERVER_KEY='your_server_key' in production or .env file",
            "6. Flutter apps automatically subscribe to topics:",
            "   - NotificationService.subscribeToDriver(driverId)",
            "   - NotificationService.subscribeToRide(rideId)",
            "   - NotificationService.subscribeToPassenger(passengerId)",
        ],
        "topic_format": {
            "driver": "driver_{driver_id}",
            "ride": "ride_{ride_id}",
            "passenger": "passenger_{passenger_id}",
        },
        "test_endpoints": {
            "ride_started": "POST /notifications/tests/ride_started/{ride_id}",
            "dropped_off": "POST /notifications/tests/dropped_off/{ride_id}",
            "payment_successful": "POST /notifications/tests/payment_successful/{ride_id}",
            "passenger_boarded": "POST /notifications/tests/passenger_boarded/{driver_id}",
        },
    }
