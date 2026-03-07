# 📡 RFID Reader Integration Guide

## ✅ What Was Added

Your admin dashboard now has a comprehensive **RFID Reader Management System** with:

### 1. **Real-Time Tap Monitoring** 📊
- Live display of all RFID card tap events
- Shows tap-in, tap-out, balance load, and card block events
- Automatic scrolling with last 20 events tracked
- Color-coded event types for quick identification

### 2. **Balance Management** 💰
- Load balance to cards via admin panel
- Check current card balance
- Track balance load transactions
- Support for multiple payment methods

### 3. **Card Management** 🔒
- Block cards (for lost/stolen cards)
- Request card replacement
- Add reason for card actions
- View card status

### 4. **Real-Time WebSocket Integration** 🔌
- Live RFID tap events via WebSocket
- Real-time event monitoring
- Automatic dashboard updates

---

## 🚀 Hardware Setup (RFID Reader)

Your RFID reader device should be configured to send tap events to the backend.
- **API Endpoints Used:**
  - `POST /payments/tap-in` - Passenger taps in
  - `POST /payments/tap-out` - Passenger taps out

### Prerequisites
1. **Backend Running:** `http://127.0.0.1:8000`
2. **Admin Dashboard:** Open `admin_dashboard.html` in Live Server (`http://127.0.0.1:5500`)
3. **RFID Device Configured:**
   ```
   WiFi SSID: "Goblok Anjing"
   WiFi Password: "192.168.0.254"
   API Base: http://192.168.5.31:8000
   ```

---

## 📖 How to Use

### Access RFID Manager

1. Open Admin Dashboard: `http://127.0.0.1:5500/admin_dashboard.html`
2. Click **"📡 RFID Reader"** button in Quick Actions
3. A modal window will open with 4 tabs

### Tab 1: Monitor Taps 📊

**Real-time event monitoring**

- Shows all RFID card interactions
- Events include:
  - ✅ **Tap-In** (green) - Passenger boards bus
  - 🚪 **Tap-Out** (orange) - Passenger exits bus
  - 💰 **Balance Load** (purple) - Admin loaded balance
  - 🚫 **Card Block** (red) - Card was blocked

**Live Streaming:**
- WebSocket automatically updates events
- Displays timestamp for each event
- Keeps last 20 events in memory

### Tab 2: Load Balance 💰

**Add credit to passenger cards**

1. Enter User ID (UUID format):
   ```
   Example: bb6e65b6-1cc5-4b63-8b99-0c80f86e0b9b
   ```
2. Enter Amount in Philippine Peso (₱)
3. Click **"✅ Load Balance"**
4. Confirmation shows:
   - Amount loaded
   - Transaction ID
   - Timestamp

**Backend Endpoint:**
```
POST /payments/load-balance
{
  "user_id": "uuid",
  "amount": 100.00,
  "payment_method": "admin_nfc",
  "card_id": null
}
```

### Tab 3: Check Balance 🔍

**View current card balance**

1. Enter User ID (UUID)
2. Click **"🔍 Check Balance"**
3. Display shows:
   - Current balance in ₱
   - User ID (truncated)
   - Status (Active/Inactive)

**Backend Endpoint:**
```
GET /payments/balance/{user_id}
```

### Tab 4: Card Management 🔒

**Block or replace cards**

1. Enter User ID (UUID)
2. Enter Reason for action
3. Click either:
   - **"🚫 Block Card"** - For lost/stolen/damaged cards
   - **"🔄 Request Replacement"** - Request new card

**Backend Endpoints:**
```
POST /payments/card/{user_id}/block
POST /payments/card/{user_id}/replace
```

---

## 🔗 Backend API Integration

All RFID operations use these backend endpoints:

### Tap Events
```
POST /payments/tap-in
POST /payments/tap-out
```

### Balance Operations
```
POST /payments/load-balance      # Load credit
GET /payments/balance/{user_id}  # Check balance
POST /payments/balance/check     # Check via NFC
```

### Card Management
```
POST /payments/card/{user_id}/block     # Block card
POST /payments/card/{user_id}/replace   # Request replacement
```

### Real-Time
```
WebSocket: ws://127.0.0.1:8000/ws/admin
- Receives: gps_update, rfid_tap events
```

---

## 🧪 Testing the RFID System

### Test 1: Monitor Real Taps
1. Open RFID Manager
2. Go to "Monitor Taps" tab
3. Tap a card on your RFID reader
4. Event should appear in real-time

### Test 2: Load Balance
```bash
# From PowerShell in backend directory
$body = @{
  user_id = "bb6e65b6-1cc5-4b63-8b99-0c80f86e0b9b"
  amount = 500.00
  payment_method = "admin_nfc"
  card_id = $null
} | ConvertTo-Json

Invoke-RestMethod -Uri 'http://127.0.0.1:8000/payments/load-balance' `
  -Method Post -ContentType 'application/json' -Body $body
```

### Test 3: Check Balance
```bash
$userId = "bb6e65b6-1cc5-4b63-8b99-0c80f86e0b9b"
Invoke-RestMethod -Uri "http://127.0.0.1:8000/payments/balance/$userId" `
  -Method Get
```

### Test 4: Block Card
```bash
$body = @{
  status = "blocked"
  reason = "Lost card"
} | ConvertTo-Json

Invoke-RestMethod -Uri 'http://127.0.0.1:8000/payments/card/bb6e65b6-1cc5-4b63-8b99-0c80f86e0b9b/block' `
  -Method Post -ContentType 'application/json' -Body $body
```

---

## 🎨 UI Features

### Real-Time Event Colors
- 🟢 **Green** = Tap-In (boarding)
- 🟠 **Orange** = Tap-Out (exiting)
- 🟣 **Purple** = Balance Operations
- 🔴 **Red** = Card Blocks/Issues

### Modal Tabs
- Click tab header to switch sections
- Active tab is highlighted in blue
- Forms clear after successful submission
- Results shown with color feedback:
  - Green (✅) = Success
  - Orange (⚠️) = Warning/Pending
  - Red (❌) = Error

---

## 📱 Integration with Other Components

### WebSocket Connection
The RFID manager connects to the same WebSocket as the main dashboard:
- **URL:** `ws://127.0.0.1:8000/ws/admin`
- **Events:** GPS updates + RFID tap events
- **Auto-reconnect:** Every 3 seconds if disconnected

### Admin Dashboard Stats
- Real-time tap events update activity feed
- Balance loads appear in payment breakdown
- Card blocks tracked in transaction history

### Backend Dependencies
- **Database:** SQLite `peakmap.db`
- **Tables:** `payments`, `users`, `rides`
- **ORM:** SQLAlchemy

---

## 🐛 Troubleshooting

### Events Not Appearing
1. Check WebSocket connection (blue indicator in header)
2. Verify backend is running: `http://127.0.0.1:8000`
3. Check browser console for errors (F12)

### Balance Load Fails
1. Verify user ID is correct (should be UUID format)
2. Check backend logs for errors
3. Ensure amount is valid positive number

### Cards Not Blocking
1. Verify user exists in database
2. Check if card already blocked
3. Review backend error message

---

## 📊 Event Flow Diagram

```
┌─────────────────────────────────────────────────────────┐
│                   Admin Dashboard                       │
│  ┌──────────────────────────────────────────────────┐  │
│  │     RFID Reader Management Panel                 │  │
│  │  ┌────────┬────────┬────────┬────────┐          │  │
│  │  │Monitor │Balance │ Check  │  Mgmt  │          │  │
│  │  └────────┴────────┴────────┴────────┘          │  │
│  └──────────────────────────────────────────────────┘  │
│                      │                                  │
│                      ▼                                  │
│            WebSocket Connection                        │
│          ws://127.0.0.1:8000/ws/admin                  │
│                      │                                  │
└──────────────────────┼──────────────────────────────────┘
                       │
        ┌──────────────┼──────────────┐
        │              │              │
        ▼              ▼              ▼
    Backend API    WebSocket      Database
    (FastAPI)      (Events)      (SQLite)
    
├─ /payments/tap-in
├─ /payments/tap-out
├─ /payments/load-balance
├─ /payments/balance/{id}
├─ /payments/card/{id}/block
└─ /payments/card/{id}/replace
```

---

## 📝 Notes

- **Offline Mode:** Dashboard works without Google Maps API key
- **Fallback:** If WebSocket disconnects, periodic data refresh continues
- **SQLite Compatibility:** All PaymentOperations use `ride_id=0` for marker transactions
- **Real-Time:** Events appear instantly via WebSocket (no polling needed)

---

## ✨ Next Steps

1. ✅ Test RFID tap events from your RFID device
2. ✅ Load balance to test cards
3. ✅ Monitor real-time events
4. ✅ Block/replace damaged cards
5. Configure Google Maps API key (optional for full map display)
6. Set up Supabase service role key for production write access

---

**Created:** March 7, 2026  
**System:** PEAK MAP v2  
**Status:** ✅ Ready for Testing
