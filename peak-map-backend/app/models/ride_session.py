import uuid
from datetime import datetime

from sqlalchemy import Column, DateTime, ForeignKey, Integer, String

from app.database import Base


class RideSession(Base):
    __tablename__ = "ride_sessions"

    id = Column(Integer, primary_key=True)
    driver_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    session_code = Column(String, unique=True, nullable=False)
    status = Column(String, default="open")  # open | paired | closed
    created_at = Column(DateTime, default=datetime.utcnow)

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        if not self.session_code:
            self.session_code = str(uuid.uuid4())
