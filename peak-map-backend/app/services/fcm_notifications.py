"""
Firebase Cloud Messaging (FCM) Notification Service

Sends push notifications to mobile apps for:
- Ride start/end alerts
- Drop-off detection
- Missed stop warnings
- Payment confirmations
- Driver updates
"""

import requests
import os
from typing import Optional, Dict, Any
import logging

logger = logging.getLogger(__name__)

# FCM Server Key (Get from Firebase Console -> Project Settings -> Cloud Messaging)
# In production, store this in environment variables
FCM_SERVER_KEY = os.getenv("FCM_SERVER_KEY", "YOUR_FCM_SERVER_KEY_HERE")
FCM_URL = "https://fcm.googleapis.com/fcm/send"


class NotificationService:
    """Firebase Cloud Messaging notification sender"""
    
    @staticmethod
    def send_to_topic(
        topic: str,
        title: str,
        body: str,
        data: Optional[Dict[str, Any]] = None
    ) -> bool:
        """
        Send notification to a Firebase topic
        
        Args:
            topic: Topic name (e.g., "driver_1", "ride_5", "passenger_10")
            title: Notification title
            body: Notification body text
            data: Optional data payload
            
        Returns:
            bool: True if successful, False otherwise
        """
        headers = {
            "Authorization": f"key={FCM_SERVER_KEY}",
            "Content-Type": "application/json",
        }
        
        payload = {
            "to": f"/topics/{topic}",
            "notification": {
                "title": title,
                "body": body,
                "sound": "default",
            },
            "priority": "high",
        }
        
        if data:
            payload["data"] = data
        
        try:
            response = requests.post(FCM_URL, headers=headers, json=payload)
            
            if response.status_code == 200:
                logger.info(f"✅ Notification sent to topic '{topic}': {title}")
                return True
            else:
                logger.error(f"❌ FCM error: {response.status_code} - {response.text}")
                return False
                
        except Exception as e:
            logger.error(f"❌ Failed to send notification: {e}")
            return False
    
    @staticmethod
    def send_to_device(
        token: str,
        title: str,
        body: str,
        data: Optional[Dict[str, Any]] = None
    ) -> bool:
        """
        Send notification to a specific device token
        
        Args:
            token: FCM device token
            title: Notification title
            body: Notification body text
            data: Optional data payload
            
        Returns:
            bool: True if successful, False otherwise
        """
        headers = {
            "Authorization": f"key={FCM_SERVER_KEY}",
            "Content-Type": "application/json",
        }
        
        payload = {
            "to": token,
            "notification": {
                "title": title,
                "body": body,
                "sound": "default",
            },
            "priority": "high",
        }
        
        if data:
            payload["data"] = data
        
        try:
            response = requests.post(FCM_URL, headers=headers, json=payload)
            
            if response.status_code == 200:
                logger.info(f"✅ Notification sent to device: {title}")
                return True
            else:
                logger.error(f"❌ FCM error: {response.status_code} - {response.text}")
                return False
                
        except Exception as e:
            logger.error(f"❌ Failed to send notification: {e}")
            return False


# ==================== NOTIFICATION TEMPLATES ====================

class RideNotifications:
    """Ride-related notification templates"""
    
    @staticmethod
    def ride_started(ride_id: int, eta_minutes: int):
        """Notify passenger that ride has started"""
        NotificationService.send_to_topic(
            topic=f"ride_{ride_id}",
            title="🚍 Your Bus Has Started!",
            body=f"Your bus is on the way. Estimated arrival: {eta_minutes} minutes.",
            data={
                "type": "ride_started",
                "ride_id": str(ride_id),
                "eta_minutes": str(eta_minutes),
            }
        )
    
    @staticmethod
    def approaching_station(ride_id: int, station_name: str):
        """Notify passenger that bus is approaching their station"""
        NotificationService.send_to_topic(
            topic=f"ride_{ride_id}",
            title="📍 Approaching Your Station",
            body=f"Your bus is approaching {station_name}. Please prepare to get off.",
            data={
                "type": "approaching_station",
                "ride_id": str(ride_id),
                "station_name": station_name,
            }
        )
    
    @staticmethod
    def dropped_off(ride_id: int, fare_amount: float):
        """Notify passenger they've been dropped off"""
        NotificationService.send_to_topic(
            topic=f"ride_{ride_id}",
            title="🎉 You've Arrived!",
            body=f"You have reached your destination. Fare: ₱{fare_amount:.2f}. Please proceed to payment.",
            data={
                "type": "dropped_off",
                "ride_id": str(ride_id),
                "fare_amount": str(fare_amount),
            }
        )
    
    @staticmethod
    def missed_stop(ride_id: int):
        """Notify passenger they missed their stop"""
        NotificationService.send_to_topic(
            topic=f"ride_{ride_id}",
            title="⚠️ You Missed Your Stop!",
            body="The bus has passed your station. Please contact the driver.",
            data={
                "type": "missed_stop",
                "ride_id": str(ride_id),
            }
        )
    
    @staticmethod
    def ride_cancelled(ride_id: int, reason: str = "Unknown"):
        """Notify that ride was cancelled"""
        NotificationService.send_to_topic(
            topic=f"ride_{ride_id}",
            title="❌ Ride Cancelled",
            body=f"Your ride has been cancelled. Reason: {reason}",
            data={
                "type": "ride_cancelled",
                "ride_id": str(ride_id),
                "reason": reason,
            }
        )


class PaymentNotifications:
    """Payment-related notification templates"""
    
    @staticmethod
    def payment_initiated(ride_id: int, method: str, amount: float):
        """Notify that payment was initiated"""
        NotificationService.send_to_topic(
            topic=f"ride_{ride_id}",
            title="💳 Payment Initiated",
            body=f"Processing {method} payment of ₱{amount:.2f}...",
            data={
                "type": "payment_initiated",
                "ride_id": str(ride_id),
                "method": method,
                "amount": str(amount),
            }
        )
    
    @staticmethod
    def payment_successful(ride_id: int, method: str, amount: float):
        """Notify that payment was successful"""
        NotificationService.send_to_topic(
            topic=f"ride_{ride_id}",
            title="✅ Payment Successful!",
            body=f"₱{amount:.2f} paid via {method}. Thank you for riding!",
            data={
                "type": "payment_successful",
                "ride_id": str(ride_id),
                "method": method,
                "amount": str(amount),
            }
        )
    
    @staticmethod
    def payment_failed(ride_id: int, method: str, reason: str = "Unknown"):
        """Notify that payment failed"""
        NotificationService.send_to_topic(
            topic=f"ride_{ride_id}",
            title="❌ Payment Failed",
            body=f"{method} payment failed. Reason: {reason}. Please try again.",
            data={
                "type": "payment_failed",
                "ride_id": str(ride_id),
                "method": method,
                "reason": reason,
            }
        )
    
    @staticmethod
    def cash_received(driver_id: int, ride_id: int, amount: float):
        """Notify driver that cash was received"""
        NotificationService.send_to_topic(
            topic=f"driver_{driver_id}",
            title="💵 Cash Payment Received",
            body=f"Cash collected: ₱{amount:.2f} for Ride #{ride_id}",
            data={
                "type": "cash_received",
                "driver_id": str(driver_id),
                "ride_id": str(ride_id),
                "amount": str(amount),
            }
        )


class DriverNotifications:
    """Driver-related notification templates"""
    
    @staticmethod
    def passenger_boarded(driver_id: int, ride_id: int, passenger_name: str):
        """Notify driver that passenger has boarded"""
        NotificationService.send_to_topic(
            topic=f"driver_{driver_id}",
            title="🧍 Passenger Boarded",
            body=f"{passenger_name} scanned QR code. Ride #{ride_id} started.",
            data={
                "type": "passenger_boarded",
                "driver_id": str(driver_id),
                "ride_id": str(ride_id),
                "passenger_name": passenger_name,
            }
        )
    
    @staticmethod
    def passenger_dropped(driver_id: int, ride_id: int):
        """Notify driver that passenger was dropped off"""
        NotificationService.send_to_topic(
            topic=f"driver_{driver_id}",
            title="📍 Passenger Dropped Off",
            body=f"Passenger reached destination. Ride #{ride_id} completed.",
            data={
                "type": "passenger_dropped",
                "driver_id": str(driver_id),
                "ride_id": str(ride_id),
            }
        )
    
    @staticmethod
    def new_ride_request(driver_id: int, passenger_name: str, station_name: str):
        """Notify driver about new ride request (future feature)"""
        NotificationService.send_to_topic(
            topic=f"driver_{driver_id}",
            title="🔔 New Ride Request",
            body=f"{passenger_name} wants to board at {station_name}",
            data={
                "type": "new_ride_request",
                "driver_id": str(driver_id),
                "passenger_name": passenger_name,
                "station_name": station_name,
            }
        )


# ==================== USAGE EXAMPLES ====================

"""
# Example 1: Ride Started
from app.services.fcm_notifications import RideNotifications
RideNotifications.ride_started(ride_id=5, eta_minutes=15)

# Example 2: Dropped Off
RideNotifications.dropped_off(ride_id=5, fare_amount=45.0)

# Example 3: Payment Successful
from app.services.fcm_notifications import PaymentNotifications
PaymentNotifications.payment_successful(ride_id=5, method="GCash", amount=45.0)

# Example 4: Driver Notified of Boarding
from app.services.fcm_notifications import DriverNotifications
DriverNotifications.passenger_boarded(driver_id=1, ride_id=5, passenger_name="Juan Dela Cruz")

# Example 5: Custom Notification
from app.services.fcm_notifications import NotificationService
NotificationService.send_to_topic(
    topic="all_drivers",
    title="System Maintenance",
    body="System will be under maintenance from 2AM-4AM",
    data={"type": "maintenance_alert"}
)
"""
