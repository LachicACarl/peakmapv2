from sqlalchemy import Column, Float, Integer, ForeignKey
from sqlalchemy.orm import relationship

from app.database import Base


class RouteSegment(Base):
    """
    Station-to-station route segments for ETA calculation
    Represents travel time and distance between consecutive stations
    """
    __tablename__ = "route_segments"

    id = Column(Integer, primary_key=True)
    from_station_id = Column(Integer, ForeignKey("stations.id"), nullable=False)
    to_station_id = Column(Integer, ForeignKey("stations.id"), nullable=False)
    distance_km = Column(Float, nullable=False)  # Distance in kilometers
    avg_time_minutes = Column(Float, nullable=False)  # Average travel time in minutes
    stop_delay_seconds = Column(Integer, default=30)  # Time spent at station stop
    
    # Relationships
    from_station = relationship("Station", foreign_keys=[from_station_id])
    to_station = relationship("Station", foreign_keys=[to_station_id])
