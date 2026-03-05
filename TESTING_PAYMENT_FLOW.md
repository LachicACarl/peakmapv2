# 🚀 Quick Start: Test Payment Flow

## Prerequisites
- Backend server running: `python run_server.py`
- Database with sample stations and fares
- Terminal or API client (curl/Postman)

---

## 🧪 Complete Test Scenario

### Step 1: Setup Test Data

#### Create Stations
```bash
curl -X POST http://127.0.0.1:8000/stations/ \
  -H "Content-Type: application/json" \
  -d '{"name": "Cubao Station", "latitude": 14.6199, "longitude": 121.0540}'

curl -X POST http://127.0.0.1:8000/stations/ \
  -H "Content-Type: application/json" \
  -d '{"name": "Ortigas Station", "latitude": 14.5834, "longitude": 121.0565}'
```

#### Create Fare
```bash
curl -X POST http://127.0.0.1:8000/fares/ \
  -H "Content-Type: application/json" \
  -d '{"from_station_id": 1, "to_station_id": 2, "fare": 45.0}'
```

#### Create Test Users
```bash
# Driver
curl -X POST http://127.0.0.1:8000/users/ \
  -H "Content-Type: application/json" \
  -d '{"username": "driver_juan", "role": "driver"}'

# Passenger
curl -X POST http://127.0.0.1:8000/users/ \
  -H "Content-Type: application/json" \
  -d '{"username": "passenger_maria", "role": "passenger"}'
```

---

### Step 2: Start a Ride Session

#### 2.1 Driver Starts Session
```bash
curl -X POST http://127.0.0.1:8000/rides/sessions/start-driver \
  -H "Content-Type: application/json" \
  -d '{
    "driver_id": 1,
    "from_station_id": 1,
    "session_code": "RIDE1234"
  }'
```

**Response:**
```json
{
  "session_id": 1,
  "session_code": "RIDE1234",
  "qr_code": "QR_RIDE1234_1",
  "status": "waiting_for_passenger"
}
```

#### 2.2 Passenger Joins Session
```bash
curl -X POST http://127.0.0.1:8000/rides/sessions/join-passenger \
  -H "Content-Type: application/json" \
  -d '{
    "passenger_id": 2,
    "session_code": "RIDE1234"
  }'
```

**Response:**
```json
{
  "session_id": 1,
  "message": "Passenger joined. Waiting for driver confirmation."
}
```

#### 2.3 Driver Confirms Passenger
```bash
curl -X POST "http://127.0.0.1:8000/rides/sessions/confirm-passenger?session_id=1&to_station_id=2" \
  -H "Content-Type: application/json"
```

**Response:**
```json
{
  "message": "Passenger confirmed. Ride created.",
  "ride_id": 1,
  "fare_amount": 45.0,  // 🔒 FARE LOCKED HERE
  "session_status": "ride_active"
}
```

---

### Step 3: Simulate GPS Tracking

```bash
curl -X POST http://127.0.0.1:8000/gps/update \
  -H "Content-Type: application/json" \
  -d '{
    "driver_id": 1,
    "latitude": 14.6199,
    "longitude": 121.0540,
    "speed": 15.5
  }'
```

**Repeat every 5 seconds** with different coordinates moving towards Ortigas.

---

### Step 4: Simulate Drop-off (Arrival)

#### Option A: Manual Drop-off Trigger
```bash
curl -X POST http://127.0.0.1:8000/rides/1/dropoff
```

#### Option B: Automatic Detection
Send GPS update within 100m of Ortigas Station:
```bash
curl -X POST http://127.0.0.1:8000/gps/update \
  -H "Content-Type: application/json" \
  -d '{
    "driver_id": 1,
    "latitude": 14.5834,
    "longitude": 121.0565,
    "speed": 2.0
  }'
```

Backend auto-detects arrival and marks ride as "dropped".

---

### Step 5: Check Ride Status

```bash
curl http://127.0.0.1:8000/rides/1
```

**Response:**
```json
{
  "id": 1,
  "driver_id": 1,
  "passenger_id": 2,
  "from_station_id": 1,
  "to_station_id": 2,
  "status": "dropped",
  "fare_amount": 45.0,  // ✅ Fare locked from Step 2.3
  "distance_traveled": 5.2,
  "created_at": "2024-01-15T10:00:00",
  "completed_at": "2024-01-15T10:20:00"
}
```

---

### Step 6: Payment Flow

#### 6.1 Passenger Initiates Payment (Cash)
```bash
curl -X POST http://127.0.0.1:8000/payments/initiate \
  -H "Content-Type: application/json" \
  -d '{
    "ride_id": 1,
    "method": "cash"
  }'
```

**Response:**
```json
{
  "payment_id": 1,
  "ride_id": 1,
  "amount": 45.0,
  "method": "cash",
  "status": "pending",
  "created_at": "2024-01-15T10:21:00"
}
```

#### 6.2 Check Payment Status
```bash
curl http://127.0.0.1:8000/payments/1
```

**Response:**
```json
{
  "id": 1,
  "ride_id": 1,
  "amount": 45.0,
  "method": "cash",
  "status": "pending",  // 💵 Waiting for driver
  "reference": null,
  "created_at": "2024-01-15T10:21:00",
  "confirmed_at": null
}
```

#### 6.3 Driver Confirms Cash Receipt
```bash
curl -X POST http://127.0.0.1:8000/payments/cash/confirm \
  -H "Content-Type: application/json" \
  -d '{
    "payment_id": 1
  }'
```

**Response:**
```json
{
  "message": "Cash payment confirmed",
  "payment": {
    "id": 1,
    "ride_id": 1,
    "amount": 45.0,
    "method": "cash",
    "status": "paid",  // ✅ CONFIRMED
    "confirmed_at": "2024-01-15T10:22:00"
  }
}
```

#### 6.4 Verify Payment Completed
```bash
curl http://127.0.0.1:8000/payments/ride/1
```

**Response:**
```json
{
  "id": 1,
  "status": "paid",  // ✅ SUCCESS
  "amount": 45.0,
  "method": "cash"
}
```

---

## 🎯 Alternative: GCash Payment

### 6A.1 Initiate GCash Payment
```bash
curl -X POST http://127.0.0.1:8000/payments/initiate \
  -H "Content-Type: application/json" \
  -d '{
    "ride_id": 1,
    "method": "gcash"
  }'
```

### 6A.2 Get Checkout URL
```bash
curl -X POST http://127.0.0.1:8000/payments/gcash/initiate \
  -H "Content-Type: application/json" \
  -d '{
    "payment_id": 1
  }'
```

**Response (Mock):**
```json
{
  "checkout_url": "https://mock-gcash-checkout.com/pay/xyz123",
  "reference": "REF_xyz123",
  "message": "In production, redirect user to checkout_url"
}
```

### 6A.3 Simulate Webhook (Auto-confirm)
```bash
curl -X POST http://127.0.0.1:8000/payments/webhook/gcash \
  -H "Content-Type: application/json" \
  -d '{
    "payment_id": 1,
    "status": "paid",
    "reference": "REF_xyz123"
  }'
```

**Response:**
```json
{
  "message": "Payment status updated to paid"
}
```

---

## 📱 Mobile App Testing

### Using Flutter App

#### Passenger Flow:
1. **Launch Passenger App**
2. Enter Driver ID: `1`
3. Select Station: "Ortigas Station" (ID: 2)
4. **Track Bus** → See live map with ETA
5. **Arrives** → "You've Arrived!" dialog shows
6. **"Pay ₱45.00" button appears**
7. Tap → Select **Cash**
8. **Waiting for driver confirmation...**
9. (Driver confirms on their app)
10. ✅ **Payment Confirmed!**

#### Driver Flow:
1. **Launch Driver App**
2. Enter Driver ID: `1`
3. **Start GPS Tracking** → Green play button
4. Green "Cash Payment" floating button visible
5. Tap → Enter Ride ID: `1`
6. **Cash Confirm Screen opens**
7. Shows: Amount ₱45.00, Status: pending
8. Tap **"CONFIRM CASH RECEIVED"**
9. ✅ **Payment Confirmed!** → Returns to map

---

## 🧹 Reset for New Test

```bash
# Delete all rides
curl -X DELETE http://127.0.0.1:8000/rides/1

# Delete all payments
# (If you have DELETE endpoint)

# Or: Stop server, delete peakmap.db, restart server
```

---

## 📊 Verify in Swagger UI

1. Open http://127.0.0.1:8000/docs
2. Expand **payments** section
3. Try interactive API calls
4. See real-time responses

---

## 🎓 Expected Results

After completing all steps:

✅ **Ride created** with locked fare (₱45.00)  
✅ **GPS tracking** showing movement  
✅ **Drop-off detected** automatically or manually  
✅ **Payment initiated** (status: pending)  
✅ **Cash confirmed** by driver (status: paid)  
✅ **Complete ride lifecycle** from start to payment

---

## 🐛 Troubleshooting

### Error: "Ride not found"
- Check ride ID is correct
- Ensure ride was created in Step 2.3

### Error: "Payment already exists for this ride"
- Each ride can only have one payment
- Delete existing payment or use new ride

### Error: "Fare not found"
- Insert fare record (Step 1 - Create Fare)
- Check from_station_id and to_station_id match

### Error: "Invalid payment status transition"
- Can't confirm already-paid payment
- Check current status with GET /payments/{id}

---

## 🎉 Success Criteria

You should see:
- ✅ Ride status: "dropped"
- ✅ Fare amount: 45.0 (locked)
- ✅ Payment status: "paid"
- ✅ confirmed_at timestamp populated
- ✅ Backend logs show no errors

**PAYMENT SYSTEM IS WORKING! 🎊**

---

## 📝 Quick Reference

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/rides/sessions/start-driver` | POST | Driver starts session |
| `/rides/sessions/join-passenger` | POST | Passenger joins |
| `/rides/sessions/confirm-passenger` | POST | 🔒 Locks fare |
| `/gps/update` | POST | Send GPS data |
| `/rides/{id}/dropoff` | POST | Manual drop-off |
| `/payments/initiate` | POST | Create payment |
| `/payments/cash/confirm` | POST | Confirm cash |
| `/payments/{id}` | GET | Check status |

---

**Next:** Try different payment methods (gcash, ewallet) and test webhook flow!
