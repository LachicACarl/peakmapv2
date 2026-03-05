import uuid

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.ride import Ride
from app.models.ride_session import RideSession
from app.models.station import Station
from app.models.user import User

router = APIRouter(prefix="/sessions", tags=["Ride Sessions"])


class SessionCreate(BaseModel):
    driver_id: int


class SessionJoin(BaseModel):
    session_code: str
    passenger_id: int


class SessionConfirm(BaseModel):
    session_id: int
    passenger_id: int
    station_id: int


@router.post("/create", response_model=dict)
def create_session(data: SessionCreate, db: Session = Depends(get_db)):
    """
    Driver creates a new ride session and gets a QR code.
    The session_code is displayed as a QR code for passengers to scan.
    """
    # Verify driver exists
    driver = db.query(User).filter(User.id == data.driver_id).first()
    if not driver:
        return {"error": "Driver not found"}
    
    # Generate unique session code
    session_code = str(uuid.uuid4())
    
    session = RideSession(
        driver_id=data.driver_id,
        session_code=session_code,
        status="open"
    )

    db.add(session)
    db.commit()
    db.refresh(session)

    return {
        "message": "Session created",
        "session_id": session.id,
        "session_code": session.session_code,
        "status": session.status,
        "driver_id": session.driver_id,
        "qr_data": {
            "type": "driver_session",
            "session_code": session.session_code,
            "driver_id": session.driver_id
        }
    }


@router.post("/join", response_model=dict)
def join_session(data: SessionJoin, db: Session = Depends(get_db)):
    """
    Passenger scans driver's QR code and joins the session.
    This pairs the passenger with the driver.
    """
    # Verify passenger exists
    passenger = db.query(User).filter(User.id == data.passenger_id).first()
    if not passenger:
        return {"error": "Passenger not found"}
    
    # Find open session with the given code
    session = db.query(RideSession).filter(
        RideSession.session_code == data.session_code,
        RideSession.status == "open"
    ).first()

    if not session:
        return {"error": "Invalid or closed session"}

    # Mark session as paired
    session.status = "paired"
    db.commit()

    # Get driver info
    driver = db.query(User).filter(User.id == session.driver_id).first()

    return {
        "message": "Joined session successfully",
        "session_id": session.id,
        "driver_id": session.driver_id,
        "driver_name": driver.full_name if driver else "Unknown",
        "passenger_id": data.passenger_id,
        "status": "paired",
        "passenger_qr_data": {
            "type": "passenger_confirmation",
            "session_id": session.id,
            "passenger_id": data.passenger_id
        }
    }


@router.post("/confirm", response_model=dict)
def confirm_passenger(data: SessionConfirm, db: Session = Depends(get_db)):
    """
    Driver scans passenger's QR code to confirm identity and start the ride.
    This creates an active ride and closes the session.
    """
    # Find paired session
    session = db.query(RideSession).filter(
        RideSession.id == data.session_id,
        RideSession.status == "paired"
    ).first()

    if not session:
        return {"error": "Session not valid or already closed"}
    
    # Verify station exists
    station = db.query(Station).filter(Station.id == data.station_id).first()
    if not station:
        return {"error": "Station not found"}
    
    # Verify passenger exists
    passenger = db.query(User).filter(User.id == data.passenger_id).first()
    if not passenger:
        return {"error": "Passenger not found"}

    # Calculate fare (using fare service)
    from app.services.fare_service import get_fare
    
    # For now, assume starting from station 1 (TODO: track actual boarding station)
    fare_amount = get_fare(db, from_station_id=1, to_station_id=data.station_id)
    
    # Create the ride with locked fare
    ride = Ride(
        passenger_id=data.passenger_id,
        driver_id=session.driver_id,
        station_id=data.station_id,
        fare_amount=fare_amount if fare_amount else 0.0,  # Lock fare when ride starts
        status="ongoing"
    )

    # Close the session
    session.status = "closed"
    
    db.add(ride)
    db.commit()
    db.refresh(ride)

    return {
        "message": "✅ Ride started successfully",
        "ride_id": ride.id,
        "session_id": session.id,
        "passenger_id": data.passenger_id,
        "driver_id": session.driver_id,
        "destination_station": station.name,
        "fare_amount": ride.fare_amount,
        "status": "ongoing"
    }


@router.get("/", response_model=list[dict])
def get_sessions(driver_id: int | None = None, status: str | None = None, 
                 db: Session = Depends(get_db)):
    """Get all sessions with optional filters"""
    query = db.query(RideSession)
    
    if driver_id:
        query = query.filter(RideSession.driver_id == driver_id)
    if status:
        query = query.filter(RideSession.status == status)
    
    sessions = query.order_by(RideSession.created_at.desc()).all()
    
    result = []
    for session in sessions:
        driver = db.query(User).filter(User.id == session.driver_id).first()
        result.append({
            "id": session.id,
            "driver_id": session.driver_id,
            "driver_name": driver.full_name if driver else "Unknown",
            "session_code": session.session_code,
            "status": session.status,
            "created_at": str(session.created_at)
        })
    
    return result


@router.get("/{session_id}", response_model=dict)
def get_session(session_id: int, db: Session = Depends(get_db)):
    """Get session details by ID"""
    session = db.query(RideSession).filter(RideSession.id == session_id).first()
    
    if not session:
        return {"error": "Session not found"}
    
    driver = db.query(User).filter(User.id == session.driver_id).first()
    
    return {
        "id": session.id,
        "driver_id": session.driver_id,
        "driver_name": driver.full_name if driver else "Unknown",
        "session_code": session.session_code,
        "status": session.status,
        "created_at": str(session.created_at)
    }
