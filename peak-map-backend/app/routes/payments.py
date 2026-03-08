from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, field_validator
from sqlalchemy.orm import Session
from typing import Optional

from app.database import get_db
from app.models.payment import Payment
from app.models.ride import Ride
from app.services.fare_service import get_fare

router = APIRouter(prefix="/payments", tags=["Payments"])


class PaymentInitiate(BaseModel):
    ride_id: int
    method: str  # cash | gcash | ewallet
    
    @field_validator('method')
    @classmethod
    def validate_method(cls, v):
        if v not in ["cash", "gcash", "ewallet"]:
            raise ValueError('Payment method must be: cash, gcash, or ewallet')
        return v


class PaymentConfirm(BaseModel):
    payment_id: int


class WebhookData(BaseModel):
    reference: str
    status: str
    amount: float


class BalanceLoadPayload(BaseModel):
    user_id: str
    amount: float
    payment_method: str = "admin_nfc"
    card_id: Optional[str] = None


class BalanceCheckPayload(BaseModel):
    user_id: str
    card_id: Optional[str] = None


@router.post("/initiate", response_model=dict)
def initiate_payment(data: PaymentInitiate, db: Session = Depends(get_db)):
    """
    Initiate a payment for a ride.
    Payment method: cash, gcash, or ewallet.
    """
    # Verify ride exists
    ride = db.query(Ride).filter(Ride.id == data.ride_id).first()
    if not ride:
        raise HTTPException(status_code=404, detail="Ride not found")
    
    # Check if payment already exists for this ride
    existing_payment = db.query(Payment).filter(
        Payment.ride_id == data.ride_id,
        Payment.status.in_(["pending", "paid"])
    ).first()
    
    if existing_payment:
        raise HTTPException(
            status_code=400, 
            detail=f"Payment already exists for this ride (ID: {existing_payment.id}, status: {existing_payment.status})"
        )
    
    # Get fare amount from ride
    if not ride.fare_amount:
        raise HTTPException(status_code=400, detail="Fare not set for this ride")
    
    # Create payment record
    payment = Payment(
        ride_id=data.ride_id,
        amount=ride.fare_amount,
        method=data.method,
        status="pending"
    )
    
    db.add(payment)
    db.commit()
    db.refresh(payment)
    
    return {
        "message": "Payment initiated",
        "payment_id": payment.id,
        "amount": payment.amount,
        "method": payment.method,
        "status": payment.status,
        "ride_id": data.ride_id
    }


@router.post("/confirm", response_model=dict)
def confirm_payment(data: PaymentConfirm, db: Session = Depends(get_db)):
    """
    Confirm payment (works for all payment methods).
    Updates payment status from pending to paid.
    """
    payment = db.query(Payment).filter(Payment.id == data.payment_id).first()
    
    if not payment:
        raise HTTPException(status_code=404, detail="Payment not found")
    
    if payment.status == "paid":
        return {"message": "Payment already confirmed", "status": "paid"}
    
    if payment.status == "failed":
        raise HTTPException(status_code=400, detail="Cannot confirm failed payment")
    
    # Update payment status
    payment.status = "paid"
    payment.paid_at = datetime.utcnow()
    
    db.commit()
    
    return {
        "message": "✅ Payment confirmed",
        "payment_id": payment.id,
        "method": payment.method,
        "status": "paid",
        "amount": payment.amount,
        "paid_at": str(payment.paid_at)
    }


@router.post("/cash/confirm", response_model=dict)
def confirm_cash_payment(data: PaymentConfirm, db: Session = Depends(get_db)):
    """
    Driver confirms cash payment received.
    This is called after passenger hands cash to driver.
    """
    payment = db.query(Payment).filter(Payment.id == data.payment_id).first()
    
    if not payment:
        raise HTTPException(status_code=404, detail="Payment not found")
    
    if payment.method != "cash":
        raise HTTPException(status_code=400, detail="This is not a cash payment")
    
    if payment.status == "paid":
        return {"message": "Payment already confirmed", "status": "paid"}
    
    if payment.status == "failed":
        raise HTTPException(status_code=400, detail="Cannot confirm failed payment")
    
    # Update payment status
    payment.status = "paid"
    payment.paid_at = datetime.utcnow()
    
    db.commit()
    
    return {
        "message": "✅ Cash payment confirmed",
        "payment_id": payment.id,
        "status": "paid",
        "amount": payment.amount,
        "paid_at": str(payment.paid_at)
    }


@router.post("/gcash/initiate", response_model=dict)
def initiate_gcash_payment(payment_id: int, db: Session = Depends(get_db)):
    """
    Initiate GCash payment.
    In production, this would integrate with PayMongo or Xendit.
    For now, returns a mock checkout URL.
    """
    payment = db.query(Payment).filter(Payment.id == payment_id).first()
    
    if not payment:
        return {"error": "Payment not found"}
    
    if payment.method != "gcash":
        return {"error": "This is not a GCash payment"}
    
    # Generate reference number
    import uuid
    reference = f"GCASH-{uuid.uuid4().hex[:8].upper()}"
    payment.reference = reference
    db.commit()
    
    # In production, you would call PayMongo/Xendit API here
    # Example: paymongo.create_payment_intent(amount=payment.amount)
    
    # Mock response - in production this would be real checkout URL
    return {
        "message": "GCash payment initiated",
        "payment_id": payment.id,
        "reference": reference,
        "checkout_url": f"https://payment-gateway.example.com/checkout/{reference}",
        "amount": payment.amount,
        "note": "⚠️ This is a mock URL. Integrate with PayMongo/Xendit for production."
    }


@router.post("/ewallet/initiate", response_model=dict)
def initiate_ewallet_payment(payment_id: int, db: Session = Depends(get_db)):
    """
    Initiate e-wallet payment (Maya, PayMaya, etc.).
    Similar to GCash, integrates with payment gateway.
    """
    payment = db.query(Payment).filter(Payment.id == payment_id).first()
    
    if not payment:
        return {"error": "Payment not found"}
    
    if payment.method != "ewallet":
        return {"error": "This is not an e-wallet payment"}
    
    # Generate reference number
    import uuid
    reference = f"EWALLET-{uuid.uuid4().hex[:8].upper()}"
    payment.reference = reference
    db.commit()
    
    # In production, integrate with payment gateway
    return {
        "message": "E-wallet payment initiated",
        "payment_id": payment.id,
        "reference": reference,
        "checkout_url": f"https://payment-gateway.example.com/checkout/{reference}",
        "amount": payment.amount,
        "note": "⚠️ This is a mock URL. Integrate with payment gateway for production."
    }


@router.post("/webhook/gcash", response_model=dict)
def gcash_webhook(data: WebhookData, db: Session = Depends(get_db)):
    """
    Webhook endpoint for GCash payment confirmation.
    Payment gateway calls this when payment is successful.
    
    IMPORTANT: In production, verify webhook signature!
    """
    payment = db.query(Payment).filter(
        Payment.reference == data.reference
    ).first()
    
    if not payment:
        return {"error": "Payment not found", "status": "failed"}
    
    # Update payment status based on webhook data
    if data.status == "paid" or data.status == "success":
        payment.status = "paid"
        payment.paid_at = datetime.utcnow()
    elif data.status == "failed":
        payment.status = "failed"
    
    db.commit()
    
    return {
        "status": "ok",
        "message": "Webhook processed",
        "payment_id": payment.id,
        "payment_status": payment.status
    }


@router.get("/{payment_id}", response_model=dict)
def get_payment(payment_id: int, db: Session = Depends(get_db)):
    """Get payment details"""
    payment = db.query(Payment).filter(Payment.id == payment_id).first()
    
    if not payment:
        return {"error": "Payment not found"}
    
    return {
        "id": payment.id,
        "ride_id": payment.ride_id,
        "amount": payment.amount,
        "method": payment.method,
        "status": payment.status,
        "reference": payment.reference,
        "created_at": str(payment.created_at),
        "paid_at": str(payment.paid_at) if payment.paid_at else None
    }


@router.get("/ride/{ride_id}", response_model=dict)
def get_payment_by_ride(ride_id: int, db: Session = Depends(get_db)):
    """Get payment for a specific ride"""
    payment = db.query(Payment).filter(Payment.ride_id == ride_id).first()
    
    if not payment:
        return {"error": "No payment found for this ride"}
    
    return {
        "id": payment.id,
        "ride_id": payment.ride_id,
        "amount": payment.amount,
        "method": payment.method,
        "status": payment.status,
        "reference": payment.reference,
        "created_at": str(payment.created_at),
        "paid_at": str(payment.paid_at) if payment.paid_at else None
    }


@router.get("/", response_model=list[dict])
def get_all_payments(
    status: str | None = None,
    method: str | None = None,
    db: Session = Depends(get_db)
):
    """Get all payments with optional filters"""
    query = db.query(Payment)
    
    if status:
        query = query.filter(Payment.status == status)
    if method:
        query = query.filter(Payment.method == method)
    
    payments = query.order_by(Payment.created_at.desc()).all()
    
    result = []
    for payment in payments:
        result.append({
            "id": payment.id,
            "ride_id": payment.ride_id,
            "amount": payment.amount,
            "method": payment.method,
            "status": payment.status,
            "reference": payment.reference,
            "created_at": str(payment.created_at),
            "paid_at": str(payment.paid_at) if payment.paid_at else None
        })
    
    return result


# ============ NFC BALANCE LOADING ENDPOINTS ============

@router.post("/load-balance")
def load_balance(payload: BalanceLoadPayload, db: Session = Depends(get_db)):
    """Admin endpoint to load balance to user's account via NFC"""
    try:
        print(f"✅ Balance Load Request: User {payload.user_id}, Amount ₱{payload.amount}")
        
        # Validate amount
        if payload.amount <= 0:
            raise HTTPException(status_code=400, detail="Amount must be greater than 0")
        
        # Create balance load transaction
        payment = Payment(
            user_id=payload.user_id,  # Store Supabase user ID
            ride_id=0,  # Legacy SQLite compatibility (non-null ride_id)
            amount=payload.amount,
            method="admin_nfc",  # Mark as admin NFC load
            status="paid",
            reference=f"NFC-{payload.user_id}-{datetime.utcnow().timestamp()}",
            paid_at=datetime.utcnow(),
        )
        
        db.add(payment)
        db.commit()
        db.refresh(payment)
        
        print(f"✅ Balance loaded successfully: ₱{payload.amount} for user {payload.user_id}")
        
        return {
            "success": True,
            "message": f"Balance of ₱{payload.amount} loaded successfully",
            "transaction_id": payment.id,
            "user_id": payload.user_id,
            "amount": payload.amount,
            "card_id": payload.card_id,
            "timestamp": str(payment.created_at),
        }
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Balance load error: {e}")
        raise HTTPException(status_code=500, detail=f"Balance load failed: {str(e)}")


@router.post("/balance/check")
def check_balance_nfc(payload: BalanceCheckPayload, db: Session = Depends(get_db)):
    """Check balance via NFC card scan"""
    try:
        # Get all paid NFC transactions for this user only
        payments = db.query(Payment).filter(
            Payment.user_id == payload.user_id,
            Payment.status == "paid",
        ).all()

        # Calculate balance: loads (admin_nfc) minus deductions (bus_fare_nfc)
        total_balance = 0.0
        for payment in payments:
            if payment.method == "admin_nfc":
                total_balance += payment.amount
            elif payment.method == "bus_fare_nfc":
                total_balance -= payment.amount

        return {
            "success": True,
            "user_id": payload.user_id,
            "card_id": payload.card_id,
            "balance": float(total_balance),
            "message": f"User {payload.user_id} has a balance of ₱{total_balance}",
        }
    except Exception as e:
        print(f"NFC balance check error: {e}")
        raise HTTPException(status_code=500, detail=f"Balance check failed: {str(e)}")


@router.get("/balance/{user_id}")
def get_user_balance(user_id: str, db: Session = Depends(get_db)):
    """Get user's current balance (sum of all loads minus deductions)"""
    try:
        # Get all transactions for this user
        payments = db.query(Payment).filter(
            Payment.user_id == user_id,
            Payment.status == "paid",
        ).all()

        # Calculate balance: loads (admin_nfc) minus deductions (bus_fare_nfc)
        total_balance = 0.0
        for p in payments:
            if p.method == "admin_nfc":
                total_balance += p.amount  # Add loaded amount
            elif p.method == "bus_fare_nfc":
                total_balance -= p.amount  # Subtract fare deduction

        return {
            "success": True,
            "user_id": user_id,
            "balance": float(total_balance),
        }
    except Exception as e:
        print(f"Balance check error: {e}")
        raise HTTPException(status_code=500, detail=f"Balance retrieval failed: {str(e)}")


@router.get("/transactions/admin")
def get_all_nfc_transactions(db: Session = Depends(get_db)):
    """Get all NFC balance load transactions (admin view)"""
    try:
        # Get all admin NFC load transactions, most recent first
        payments = db.query(Payment).filter(
            Payment.method == "admin_nfc",
            Payment.status == "paid",
        ).order_by(Payment.created_at.desc()).limit(50).all()
        
        return {
            "success": True,
            "transaction_count": len(payments),
            "transactions": [
                {
                    "id": p.id,
                    "user_id": p.user_id,
                    "amount": p.amount,
                    "method": p.method,
                    "status": p.status,
                    "created_at": str(p.created_at),
                    "paid_at": str(p.paid_at) if p.paid_at else None,
                }
                for p in payments
            ],
        }
    except Exception as e:
        print(f"Admin transaction retrieval error: {e}")
        return {
            "success": True,
            "transaction_count": 0,
            "transactions": [],
        }


@router.get("/transactions/{user_id}")
def get_user_transactions(user_id: str, db: Session = Depends(get_db)):
    """Get all balance transactions for a user (loads and deductions)"""
    try:
        # Get all transactions for this user, most recent first
        payments = db.query(Payment).filter(
            Payment.user_id == user_id,
        ).order_by(Payment.created_at.desc()).limit(20).all()
        
        return {
            "success": True,
            "user_id": user_id,
            "transaction_count": len(payments),
            "transactions": [
                {
                    "id": p.id,
                    "amount": p.amount,
                    "method": p.method,  # admin_nfc (load) or bus_fare_nfc (deduction)
                    "status": p.status,
                    "created_at": str(p.created_at),
                    "paid_at": str(p.paid_at) if p.paid_at else None,
                    "transaction_type": "load" if p.method == "admin_nfc" else "deduction",
                }
                for p in payments
            ],
        }
    except Exception as e:
        print(f"Transaction retrieval error: {e}")
        return {
            "success": True,
            "user_id": user_id,
            "transaction_count": 0,
            "transactions": [],
        }


# ============ BUS ENTRY FARE DEDUCTION ============

class FareDeductPayload(BaseModel):
    user_id: str
    amount: float
    bus_id: str
    driver_id: str


class TapInPayload(BaseModel):
    user_id: str
    bus_id: str
    driver_id: str
    station_id: int
    card_uid: Optional[str] = None


class TapOutPayload(BaseModel):
    user_id: str
    bus_id: str
    driver_id: str
    station_id: int
    card_uid: Optional[str] = None


def _calculate_user_balance(db: Session, user_id: str) -> float:
    user_payments = db.query(Payment).filter(
        Payment.user_id == user_id,
        Payment.status == "paid",
    ).all()

    balance = 0.0
    for payment in user_payments:
        if payment.method == "admin_nfc":
            balance += payment.amount
        elif payment.method == "bus_fare_nfc":
            balance -= payment.amount

    return float(balance)


def _is_card_blocked(db: Session, user_id: str) -> bool:
    return db.query(Payment).filter(
        Payment.user_id == user_id,
        Payment.method == "card_blocked",
        Payment.status == "paid",
    ).first() is not None


@router.post("/tap-in")
def tap_in_passenger(payload: TapInPayload, db: Session = Depends(get_db)):
    """Passenger taps in when entering a bus via an NFC/RFID scanner."""
    try:
        if _is_card_blocked(db, payload.user_id):
            return {
                "success": False,
                "error": "Card is blocked",
                "status": "entry_denied",
            }

        # Prevent rapid duplicate tap-ins (same user within 8 seconds)
        recent_tap_in = db.query(Payment).filter(
            Payment.user_id == payload.user_id,
            Payment.method == "tap_in_nfc",
            Payment.created_at >= datetime.utcnow() - timedelta(seconds=8)
        ).order_by(Payment.created_at.desc()).first()

        if recent_tap_in:
            return {
                "success": False,
                "error": "Duplicate tap-in detected. Please wait a moment.",
                "status": "duplicate_tap_in",
            }

        # Only one open trip at a time
        open_trip = db.query(Payment).filter(
            Payment.user_id == payload.user_id,
            Payment.method == "tap_in_nfc",
            Payment.status == "pending",
        ).order_by(Payment.created_at.desc()).first()

        if open_trip:
            return {
                "success": False,
                "error": "Passenger already tapped in. Tap out first.",
                "status": "already_tapped_in",
                "open_trip_reference": open_trip.reference,
            }

        balance = _calculate_user_balance(db, payload.user_id)
        
        # Store card_uid in reference for matching on tap-out
        card_uid = payload.card_uid or "UNKNOWN"

        tap_in = Payment(
            user_id=payload.user_id,
            ride_id=0,
            amount=0.0,
            method="tap_in_nfc",
            status="pending",  # pending = open trip
            reference=f"TAPIN-{card_uid}-{payload.user_id}-{payload.bus_id}-{payload.station_id}-{datetime.utcnow().timestamp()}",
            paid_at=None,
        )

        db.add(tap_in)
        db.commit()
        db.refresh(tap_in)

        return {
            "success": True,
            "message": "Tap-in successful",
            "status": "entry_granted",
            "tap_in_id": tap_in.id,
            "user_id": payload.user_id,
            "bus_id": payload.bus_id,
            "driver_id": payload.driver_id,
            "station_id": payload.station_id,
            "card_uid": payload.card_uid,
            "current_balance": balance,
            "timestamp": str(tap_in.created_at),
        }
    except Exception as e:
        print(f"❌ Tap-in error: {e}")
        return {
            "success": False,
            "error": str(e),
            "status": "entry_error",
        }


@router.post("/tap-out")
def tap_out_passenger(payload: TapOutPayload, db: Session = Depends(get_db)):
    """Passenger taps out when exiting a bus; fare is computed and deducted."""
    try:
        # Prevent rapid duplicate tap-outs
        recent_tap_out = db.query(Payment).filter(
            Payment.user_id == payload.user_id,
            Payment.method == "tap_out_nfc",
            Payment.created_at >= datetime.utcnow() - timedelta(seconds=8)
        ).order_by(Payment.created_at.desc()).first()

        if recent_tap_out:
            return {
                "success": False,
                "error": "Duplicate tap-out detected. Please wait a moment.",
                "status": "duplicate_tap_out",
            }

        open_trip = db.query(Payment).filter(
            Payment.user_id == payload.user_id,
            Payment.method == "tap_in_nfc",
            Payment.status == "pending",
        ).order_by(Payment.created_at.desc()).first()

        if not open_trip:
            return {
                "success": False,
                "error": "No active tap-in found. Passenger must tap in first.",
                "status": "no_open_trip",
            }

        # Parse from TAPIN reference format:
        # TAPIN-{card_uid}-{user_id}-{bus_id}-{station_id}-{timestamp}
        from_station_id = None
        tap_in_card_uid = None
        if open_trip.reference:
            ref_parts = open_trip.reference.split("-")
            if len(ref_parts) >= 6:
                try:
                    tap_in_card_uid = ref_parts[1]  # Extract card_uid from tap-in
                    from_station_id = int(ref_parts[-2])
                except (ValueError, IndexError):
                    from_station_id = None
            elif len(ref_parts) >= 5:  # Old format without card_uid
                try:
                    from_station_id = int(ref_parts[-2])
                except ValueError:
                    from_station_id = None
        
        # Verify the same card is being used for tap-out
        if tap_in_card_uid and payload.card_uid and tap_in_card_uid != payload.card_uid:
            return {
                "success": False,
                "error": f"Card mismatch! You tapped in with card {tap_in_card_uid} but tapping out with {payload.card_uid}",
                "status": "card_mismatch",
                "expected_card": tap_in_card_uid,
                "provided_card": payload.card_uid,
            }

        if from_station_id is None:
            return {
                "success": False,
                "error": "Invalid tap-in reference. Cannot determine boarding station.",
                "status": "invalid_open_trip",
            }

        if from_station_id == payload.station_id:
            return {
                "success": False,
                "error": "Tap-out station cannot be the same as tap-in station.",
                "status": "invalid_tap_out_station",
            }

        fare_amount = get_fare(db, from_station_id=from_station_id, to_station_id=payload.station_id)
        if fare_amount is None:
            return {
                "success": False,
                "error": f"Fare not configured from station {from_station_id} to {payload.station_id}",
                "status": "fare_not_found",
            }

        current_balance = _calculate_user_balance(db, payload.user_id)
        if current_balance < fare_amount:
            return {
                "success": False,
                "error": f"Insufficient balance. Available: ₱{current_balance}, Required: ₱{fare_amount}",
                "status": "exit_denied_insufficient_balance",
                "balance": float(current_balance),
                "required": float(fare_amount),
            }

        # Deduct fare
        card_uid = payload.card_uid or tap_in_card_uid or "UNKNOWN"
        
        fare_payment = Payment(
            user_id=payload.user_id,
            ride_id=0,
            amount=float(fare_amount),
            method="bus_fare_nfc",
            status="paid",
            reference=f"BUSFARE-{card_uid}-{payload.user_id}-{payload.bus_id}-{from_station_id}-{payload.station_id}-{datetime.utcnow().timestamp()}",
            paid_at=datetime.utcnow(),
        )

        # Log tap-out event
        tap_out = Payment(
            user_id=payload.user_id,
            ride_id=0,
            amount=0.0,
            method="tap_out_nfc",
            status="paid",
            reference=f"TAPOUT-{card_uid}-{payload.user_id}-{payload.bus_id}-{payload.station_id}-{datetime.utcnow().timestamp()}",
            paid_at=datetime.utcnow(),
        )

        # Close open trip
        open_trip.status = "paid"
        open_trip.paid_at = datetime.utcnow()

        db.add(fare_payment)
        db.add(tap_out)
        db.commit()
        db.refresh(fare_payment)

        new_balance = current_balance - float(fare_amount)

        return {
            "success": True,
            "message": "Tap-out successful. Fare deducted.",
            "status": "exit_granted",
            "user_id": payload.user_id,
            "bus_id": payload.bus_id,
            "driver_id": payload.driver_id,
            "card_uid": card_uid,
            "card_matched": tap_in_card_uid == payload.card_uid if (tap_in_card_uid and payload.card_uid) else True,
            "from_station_id": from_station_id,
            "to_station_id": payload.station_id,
            "fare_amount": float(fare_amount),
            "previous_balance": float(current_balance),
            "new_balance": float(new_balance),
            "fare_transaction_id": fare_payment.id,
            "timestamp": str(fare_payment.created_at),
        }
    except Exception as e:
        print(f"❌ Tap-out error: {e}")
        return {
            "success": False,
            "error": str(e),
            "status": "exit_error",
        }


@router.post("/deduct-fare")
def deduct_fare(payload: FareDeductPayload, db: Session = Depends(get_db)):
    """Deduct bus fare from user's loaded balance (Bus Entry Scanner)"""
    try:
        print(f"🚌 Fare Deduction: User {payload.user_id}, Amount ₱{payload.amount}")
        
        # Validate amount
        if payload.amount <= 0:
            raise HTTPException(status_code=400, detail="Fare amount must be greater than 0")
        
        # Get user's current balance (loads minus deductions)
        user_payments = db.query(Payment).filter(
            Payment.user_id == payload.user_id,
            Payment.status == "paid",
        ).all()
        
        # Calculate balance: loads minus deductions
        current_balance = 0.0
        for p in user_payments:
            if p.method == "admin_nfc":
                current_balance += p.amount  # Add loaded amount
            elif p.method == "bus_fare_nfc":
                current_balance -= p.amount  # Subtract fare deduction
        
        # Check if balance is sufficient
        if current_balance < payload.amount:
            print(f"❌ Insufficient balance: ₱{current_balance} < ₱{payload.amount}")
            return {
                "success": False,
                "error": f"Insufficient balance. Available: ₱{current_balance}, Required: ₱{payload.amount}",
                "balance": float(current_balance),
                "required": float(payload.amount),
            }
        
        # Create fare deduction transaction
        fare_payment = Payment(
            user_id=payload.user_id,  # Store user ID
            ride_id=0,
            amount=payload.amount,
            method="bus_fare_nfc",  # Mark as bus fare payment
            status="paid",
            reference=f"BUSFARE-{payload.user_id}-{payload.bus_id}-{datetime.utcnow().timestamp()}",
            paid_at=datetime.utcnow(),
        )
        
        db.add(fare_payment)
        db.commit()
        db.refresh(fare_payment)
        
        # Calculate new balance
        new_balance = current_balance - payload.amount
        
        print(f"✅ Fare deducted successfully: ₱{payload.amount}")
        print(f"   New balance: ₱{new_balance}")
        
        return {
            "success": True,
            "message": f"Fare of ₱{payload.amount} deducted successfully",
            "transaction_id": fare_payment.id,
            "user_id": payload.user_id,
            "bus_id": payload.bus_id,
            "driver_id": payload.driver_id,
            "fare_amount": float(payload.amount),
            "previous_balance": float(current_balance),
            "new_balance": float(new_balance),
            "status": "entry_granted",
            "timestamp": str(fare_payment.created_at),
        }
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Fare deduction error: {e}")
        # Return error with balance info
        return {
            "success": False,
            "error": f"Error processing fare: {str(e)}",
            "status": "error",
        }

# ============ DRIVER SALES REPORT ============

@router.get("/driver/{driver_id}/daily-sales")
def get_driver_daily_sales(driver_id: int, db: Session = Depends(get_db)):
    """Get driver's daily sales (bus fare deductions processed)"""
    try:
        # Get all bus fare transactions for rides driven by this driver
        # Note: In a real system, you'd join with rides table to filter by driver_id
        # For now, return aggregated data
        fare_deductions = db.query(Payment).filter(
            Payment.method == "bus_fare_nfc",
            Payment.status == "paid",
        ).all()
        
        total_fares = sum(p.amount for p in fare_deductions)
        transaction_count = len(fare_deductions)
        
        # Group by date for daily breakdown
        daily_breakdown = {}
        for payment in fare_deductions:
            date = payment.created_at.date() if payment.created_at else None
            if date:
                if str(date) not in daily_breakdown:
                    daily_breakdown[str(date)] = {"amount": 0.0, "count": 0}
                daily_breakdown[str(date)]["amount"] += payment.amount
                daily_breakdown[str(date)]["count"] += 1
        
        return {
            "success": True,
            "driver_id": driver_id,
            "total_daily_earnings": float(total_fares),
            "transaction_count": transaction_count,
            "daily_breakdown": daily_breakdown,
            "currency": "PHP",
            "last_updated": str(datetime.utcnow()),
        }
    except Exception as e:
        print(f"❌ Daily sales error: {e}")
        return {
            "success": False,
            "driver_id": driver_id,
            "error": str(e),
        }


# ============ TRANSACTION REFUND/REVERSAL ============

class RefundPayload(BaseModel):
    reason: Optional[str] = None
    refunded_by: Optional[str] = None  # Admin user ID


@router.post("/refund/{transaction_id}")
def refund_transaction(transaction_id: int, payload: RefundPayload, db: Session = Depends(get_db)):
    """Refund a transaction and reverse the balance change"""
    try:
        # Get original transaction
        original = db.query(Payment).filter(Payment.id == transaction_id).first()
        
        if not original:
            raise HTTPException(status_code=404, detail="Transaction not found")
        
        if original.status != "paid":
            raise HTTPException(status_code=400, detail="Can only refund paid transactions")
        
        # Check if already refunded
        existing_refund = db.query(Payment).filter(
            Payment.reference.like(f"REFUND-{transaction_id}-%")
        ).first()
        
        if existing_refund:
            return {
                "success": False,
                "error": "Transaction already refunded",
                "refund_id": existing_refund.id,
            }
        
        # Create reverse transaction
        refund = Payment(
            user_id=original.user_id,
            ride_id=original.ride_id,
            amount=-original.amount,  # Negative amount to reverse
            method=original.method,
            status="paid",
            reference=f"REFUND-{transaction_id}-{datetime.utcnow().timestamp()}",
            paid_at=datetime.utcnow(),
        )
        
        db.add(refund)
        db.commit()
        db.refresh(refund)
        
        print(f"✅ Transaction {transaction_id} refunded: ₱{original.amount} reversed")
        
        # Recalculate user balance
        if original.user_id:
            user_payments = db.query(Payment).filter(
                Payment.user_id == original.user_id,
                Payment.status == "paid",
            ).all()
            
            new_balance = 0.0
            for p in user_payments:
                if p.method == "admin_nfc":
                    new_balance += p.amount
                elif p.method in ("bus_fare_nfc",):
                    new_balance -= p.amount
        else:
            new_balance = 0.0
        
        return {
            "success": True,
            "message": f"Transaction refunded successfully",
            "original_transaction_id": transaction_id,
            "refund_transaction_id": refund.id,
            "refund_amount": float(original.amount),
            "user_id": original.user_id,
            "new_user_balance": float(new_balance),
            "reason": payload.reason,
            "refunded_by": payload.refunded_by,
            "timestamp": str(refund.created_at),
        }
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Refund error: {e}")
        return {
            "success": False,
            "error": str(e),
        }


# ============ CARD MANAGEMENT ============

class CardStatusPayload(BaseModel):
    status: str  # active | blocked | lost
    reason: Optional[str] = None


@router.post("/card/{user_id}/block")
def block_card(user_id: str, payload: CardStatusPayload, db: Session = Depends(get_db)):
    """Block user's card (no more transactions allowed)"""
    try:
        # Create a marker transaction to track card blocking
        block_transaction = Payment(
            user_id=user_id,
            ride_id=0,  # Legacy SQLite compatibility (non-null ride_id)
            amount=0.0,
            method="card_blocked",
            status="paid",
            reference=f"BLOCK-{user_id}-{datetime.utcnow().timestamp()}",
            paid_at=datetime.utcnow(),
        )
        
        db.add(block_transaction)
        db.commit()
        db.refresh(block_transaction)
        
        print(f"✅ Card blocked for user {user_id}: {payload.reason}")
        
        return {
            "success": True,
            "message": "Card blocked successfully",
            "user_id": user_id,
            "status": "blocked",
            "reason": payload.reason,
            "timestamp": str(block_transaction.created_at),
        }
    except Exception as e:
        print(f"❌ Card block error: {e}")
        return {
            "success": False,
            "error": str(e),
        }


@router.post("/card/{user_id}/replace")
def request_card_replacement(user_id: str, payload: CardStatusPayload, db: Session = Depends(get_db)):
    """Request replacement for lost/damaged card"""
    try:
        # Create replacement request marker
        replacement_transaction = Payment(
            user_id=user_id,
            ride_id=0,  # Legacy SQLite compatibility (non-null ride_id)
            amount=0.0,
            method="card_replacement",
            status="pending",
            reference=f"REPLACE-{user_id}-{datetime.utcnow().timestamp()}",
        )
        
        db.add(replacement_transaction)
        db.commit()
        db.refresh(replacement_transaction)
        
        print(f"✅ Card replacement requested for user {user_id}: {payload.reason}")
        
        return {
            "success": True,
            "message": "Card replacement request submitted",
            "user_id": user_id,
            "status": "pending_replacement",
            "reason": payload.reason,
            "request_id": replacement_transaction.id,
            "timestamp": str(replacement_transaction.created_at),
        }
    except Exception as e:
        print(f"❌ Replacement request error: {e}")
        return {
            "success": False,
            "error": str(e),
        }


@router.get("/card/{user_id}/status")
def get_card_status(user_id: str, db: Session = Depends(get_db)):
    """Check card status for user"""
    try:
        # Check for block markers
        is_blocked = db.query(Payment).filter(
            Payment.user_id == user_id,
            Payment.method == "card_blocked",
        ).first() is not None
        
        # Check for replacement requests
        replacement = db.query(Payment).filter(
            Payment.user_id == user_id,
            Payment.method == "card_replacement",
            Payment.status == "pending",
        ).first()
        
        status = "blocked" if is_blocked else "active"
        if replacement:
            status = "pending_replacement"
        
        return {
            "success": True,
            "user_id": user_id,
            "status": status,  # active | blocked | pending_replacement
            "is_blocked": is_blocked,
            "has_replacement_pending": replacement is not None,
            "replacement_request_id": replacement.id if replacement else None,
        }
    except Exception as e:
        print(f"❌ Card status error: {e}")
        return {
            "success": False,
            "error": str(e),
        }