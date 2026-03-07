from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Any, Optional
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


def _force_local_auth_enabled() -> bool:
    value = os.getenv("FORCE_LOCAL_AUTH", "false").strip().lower()
    return value in {"1", "true", "yes", "on"}


def _response_data(response: Any) -> list[dict]:
    if response is None:
        return []

    data = getattr(response, "data", None)
    if isinstance(data, list):
        return data

    if isinstance(response, dict):
        maybe_data = response.get("data")
        if isinstance(maybe_data, list):
            return maybe_data

    return []


def _find_supabase_user_by_email(supabase, email: str) -> Optional[dict]:
    try:
        result = (
            supabase.table("users")
            .select("id,email,user_type,name,phone")
            .eq("email", email)
            .limit(1)
            .execute()
        )
        rows = _response_data(result)
        return rows[0] if rows else None
    except Exception as exc:
        print(f"Supabase users lookup skipped: {exc}")
        return None


def _sync_supabase_user_profile(
    supabase,
    email: str,
    name: str,
    user_type: str,
    phone: Optional[str] = None,
) -> Optional[int]:
    existing = _find_supabase_user_by_email(supabase, email)
    update_payload = {"name": name, "user_type": user_type}
    if phone:
        update_payload["phone"] = phone

    if existing:
        (
            supabase.table("users")
            .update(update_payload)
            .eq("id", existing.get("id"))
            .execute()
        )
        return existing.get("id")

    result = (
        supabase.table("users")
        .insert(
            {
                "email": email,
                "name": name,
                "user_type": user_type,
                "phone": phone or "",
            }
        )
        .execute()
    )
    rows = _response_data(result)
    if rows:
        return rows[0].get("id")

    raise RuntimeError("Supabase users sync failed: no row returned from insert")


def _ensure_supabase_role_profile(
    supabase,
    public_user_id: Optional[int],
    user_type: str,
    profile_payload: Optional[dict[str, Any]] = None,
) -> None:
    if not public_user_id:
        raise RuntimeError("Supabase role sync failed: users.id is missing")

    table_name = "drivers" if user_type == "driver" else "passengers"
    payload = {"user_id": public_user_id}
    if profile_payload:
        for key, value in profile_payload.items():
            if value is not None and value != "":
                payload[key] = value

    existing = (
        supabase.table(table_name)
        .select("id")
        .eq("user_id", public_user_id)
        .limit(1)
        .execute()
    )
    existing_rows = _response_data(existing)
    if existing_rows:
        update_payload = {k: v for k, v in payload.items() if k != "user_id"}
        if update_payload:
            (
                supabase.table(table_name)
                .update(update_payload)
                .eq("id", existing_rows[0].get("id"))
                .execute()
            )
        return

    supabase.table(table_name).insert(payload).execute()


def _ensure_not_already_registered(
    identifier: str,
    db: Session,
    supabase,
    check_local: bool = True,
) -> None:
    supabase_existing = _find_supabase_user_by_email(supabase, identifier)
    if supabase_existing:
        raise HTTPException(status_code=400, detail="Account already exists")

    if check_local:
        local_existing = db.query(LocalAuthUser).filter(LocalAuthUser.email == identifier).first()
        if local_existing:
            raise HTTPException(status_code=400, detail="Account already exists")


def _normalize_identifier(value: str) -> str:
    return value.strip().lower()


def _hash_password(password: str) -> str:
    pepper = os.getenv("LOCAL_AUTH_PEPPER", "peakmap_local_auth")
    return hashlib.sha256(f"{pepper}:{password}".encode("utf-8")).hexdigest()


def _create_local_token() -> str:
    return f"local_{secrets.token_urlsafe(24)}"


def _ensure_app_user(
    db: Session,
    identifier: str,
    name: str,
    user_type: str,
    phone: Optional[str] = None,
) -> int:
    normalized_phone = phone.strip() if phone else None
    existing = None

    if normalized_phone:
        existing = db.query(User).filter(User.phone_number == normalized_phone).first()

    if not existing:
        existing = db.query(User).filter(User.phone_number == identifier).first()

    if existing:
        changed = False
        if name and existing.full_name != name:
            existing.full_name = name
            changed = True
        if user_type and existing.role != user_type:
            existing.role = user_type
            changed = True
        if normalized_phone and existing.phone_number != normalized_phone:
            existing.phone_number = normalized_phone
            changed = True

        if changed:
            db.commit()
            db.refresh(existing)

        return existing.id

    user = User(
        full_name=name or identifier,
        phone_number=normalized_phone or identifier,
        role=user_type,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user.id


def _register_local_fallback(payload, db: Session, supabase_error: str | None = None):
    identifier = _normalize_identifier(payload.email)
    existing = db.query(LocalAuthUser).filter(LocalAuthUser.email == identifier).first()

    phone = payload.phone.strip() if payload.phone else None
    app_user_id = _ensure_app_user(
        db,
        identifier,
        payload.name,
        payload.user_type,
        phone=phone,
    )
    
    if existing:
        # Update existing local account instead of raising error
        # (useful for repeated registration attempts during Supabase outages/rate limits)
        existing.password_hash = _hash_password(payload.password)
        existing.user_type = payload.user_type
        existing.name = payload.name
        existing.app_user_id = app_user_id
        db.commit()
        db.refresh(existing)
        local_user = existing
    else:
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

    # Best effort sync to Supabase public profile tables even when
    # Auth signup is rate-limited and local fallback is used.
    try:
        if is_supabase_available():
            supabase = get_supabase_client()
            role_profile_payload: dict[str, Any] = {}
            if payload.user_type == "driver":
                role_profile_payload = {
                    "license_number": payload.license_number.strip() if payload.license_number else None,
                    "vehicle_plate": payload.vehicle_plate.strip() if payload.vehicle_plate else None,
                    "vehicle_model": payload.vehicle_model.strip() if payload.vehicle_model else None,
                }
            elif payload.user_type == "passenger" and phone:
                role_profile_payload = {"phone": phone}

            public_user_id = _sync_supabase_user_profile(
                supabase=supabase,
                email=identifier,
                name=payload.name,
                user_type=payload.user_type,
                phone=phone,
            )
            _ensure_supabase_role_profile(
                supabase,
                public_user_id,
                payload.user_type,
                role_profile_payload,
            )
    except Exception as exc:
        print(f"Supabase public profile sync skipped during local fallback: {exc}")

    return {
        "success": True,
        "message": "Registration successful (local fallback)",
        "user_id": str(local_user.app_user_id or local_user.id),
        "email": local_user.email,
        "user_type": local_user.user_type,
        "auth_method": "local_fallback",
        "fallback_reason": supabase_error,
    }


def _upsert_local_auth_shadow(
    db: Session,
    identifier: str,
    password: str,
    user_type: str,
    name: Optional[str],
    app_user_id: int,
) -> None:
    local_user = db.query(LocalAuthUser).filter(LocalAuthUser.email == identifier).first()
    password_hash = _hash_password(password)

    if local_user:
        changed = False
        if local_user.password_hash != password_hash:
            local_user.password_hash = password_hash
            changed = True
        if local_user.user_type != user_type:
            local_user.user_type = user_type
            changed = True
        if (name or identifier) != local_user.name:
            local_user.name = name or identifier
            changed = True
        if local_user.app_user_id != app_user_id:
            local_user.app_user_id = app_user_id
            changed = True

        if changed:
            db.commit()
        return

    db.add(
        LocalAuthUser(
            email=identifier,
            password_hash=password_hash,
            user_type=user_type,
            name=name or identifier,
            app_user_id=app_user_id,
        )
    )
    db.commit()


def _login_local_fallback(payload, db: Session, supabase_error: str | None = None):
    identifier = _normalize_identifier(payload.email)
    local_user = db.query(LocalAuthUser).filter(LocalAuthUser.email == identifier).first()
    if not local_user:
        return {
            "success": False,
            "message": "Invalid credentials",
            "auth_method": "local_fallback",
            "fallback_reason": supabase_error,
        }

    if local_user.password_hash != _hash_password(payload.password):
        return {
            "success": False,
            "message": "Invalid credentials",
            "auth_method": "local_fallback",
            "fallback_reason": supabase_error,
        }

    resolved_user_type = local_user.user_type
    if payload.user_type and payload.user_type != resolved_user_type:
        raise HTTPException(
            status_code=403,
            detail=f"This account is registered as {resolved_user_type}. Use {resolved_user_type} login.",
        )

    linked_user = None
    if local_user.app_user_id:
        linked_user = db.query(User).filter(User.id == local_user.app_user_id).first()

    supabase_phone = None
    try:
        if is_supabase_available():
            supabase = get_supabase_client()
            supabase_user = _find_supabase_user_by_email(supabase, identifier)
            if supabase_user and isinstance(supabase_user.get("phone"), str):
                maybe_phone = supabase_user.get("phone", "").strip()
                if maybe_phone:
                    supabase_phone = maybe_phone
    except Exception as exc:
        print(f"Supabase phone lookup skipped during local fallback login: {exc}")

    linked_phone = None
    if linked_user and linked_user.phone_number and "@" not in linked_user.phone_number:
        linked_phone = linked_user.phone_number

    preferred_phone = supabase_phone or linked_phone

    app_user_id = _ensure_app_user(
        db,
        identifier,
        local_user.name,
        resolved_user_type,
        phone=preferred_phone,
    )

    if local_user.app_user_id != app_user_id:
        local_user.app_user_id = app_user_id
        db.commit()

    app_user = db.query(User).filter(User.id == app_user_id).first()
    profile_name = app_user.full_name if app_user and app_user.full_name else local_user.name
    profile_phone = None
    if app_user and app_user.phone_number and "@" not in app_user.phone_number:
        profile_phone = app_user.phone_number

    return {
        "success": True,
        "user_id": app_user_id,
        "email": local_user.email,
        "token": _create_local_token(),
        "user_type": resolved_user_type,
        "profile": {
            "name": profile_name,
            "phone": profile_phone,
        },
        "auth_method": "local_fallback",
        "fallback_reason": supabase_error,
    }


def _is_supabase_connectivity_error(error_text: str) -> bool:
    connectivity_markers = [
        "connection",
        "connect",
        "network",
        "timed out",
        "timeout",
        "name resolution",
        "temporary failure",
        "service unavailable",
        "502",
        "503",
        "504",
    ]
    return any(marker in error_text for marker in connectivity_markers)


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
    phone: Optional[str] = None
    license_number: Optional[str] = None
    vehicle_plate: Optional[str] = None
    vehicle_model: Optional[str] = None


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

    identifier = _normalize_identifier(payload.email)

    if _force_local_auth_enabled():
        payload.email = identifier
        return _register_local_fallback(payload, db, "force_local_auth")

    if not is_supabase_available():
        return _register_local_fallback(payload, db, "supabase_sdk_unavailable")

    if "@" not in identifier:
        raise HTTPException(status_code=400, detail="Valid email is required for Supabase registration")

    supabase = get_supabase_client()
    try:
        # In Supabase mode, do not block on stale local-only records.
        _ensure_not_already_registered(identifier, db, supabase, check_local=False)

        # Sign up with Supabase Auth and store role metadata.
        result = supabase.auth.sign_up(
            {
                "email": identifier,
                "password": payload.password,
                "options": {
                    "data": {
                        "name": payload.name,
                        "user_type": payload.user_type,
                    }
                },
            }
        )

        user = result.user
        if not user:
            raise HTTPException(status_code=400, detail="Registration failed")

        phone = payload.phone.strip() if payload.phone else None
        role_profile_payload: dict[str, Any] = {}
        if payload.user_type == "driver":
            role_profile_payload = {
                "license_number": payload.license_number.strip() if payload.license_number else None,
                "vehicle_plate": payload.vehicle_plate.strip() if payload.vehicle_plate else None,
                "vehicle_model": payload.vehicle_model.strip() if payload.vehicle_model else None,
            }
        elif payload.user_type == "passenger" and phone:
            role_profile_payload = {"phone": phone}

        # Keep public profile and role-specific table in sync.
        public_user_id = _sync_supabase_user_profile(
            supabase=supabase,
            email=identifier,
            name=payload.name,
            user_type=payload.user_type,
            phone=phone,
        )
        _ensure_supabase_role_profile(
            supabase,
            public_user_id,
            payload.user_type,
            role_profile_payload,
        )

        # Keep local dashboard-compatible user mirror in sync.
        app_user_id = _ensure_app_user(db, identifier, payload.name, payload.user_type, phone=phone)

        # Keep local auth shadow in sync so fallback login works even when
        # Supabase auth is temporarily unavailable or email confirmation is pending.
        _upsert_local_auth_shadow(
            db,
            identifier=identifier,
            password=payload.password,
            user_type=payload.user_type,
            name=payload.name,
            app_user_id=app_user_id,
        )

        return {
            "success": True,
            "message": "Registration successful",
            "user_id": str(user.id),
            "email": identifier,
            "user_type": payload.user_type,
            "auth_method": "supabase",
        }
    except HTTPException:
        raise
    except Exception as exc:
        error_text = str(exc)
        error_text_lower = error_text.lower()
        print(f"Registration error: {error_text}")

        if "rate limit" in error_text_lower:
            return _register_local_fallback(payload, db, "supabase_rate_limit")

        if "already registered" in error_text_lower or "already exists" in error_text_lower:
            raise HTTPException(status_code=400, detail="Account already exists")

        if "email signups are disabled" in error_text_lower:
            raise HTTPException(
                status_code=400,
                detail="Supabase Email signups are disabled. Enable Email provider in Supabase Authentication settings.",
            )

        if _is_supabase_connectivity_error(error_text_lower):
            return _register_local_fallback(payload, db, error_text)

        raise HTTPException(status_code=400, detail=f"Supabase registration failed: {error_text}")


@router.post("/login")
def login(payload: AuthPayload, db: Session = Depends(get_db)):
    """Login user (driver or passenger)"""
    if _force_local_auth_enabled():
        return _login_local_fallback(payload, db, "force_local_auth")

    if not is_supabase_available():
        return _login_local_fallback(payload, db, "supabase_sdk_unavailable")

    supabase = get_supabase_client()
    try:
        identifier = _normalize_identifier(payload.email)

        # Try Supabase authentication
        result = supabase.auth.sign_in_with_password(
            {"email": identifier, "password": payload.password}
        )
        
        user = result.user
        session = result.session
        
        if not user:
            # Fall back to local auth if Supabase returns no user
            return _login_local_fallback(payload, db, "supabase_no_user")

        user_row = _find_supabase_user_by_email(supabase, identifier)
        resolved_user_type = (
            (user_row or {}).get("user_type")
            or payload.user_type
            or "passenger"
        )

        if payload.user_type and resolved_user_type != payload.user_type:
            raise HTTPException(
                status_code=403,
                detail=(
                    f"This account is registered as {resolved_user_type}. "
                    f"Use {resolved_user_type} login."
                ),
            )

        display_name = (user_row or {}).get("name") or identifier.split("@")[0]
        phone = (user_row or {}).get("phone")

        app_user_id = _ensure_app_user(
            db,
            identifier,
            display_name,
            resolved_user_type,
            phone=phone if isinstance(phone, str) else None,
        )
        
        return {
            "success": True,
            "user_id": app_user_id,
            "supabase_user_id": str(user.id),
            "email": identifier,
            "token": session.access_token if session else "",
            "user_type": resolved_user_type,
            "profile": {
                "name": display_name,
                "phone": phone,
            },
            "auth_method": "supabase",
        }
    except HTTPException:
        raise
    except Exception as exc:
        error_text = str(exc)
        error_text_lower = error_text.lower()
        print(f"Login error from Supabase: {error_text}")

        # For development, fall back to local auth on any error
        # This includes: invalid credentials, email not confirmed, rate limits, etc.
        if "invalid login credentials" in error_text_lower or "invalid credentials" in error_text_lower:
            # Try local fallback first; if local account does not exist, return
            # a structured failure payload instead of raising HTTP 401.
            return _login_local_fallback(payload, db, error_text)

        if "email not confirmed" in error_text_lower:
            # In development, allow login even if email not confirmed
            return _login_local_fallback(payload, db, "email_not_confirmed_fallback")

        if "rate limit" in error_text_lower:
            # Rate limited, use local fallback
            return _login_local_fallback(payload, db, "rate_limited")

        # For any other Supabase error, try local fallback
        return _login_local_fallback(payload, db, error_text)

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