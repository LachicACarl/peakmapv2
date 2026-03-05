from sqlalchemy import Column, Float, ForeignKey, Integer

from app.database import Base


class Fare(Base):
    __tablename__ = "fares"

    id = Column(Integer, primary_key=True)
    from_station = Column(Integer, ForeignKey("stations.id"), nullable=False)
    to_station = Column(Integer, ForeignKey("stations.id"), nullable=False)
    amount = Column(Float, nullable=False)
