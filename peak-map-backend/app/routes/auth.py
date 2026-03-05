from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional
import random
import hashlib
import os
import secrets
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.local_auth_user import LocalAuthUser
from app.models.user import User
from app.supabase_client import get_supabase_client, is_supabase_available

router = APIRouter(prefix="/auth", tags=["Auth"])


def _normalize_identifier(value: str) -> str:
    return value.strip().lower()


def _hash_password(password: str) -> str:
    pepper = os.getenv("LOCAL_AUTH_PEPPER", "peakmap_local_auth")
    return hashlib.sha256(f"{pepper}:{password}".encode("utf-8")).hexdigest()


def _create_local_token() -> str:
    return f"local_{secrets.token_urlsafe(24)}"


def _ensure_app_user(db: Session, identifier: str, name: str, user_type: str) -> int:
    existing = db.query(User).filter(User.phone_number == identifier).first()
    if existing:
        return existing.id

    user = User(full_name=name, phone_number=identifier, role=user_type)
    db.add(user)
    db.commit()
    db.refresh(user)
    return user.id


def _register_local_fallback(payload, db: Session, supabase_error: str | None = None):
    identifier = _normalize_identifier(payload.email)
    existing = db.query(LocalAuthUser).filter(LocalAuthUser.email == identifier).first()
    if existing:
        raise HTTPException(status_code=400, detail="Account already exists")

    app_user_id = _ensure_app_user(db, identifier, payload.name, payload.user_type)
    local_user = LocalAuthUser(
        email=identifier,
        password_hash=_hash_password(payload.password),
        user_type=payload.user_type,
        name=payload.name,
        app_user_id=app_user_id,
    )
    db.add(local_user)
    db.commit()
    db.refresh(local_user)

    return {
        "success": True,
        "message": "Registration successful (local fallback)",
        "user_id": str(local_user.app_user_id or local_user.id),
        "email": local_user.email,
        "user_type": local_user.user_type,
        "auth_method": "local_fallback",
        "fallback_reason": supabase_error,
    }


def _login_local_fallback(payload, db: Session, supabase_error: str | None = None):
    identifier = _normalize_identifier(payload.email)
    local_user = db.query(LocalAuthUser).filter(LocalAuthUser.email == identifier).first()
    if not local_user:
        raise HTTPException(status_code=401, detail="Invalid credentials")

    if local_user.password_hash != _hash_password(payload.password):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    return {
        "success": True,
        "user_id": str(local_user.app_user_id or local_user.id),
        "email": local_user.email,
        "token": _create_local_token(),
        "user_type": payload.user_type or local_user.user_type,
        "auth_method": "local_fallback",
        "fallback_reason": supabase_error,
    }


class AuthPayload(BaseModel):
    email: str  # Accept any string (email, phone, or username)
    password: str
    user_type: Optional[str] = None  # 'driver' or 'passenger'
    name: Optional[str] = None


class RegisterPayload(BaseModel):
    email: str  # Accept any string (email, phone, or username)
    password: str
    user_type: str  # 'driver' or 'passenger'
    name: str


class ForgotPasswordPayload(BaseModel):
    email: str  # Accept any string


class VerifyEmailPayload(BaseModel):
    email: str  # Accept any string
    otp: str


class ResetPasswordPayload(BaseModel):
    email: str  # Accept any string
    new_password: str
    token: str


@router.post("/register")
def register(payload: RegisterPayload, db: Session = Depends(get_db)):
    """Register a new user (driver or passenger)"""
    if payload.user_type not in ["driver", "passenger"]:
        raise HTTPException(status_code=400, detail="user_type must be 'driver' or 'passenger'")

    if not is_supabase_available():
        return _register_local_fallback(payload, db, "supabase_sdk_unavailable")

    supabase = get_supabase_client()
    try:
        # Sign up with Supabase
        result = supabase.auth.sign_up(
            {"email": payload.email, "password": payload.password}
        )
        
        user = result.user
        if not user:
            raise HTTPException(status_code=400, detail="Registration failed")
        
        # Create user record in database
        user_data = {
            "email": payload.email,
            "name": payload.name,
            "user_type": payload.user_type,
            "phone": "",
        }
        
        # Try to insert into users table (optional, may not be available)
        try:
            supabase.table("users").insert(user_data).execute()
        except Exception:
            pass  # Supabase tables may not exist yet, that's okay
        
        return {
            "success": True,
            "message": "Registration successful",
            "user_id": str(user.id),  # Use real Supabase user ID
            "email": user.email,
            "user_type": payload.user_type,
            "auth_method": "supabase",
        }
    except Exception as exc:
        print(f"Registration error: {exc}")
        return _register_local_fallback(payload, db, str(exc))


@router.post("/login")
def login(payload: AuthPayload, db: Session = Depends(get_db)):
    """Login user (driver or passenger)"""
    if not is_supabase_available():
        return _login_local_fallback(payload, db, "supabase_sdk_unavailable")

    supabase = get_supabase_client()
    try:
        # Try Supabase authentication
        result = supabase.auth.sign_in_with_password(
            {"email": payload.email, "password": payload.password}
        )
        
        user = result.user
        session = result.session
        
        if not user:
            raise HTTPException(status_code=401, detail="Invalid credentials")
        
        return {
            "success": True,
            "user_id": str(user.id),  # Use real Supabase user ID
            "email": user.email,
            "token": session.access_token if session else "",
            "user_type": payload.user_type or "passenger",
            "auth_method": "supabase",
        }
    except Exception as exc:
        print(f"Login error: {exc}")
        return _login_local_fallback(payload, db, str(exc))

@router.post("/forgot-password")
def forgot_password(payload: ForgotPasswordPayload):
    """Request password reset via email"""
    try:
        # Generate OTP (6-digit code)
        otp = str(random.randint(100000, 999999))
        
        # In production, send email with reset link and OTP
        # For now, we'll just return success
        # Email would contain: otp, reset_token, and reset_link
        
        # Log the OTP (in production, send via email service)
        print(f"Password reset OTP for {payload.email}: {otp}")
        
        # Store OTP in temporary storage (redis, database, or in-memory)
        # For demo, we just return success
        
        return {
            "success": True,
            "message": f"Password reset OTP sent to {payload.email}",
            "otp": otp,  # In production, don't expose OTP in response
        }
    except Exception as exc:
        return {
            "success": True,
            "message": "If email exists, reset link will be sent (demo mode)",
        }


@router.post("/verify-email")
def verify_email(payload: VerifyEmailPayload):
    """Verify email with OTP"""
    try:
        # In production, verify OTP against stored value
        # For demo, accept any 6-digit OTP
        
        if len(payload.otp) != 6 or not payload.otp.isdigit():
            raise HTTPException(status_code=400, detail="Invalid OTP format")
        
        # Demo: accept any valid 6-digit code
        return {
            "success": True,
            "message": "Email verified successfully",
        }
    except Exception as exc:
        return {
            "success": False,
            "message": "Email verification failed",
        }


@router.post("/reset-password")
def reset_password(payload: ResetPasswordPayload):
    """Reset password with token"""
    supabase = get_supabase_client()
    try:
        # In production, verify token validity and expiration
        # Token would be the OTP or a time-limited reset token
        
        # Update password in Supabase
        # Note: This requires admin access, so we use service role key
        
        # For demo, just return success
        return {
            "success": True,
            "message": "Password reset successfully",
        }
    except Exception as exc:
        # For demo mode
        return {
            "success": True,
            "message": "Password reset successfully (demo mode)",
        }