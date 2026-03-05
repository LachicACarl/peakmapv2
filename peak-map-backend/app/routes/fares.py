from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, field_validator
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.fare import Fare
from app.models.station import Station

router = APIRouter(prefix="/fares", tags=["Fares"])


class FareCreate(BaseModel):
    from_station: int
    to_station: int
    amount: float
    
    @field_validator('amount')
    @classmethod
    def amount_must_be_positive(cls, v):
        if v <= 0:
            raise ValueError('Fare amount must be greater than 0')
        return v
    
    @field_validator('to_station')
    @classmethod
    def stations_must_differ(cls, v, info):
        if 'from_station' in info.data and v == info.data['from_station']:
            raise ValueError('To station cannot be same as from station')
        return v


class FareOut(FareCreate):
    id: int

    class Config:
        from_attributes = True


@router.post("/", response_model=dict)
def add_fare(fare: FareCreate, db: Session = Depends(get_db)):
    # Verify stations exist
    from_stn = db.query(Station).filter(Station.id == fare.from_station).first()
    to_stn = db.query(Station).filter(Station.id == fare.to_station).first()
    
    if not from_stn:
        raise HTTPException(status_code=404, detail=f"From station {fare.from_station} not found")
    if not to_stn:
        raise HTTPException(status_code=404, detail=f"To station {fare.to_station} not found")
    
    # Check for duplicate fare route
    existing = db.query(Fare).filter(
        Fare.from_station == fare.from_station,
        Fare.to_station == fare.to_station
    ).first()
    
    if existing:
        raise HTTPException(status_code=400, detail="Fare route already exists. Update the amount instead.")
    
    new_fare = Fare(**fare.model_dump())
    db.add(new_fare)
    db.commit()
    db.refresh(new_fare)
    return {"message": "Fare added", "id": new_fare.id, "amount": new_fare.amount}


@router.get("/", response_model=list[FareOut])
def get_fares(db: Session = Depends(get_db)):
    try:
        fares = db.query(Fare).all()
        return fares
    except Exception as e:
        # Return empty list if no fares or error
        print(f"Error fetching fares: {str(e)}")
        return []
