from datetime import datetime

from sqlalchemy import Column, DateTime, Float, ForeignKey, Integer, String

from app.database import Base


class Payment(Base):
    __tablename__ = "payments"

    id = Column(Integer, primary_key=True)
    user_id = Column(String, nullable=True)  # Supabase user ID for NFC balance tracking
    ride_id = Column(Integer, ForeignKey("rides.id"), nullable=True)  # Nullable for balance loads
    amount = Column(Float, nullable=False)
    method = Column(String, nullable=False)  # cash | gcash | ewallet | admin_nfc | bus_fare_nfc
    status = Column(String, default="pending")  # pending | paid | failed
    reference = Column(String, nullable=True)  # Transaction reference for e-wallets
    created_at = Column(DateTime, default=datetime.utcnow)
    paid_at = Column(DateTime, nullable=True)
