from datetime import datetime

from sqlalchemy import Column, DateTime, Integer, String

from app.database import Base


class LocalAuthUser(Base):
    __tablename__ = "local_auth_users"

    id = Column(Integer, primary_key=True)
    email = Column(String, unique=True, nullable=False)
    password_hash = Column(String, nullable=False)
    user_type = Column(String, nullable=False)  # driver | passenger
    name = Column(String, nullable=False)
    app_user_id = Column(Integer, nullable=True)  # FK-like link to users.id
    created_at = Column(DateTime, default=datetime.utcnow)
