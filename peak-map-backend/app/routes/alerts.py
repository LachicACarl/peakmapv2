from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.payment import Payment
from app.models.ride import Ride
from app.models.station import Station

router = APIRouter(prefix="/alerts", tags=["Alerts"])


@router.get("/", response_model=list[dict])
def get_alerts(driver_id: int | None = None, db: Session = Depends(get_db)):
    """Return driver-facing alerts for ride states and pending payments."""
    alerts: list[dict] = []

    ride_query = db.query(Ride)
    if driver_id is not None:
        ride_query = ride_query.filter(Ride.driver_id == driver_id)

    rides = ride_query.order_by(Ride.started_at.desc()).limit(25).all()

    station_ids = {ride.station_id for ride in rides if ride.station_id is not None}
    station_map: dict[int, str] = {}
    if station_ids:
        station_rows = db.query(Station).filter(Station.id.in_(station_ids)).all()
        station_map = {station.id: station.name for station in station_rows}

    for ride in rides:
        if ride.status not in {"ongoing", "missed", "dropped"}:
            continue

        severity = "info"
        title = "Ride update"
        if ride.status == "missed":
            severity = "high"
            title = "Passenger missed stop"
        elif ride.status == "dropped":
            severity = "low"
            title = "Passenger dropped off"
        elif ride.status == "ongoing":
            severity = "low"
            title = "Active ride"

        alerts.append(
            {
                "id": f"ride-{ride.id}",
                "type": "ride_status",
                "severity": severity,
                "title": title,
                "message": (
                    f"Ride #{ride.id} at {station_map.get(ride.station_id, 'Unknown Station')} "
                    f"is currently {ride.status}."
                ),
                "driver_id": ride.driver_id,
                "ride_id": ride.id,
                "status": ride.status,
                "timestamp": ride.started_at.isoformat() if ride.started_at else None,
            }
        )

    pending_payment_query = db.query(Payment).filter(Payment.status == "pending")
    if driver_id is not None:
        driver_ride_ids = [ride.id for ride in rides]
        if driver_ride_ids:
            pending_payment_query = pending_payment_query.filter(Payment.ride_id.in_(driver_ride_ids))
        else:
            pending_payment_query = pending_payment_query.filter(Payment.ride_id == -1)

    pending_payments = pending_payment_query.order_by(Payment.created_at.desc()).limit(25).all()

    for payment in pending_payments:
        alerts.append(
            {
                "id": f"payment-{payment.id}",
                "type": "payment_pending",
                "severity": "medium",
                "title": "Pending payment",
                "message": f"Payment #{payment.id} for ride #{payment.ride_id} is pending confirmation.",
                "payment_id": payment.id,
                "ride_id": payment.ride_id,
                "amount": payment.amount,
                "method": payment.method,
                "timestamp": payment.created_at.isoformat() if payment.created_at else None,
            }
        )

    alerts.sort(key=lambda item: item.get("timestamp") or "", reverse=True)
    return alerts[:50]
