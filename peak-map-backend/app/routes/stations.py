from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, field_validator
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.station import Station

router = APIRouter(prefix="/stations", tags=["Stations"])


class StationCreate(BaseModel):
    name: str
    latitude: float
    longitude: float
    radius: int
    
    @field_validator('latitude')
    @classmethod
    def latitude_valid(cls, v):
        if v < -90 or v > 90:
            raise ValueError('Latitude must be between -90 and 90')
        return v
    
    @field_validator('longitude')
    @classmethod
    def longitude_valid(cls, v):
        if v < -180 or v > 180:
            raise ValueError('Longitude must be between -180 and 180')
        return v
    
    @field_validator('radius')
    @classmethod
    def radius_positive(cls, v):
        if v <= 0:
            raise ValueError('Radius must be greater than 0')
        return v


class StationOut(StationCreate):
    id: int

    class Config:
        from_attributes = True


@router.post("/", response_model=dict)
def add_station(station: StationCreate, db: Session = Depends(get_db)):
    # Check for duplicate station (same name)
    existing_name = db.query(Station).filter(
        Station.name.ilike(station.name)
    ).first()
    
    if existing_name:
        raise HTTPException(status_code=400, detail=f"Station '{station.name}' already exists")
    
    # Check for duplicate coordinates (within 100m = ~0.001 degrees)
    existing_coord = db.query(Station).filter(
        abs(Station.latitude - station.latitude) < 0.001,
        abs(Station.longitude - station.longitude) < 0.001
    ).first()
    
    if existing_coord:
        raise HTTPException(status_code=400, detail=f"Station at coordinates already exists: {existing_coord.name}")
    
    new_station = Station(**station.model_dump())
    db.add(new_station)
    db.commit()
    db.refresh(new_station)
    return {"message": "Station added", "id": new_station.id, "name": new_station.name}


@router.get("/", response_model=list[StationOut])
def get_stations(db: Session = Depends(get_db)):
    return db.query(Station).all()
