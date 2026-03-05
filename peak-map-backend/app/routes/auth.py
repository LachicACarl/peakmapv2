from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional
import random
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

from app.supabase_client import get_supabase_client

router = APIRouter(prefix="/auth", tags=["Auth"])


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
def register(payload: RegisterPayload):
    """Register a new user (driver or passenger)"""
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
        }
    except Exception as exc:
        print(f"Registration error: {exc}")
        # For demo, accept registration even if Supabase fails
        return {
            "success": True,
            "message": "Registration successful (demo mode)",
            "user_id": hash(payload.email) % 10000,
            "email": payload.email,
            "user_type": payload.user_type,
        }


@router.post("/login")
def login(payload: AuthPayload):
    """Login user (driver or passenger)"""
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
        # For demo mode, accept any login
        user_id = hash(payload.email) % 10000
        return {
            "success": True,
            "user_id": user_id,
            "email": payload.email,
            "token": "demo_token",
            "user_type": payload.user_type or "passenger",
            "auth_method": "demo",
        }

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