# 🎫 Card Recognition System - Updated

## ✅ What Changed

### 1. **Removed "Simulate Tap" Buttons**
- ❌ Removed testing buttons from admin dashboard
- Clean interface for production use only

### 2. **Enhanced Card Matching**
The system now **recognizes passengers by their card UID** when they exit the bus.

## 🔐 How Card Recognition Works

### Tap-In Flow
```
1. Passenger taps card 1603310630 at Station 1
2. System stores:
   ✓ Card UID: 1603310630
   ✓ User ID: 5
   ✓ Boarding Station: 1
   ✓ Status: Pending (waiting for tap-out)
```

### Tap-Out Flow - SAME CARD ✅
```
1. Passenger taps SAME card (1603310630) at Station 2
2. System checks:
   ✓ Is there a pending tap-in? YES
   ✓ Does card UID match? YES (1603310630 = 1603310630)
   ✓ Is balance sufficient? YES
3. Result: Exit allowed, fare deducted ✅
```

### Tap-Out Flow - DIFFERENT CARD ❌
```
1. Passenger tries different card (ABCD1234) at Station 2
2. System checks:
   ✓ Is there a pending tap-in? YES
   ✓ Does card UID match? NO (1603310630 ≠ ABCD1234)
3. Result: Exit DENIED ❌
   Error: "Card mismatch! You tapped in with card 1603310630 
          but tapping out with ABCD1234"
```

## 📊 Test Results

### Test 1: Normal Journey (PASS ✅)
```
Tap-In:  Card 1603310630 at Station 1
Tap-Out: Card 1603310630 at Station 2
Result:  ✅ Exit allowed
         Fare: ₱35.00 deducted
         New Balance: ₱465.00
         Card Matched: True
```

### Test 2: Card Mismatch (PASS ✅)
```
Tap-In:  Card 1603310630 at Station 1
Tap-Out: Card ABCD1234 at Station 2
Result:  ❌ Exit denied
         Error: Card mismatch detected
         Expected: 1603310630
         Provided: ABCD1234
```

## 🔧 Technical Details

### Updated Reference Format
**OLD Format:**
```
TAPIN-{user_id}-{bus_id}-{station_id}-{timestamp}
```

**NEW Format (with card UID):**
```
TAPIN-{card_uid}-{user_id}-{bus_id}-{station_id}-{timestamp}
Example: TAPIN-1603310630-5-1-1-1709865432.123
```

### Backend Changes
**File:** `peak-map-backend/app/routes/payments.py`

**Changes:**
1. `tap_in_passenger()` - Stores card_uid in reference
2. `tap_out_passenger()` - Validates card_uid matches tap-in
3. Returns `card_matched: true/false` in response

### API Response (Tap-Out)
```json
{
  "success": true,
  "message": "Tap-out successful. Fare deducted.",
  "status": "exit_granted",
  "user_id": "5",
  "card_uid": "1603310630",
  "card_matched": true,
  "from_station_id": 1,
  "to_station_id": 2,
  "fare_amount": 35.0,
  "previous_balance": 500.0,
  "new_balance": 465.0
}
```

### Error Response (Card Mismatch)
```json
{
  "success": false,
  "error": "Card mismatch! You tapped in with card 1603310630 but tapping out with ABCD1234",
  "status": "card_mismatch",
  "expected_card": "1603310630",
  "provided_card": "ABCD1234"
}
```

## 🚀 Usage Examples

### PowerShell Testing

#### Tap In
```powershell
$tapIn = @{
    user_id = "5"
    bus_id = "1"
    driver_id = "1"
    station_id = 1
    card_uid = "1603310630"
} | ConvertTo-Json

Invoke-RestMethod -Uri 'http://127.0.0.1:8000/payments/tap-in' `
    -Method Post -ContentType 'application/json' -Body $tapIn
```

#### Tap Out
```powershell
$tapOut = @{
    user_id = "5"
    bus_id = "1"
    driver_id = "1"
    station_id = 2
    card_uid = "1603310630"
} | ConvertTo-Json

Invoke-RestMethod -Uri 'http://127.0.0.1:8000/payments/tap-out' `
    -Method Post -ContentType 'application/json' -Body $tapOut
```

## 🎯 Benefits

### For Passengers
- ✅ Must use same card to enter and exit
- ✅ Prevents fare evasion
- ✅ Accurate journey tracking

### For System
- ✅ Card authentication on both entry and exit
- ✅ Fraud prevention
- ✅ Audit trail with card UID

### For Operators
- ✅ Clear error messages
- ✅ Tracks which card was used
- ✅ Better security

## 📱 Integration with ESP32

```cpp
// ESP32 RFID Reader Code
String cardUID = readRFIDCard();
String userID = getUserIDFromCard(cardUID);

// Tap In
HTTPClient http;
http.begin("http://192.168.5.31:8000/payments/tap-in");
http.addHeader("Content-Type", "application/json");

String tapInPayload = "{\"user_id\":\"" + userID + 
                      "\",\"bus_id\":\"1\",\"driver_id\":\"1\"," +
                      "\"station_id\":1,\"card_uid\":\"" + cardUID + "\"}";

int httpCode = http.POST(tapInPayload);
if (httpCode == 200) {
    String response = http.getString();
    DynamicJsonDocument doc(1024);
    deserializeJson(doc, response);
    
    bool success = doc["success"];
    if (success) {
        lcd.print("Welcome!");
        playSuccessSound();
    }
}
```

## 🔍 Admin Dashboard

The admin dashboard now shows:
- ✅ Real card tap events (no simulation)
- ✅ Entry/Exit tracking with card UIDs
- ✅ Cleaner interface without test buttons

## 💡 Notes

- Card UID is case-insensitive (automatically converted to uppercase)
- System remembers card from tap-in to tap-out
- Each passenger must use same physical card for entire journey
- Prevents card sharing or fraud attempts

## 🛠️ System Status

✅ **Backend:** Running with card recognition
✅ **Card Match:** Working perfectly
✅ **Fraud Prevention:** Active
✅ **Admin Dashboard:** Cleaned up
✅ **API Endpoints:** Updated

---

**Last Updated:** March 8, 2026
**Feature Status:** ✅ Production Ready
