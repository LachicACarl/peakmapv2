# 🚌 Bus Entry Payment Flow - Complete System

## System Overview

This document describes the complete NFC-based payment flow for bus entry:

```
Admin loads ₱X to NFC card 
    ↓
User receives card with balance
    ↓
User taps card at bus entrance terminal
    ↓
System verifies balance & deducts fare
    ↓
Entry granted/denied
```

---

## Architecture

### Component 1: Admin Balance Loader (Balance Loading)
- **File:** `peak_map_mobile/lib/admin/admin_balance_loader.dart`
- **Purpose:** Admin interface to load money to physical NFC cards
- **Features:**
  - NFC card scanning
  - Manual user ID entry
  - Quick amount buttons (₱100, ₱200, ₱500, ₱1000)
  - Real-time balance updates
  - Transaction history display

### Component 2: Bus Entry Scanner (Card Processing at Entry)
- **File:** `peak_map_mobile/lib/bus/bus_entry_scanner.dart`
- **Purpose:** Terminal interface at bus entrance for scanning and processing user cards
- **Features:**
  - Real-time NFC listening
  - Automatic balance verification
  - Fare calculation and deduction
  - Entry grant/deny decision
  - Transaction logging
  - Manual entry fallback
  - Passenger count tracking

### Component 3: NFC Service (Hardware Abstraction)
- **File:** `peak_map_mobile/lib/services/nfc_service.dart`
- **Purpose:** Handles all NFC read/write operations
- **Methods:**
  - `readCard()` - Extract balance and user ID from card
  - `writeBalanceToCard()` - Write new balance after deduction
  - `startNFCListener()` - Stream-based card detection

### Component 4: Backend Payment API
- **File:** `peak-map-backend/app/routes/payments.py`
- **Endpoints:**
  - `POST /payments/load-balance` - Admin loads balance to card
  - `POST /payments/deduct-fare` - Bus entry deducts fare ⭐ NEW
  - `GET /payments/balance/{user_id}` - Check balance
  - `GET /payments/transactions/{user_id}` - Transaction history

### Component 5: API Service (Frontend HTTP Client)
- **File:** `peak_map_mobile/lib/services/api_service.dart`
- **New Methods:**
  - `deductFare()` - Call backend fare deduction
  - `loadBalance()` - Load balance to card
  - `checkBalance()` - Retrieve balance
  - `getUserTransactions()` - Get transaction history

---

## Complete Workflow

### Step 1: Admin Loads Balance to Card

**User Action:**
1. Admin opens "Admin" screen → "Load Balance"
2. Clicks "Scan Card" button
3. Places admin's NFC reader on user's card
4. System reads card automatically
5. Enters amount or selects quick button (₱100/200/500/1000)
6. Clicks "Load Balance"

**Backend Process:**
```dart
// UI calls this
ApiService.loadBalance(
  userId: "user-uuid",
  amount: 500.0,
  paymentMethod: "admin_nfc",
  cardId: "card-id"
)

// Backend creates transaction
POST /payments/load-balance
{
  "user_id": "user-uuid",
  "amount": 500.0,
  "payment_method": "admin_nfc",
  "card_id": "card-id-12345"
}

// Response
{
  "success": true,
  "message": "Balance of ₱500.00 loaded successfully",
  "transaction_id": 12345,
  "user_id": "user-uuid",
  "amount": 500.0,
  "timestamp": "2026-02-26T10:30:00Z"
}
```

**NFC Card Now Contains:**
```
Card Data: {
  "userId": "user-uuid",
  "balance": 500.0,
  "timestamp": "2026-02-26T10:30:00Z"
}
```

**Result:** User has card with ₱500 balance ✅

---

### Step 2: User Carries Card & Boards Bus

User receives the NFC card with loaded balance and can now use it to board any bus.

---

### Step 3: User Taps Card at Bus Entrance Terminal

**User Action:**
1. Arrives at bus entrance
2. Terminal displays "✅ NFC Ready - Scan card"
3. User taps card on NFC reader
4. System processes automatically

**System Process:**

#### 3A. Read Card Data
```dart
// Bus Entry Scanner detects card tap
await nfcService.startNFCListener()
  .listen((cardData) async {
    // cardData contains:
    // {
    //   "userId": "user-uuid",
    //   "balance": 500.0,
    //   "timestamp": "..."
    // }
  })
```

#### 3B. Verify Balance
```dart
// Call backend to get current balance
final balanceResponse = await apiService.checkBalance("user-uuid");
// Response: { "balance": 500.0 }

const fareAmount = 15.0;
if (balanceResponse['balance'] < fareAmount) {
  // DENIED - insufficient balance
  showError("Insufficient Balance - Available: ₱500, Required: ₱15")
  return
}
```

#### 3C. Deduct Fare from Balance
```dart
// Call backend to deduct fare
final paymentResponse = await apiService.deductFare(
  userId: "user-uuid",
  amount: 15.0,      // ₱15 base fare
  busId: "BUS-001",
  driverId: "DRIVER-001"
);
```

**Backend Deduction Logic:**
```python
POST /payments/deduct-fare
{
  "user_id": "user-uuid",
  "amount": 15.0,
  "bus_id": "BUS-001",
  "driver_id": "DRIVER-001"
}

# Backend execution:
1. Get total loaded balance for user
   current_balance = sum(all admin_nfc payments for user)
   # Result: ₱500.0

2. Check if balance sufficient
   if current_balance (500) < amount (15):
      return error
   # PASS ✅

3. Create fare deduction transaction
   payment = Payment(
     amount=15.0,
     method="bus_fare_nfc",
     status="paid",
     reference="BUSFARE-user-uuid-BUS-001-..."
   )
   db.add(payment)

4. Calculate new balance
   new_balance = 500.0 - 15.0 = 485.0

5. Return success
   {
     "success": true,
     "message": "Fare of ₱15.00 deducted successfully",
     "transaction_id": 54321,
     "user_id": "user-uuid",
     "bus_id": "BUS-001",
     "driver_id": "DRIVER-001",
     "fare_amount": 15.0,
     "previous_balance": 500.0,
     "new_balance": 485.0,
     "status": "entry_granted",
     "timestamp": "2026-02-26T14:45:00Z"
   }
```

#### 3D. Update NFC Card with New Balance
```dart
// Write updated balance back to card
await nfcService.writeBalanceToCard(
  userId: "user-uuid",
  balance: 485.0  // New balance = 500 - 15
);

// Card now contains:
// {
//   "userId": "user-uuid",
//   "balance": 485.0,
//   "timestamp": "2026-02-26T14:45:00Z"
// }
```

#### 3E. Grant Entry
```dart
// Display success screen
setState(() {
  entryGranted = true;
  statusMessage = "✅ Entry Granted\n💳 Fare: ₱15.00\n💰 New Balance: ₱485.00"
  statusColor = Colors.green
})

// UI shows:
// ✅ Entry Granted
// 💳 Fare: ₱15.00
// 💰 New Balance: ₱485.00
// 📱 User ID: user-uuid
// TXN: 54321
```

**Result:** Entry GRANTED ✅ User boards bus

---

### Step 4: Repeat for Each Trip

Each time user boards:
- Card balance decreases by fare amount (usually ₱15)
- Transaction recorded in backend
- Updated balance written to card

**Example - Second Trip:**
```
Card Balance Before: ₱485.00
Fare: ₱15.00
Card Balance After: ₱470.00
Entry: GRANTED ✅

Card now contains: { "balance": 470.0 }
```

---

## UI Screens

### 1. Home Screen (Role Selection)
```
┌─────────────────────────────┐
│         PEAK MAP            │
│  Live GPS Tracking for EDSA │
│         Buses               │
│                             │
│  [🚗 I'm a Driver]         │
│  [👤 I'm a Passenger]      │
│  [🚪 Bus Entry Terminal]   │ ⭐ NEW
│                             │
│ Choose your role...         │
└─────────────────────────────┘
```

### 2. Bus Entry Scanner Screen
```
┌─────────────────────────────┐
│    Bus Entry Scanner        │
├─────────────────────────────┤
│                             │
│  ┌─────────────────────┐   │
│  │        🚪          │   │
│  │  ✅ NFC Ready      │   │
│  │ Scan card          │   │
│  └─────────────────────┘   │
│                             │
│ ┌──────────────────────────┐│
│ │Bus: BUS-001             ││
│ │Driver: DRIVER-001       ││
│ │Fare: ₱15.00             ││
│ │Passengers: 42           ││
│ └──────────────────────────┘│
│                             │
│ [🔄 Retry] [✏️ Manual]    │
│                             │
└─────────────────────────────┘
```

### 3. Bus Entry Scanner - Entry Granted
```
┌─────────────────────────────┐
│    Bus Entry Scanner        │
├─────────────────────────────┤
│                             │
│  ┌─────────────────────┐   │
│  │        ✅          │   │
│  │  Entry Granted     │   │
│  │  Fare: ₱15.00      │   │
│  │ New Balance: ₱485  │   │
│  └─────────────────────┘   │
│                             │
│ ┌──────────────────────────┐│
│ │📱 User ID: bb6e65b6...  ││
│ │💾 Card Balance: ₱500    ││
│ │💰 New Balance: ₱485     ││
│ │TXN: 54321               ││
│ └──────────────────────────┘│
│                             │
│ ✅ Transaction Successful   │
│ Amount: ₱15.00              │
│                             │
└─────────────────────────────┘
```

### 4. Bus Entry Scanner - Entry Denied
```
┌─────────────────────────────┐
│    Bus Entry Scanner        │
├─────────────────────────────┤
│                             │
│  ┌─────────────────────┐   │
│  │        ❌          │   │
│  │ Insufficient       │   │
│  │ Balance            │   │
│  │ Needed: ₱15        │   │
│  │ Available: ₱5      │   │
│  └─────────────────────┘   │
│                             │
│ Load more balance with      │
│ admin to proceed.           │
│                             │
│ [🔄 Retry] [✏️ Manual]    │
│                             │
└─────────────────────────────┘
```

---

## Database Schema

### Payments Table
```sql
CREATE TABLE payments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  ride_id INTEGER,
  user_id TEXT,
  amount FLOAT,
  method TEXT,          -- 'admin_nfc' or 'bus_fare_nfc'
  status TEXT,          -- 'paid'
  reference TEXT,       -- 'NFC-user-uuid-timestamp' or 'BUSFARE-user-uuid-bus-001-timestamp'
  created_at TIMESTAMP,
  paid_at TIMESTAMP
);

# Example Records:

# Admin Loading Balance
INSERT INTO payments (amount, method, status, reference, created_at, paid_at)
VALUES (500.0, 'admin_nfc', 'paid', 'NFC-bb6e65b6...-1708949400', '2026-02-26 10:30:00', '2026-02-26 10:30:00');

# First Bus Entry
INSERT INTO payments (amount, method, status, reference, created_at, paid_at)
VALUES (15.0, 'bus_fare_nfc', 'paid', 'BUSFARE-bb6e65b6...-BUS-001-1708963500', '2026-02-26 14:45:00', '2026-02-26 14:45:00');

# Second Bus Entry
INSERT INTO payments (amount, method, status, reference, created_at, paid_at)
VALUES (15.0, 'bus_fare_nfc', 'paid', 'BUSFARE-bb6e65b6...-BUS-001-1708966100', '2026-02-26 15:35:00', '2026-02-26 15:35:00');

# Balance Check
SELECT SUM(amount) FROM payments WHERE method='admin_nfc' AND status='paid';
-- Result: 500.0

# After 2 trips, current balance
SELECT SUM(amount) FROM payments WHERE method IN ('admin_nfc', 'bus_fare_nfc') AND status='paid';
-- Result: 485.0 (500 - 15 - 15)
```

---

## API Endpoints

### 1. Load Balance (Admin)
```
POST /payments/load-balance
Content-Type: application/json

Request Body:
{
  "user_id": "bb6e65b6-1cc5-4b63-8b99-0c80f86e0b9b",
  "amount": 500.0,
  "payment_method": "admin_nfc",
  "card_id": "card-12345"
}

Response (200 OK):
{
  "success": true,
  "message": "Balance of ₱500.00 loaded successfully",
  "transaction_id": 42,
  "user_id": "bb6e65b6-1cc5-4b63-8b99-0c80f86e0b9b",
  "amount": 500.0,
  "card_id": "card-12345",
  "timestamp": "2026-02-26T10:30:00"
}
```

### 2. Deduct Fare (Bus Entry) ⭐ NEW
```
POST /payments/deduct-fare
Content-Type: application/json

Request Body:
{
  "user_id": "bb6e65b6-1cc5-4b63-8b99-0c80f86e0b9b",
  "amount": 15.0,
  "bus_id": "BUS-001",
  "driver_id": "DRIVER-001"
}

Response (200 OK):
{
  "success": true,
  "message": "Fare of ₱15.00 deducted successfully",
  "transaction_id": 54321,
  "user_id": "bb6e65b6-1cc5-4b63-8b99-0c80f86e0b9b",
  "bus_id": "BUS-001",
  "driver_id": "DRIVER-001",
  "fare_amount": 15.0,
  "previous_balance": 500.0,
  "new_balance": 485.0,
  "status": "entry_granted",
  "timestamp": "2026-02-26T14:45:00"
}

Response (Insufficient Balance):
{
  "success": false,
  "error": "Insufficient balance. Available: ₱5.00, Required: ₱15.00",
  "balance": 5.0,
  "required": 15.0
}
```

### 3. Check Balance
```
GET /payments/balance/bb6e65b6-1cc5-4b63-8b99-0c80f86e0b9b

Response (200 OK):
{
  "success": true,
  "user_id": "bb6e65b6-1cc5-4b63-8b99-0c80f86e0b9b",
  "balance": 485.0
}
```

### 4. Get Transactions
```
GET /payments/transactions/bb6e65b6-1cc5-4b63-8b99-0c80f86e0b9b

Response (200 OK):
{
  "success": true,
  "user_id": "bb6e65b6-1cc5-4b63-8b99-0c80f86e0b9b",
  "transaction_count": 3,
  "transactions": [
    {
      "id": 54321,
      "amount": 15.0,
      "method": "bus_fare_nfc",
      "status": "paid",
      "created_at": "2026-02-26 14:45:00",
      "paid_at": "2026-02-26 14:45:00"
    },
    {
      "id": 42,
      "amount": 500.0,
      "method": "admin_nfc",
      "status": "paid",
      "created_at": "2026-02-26 10:30:00",
      "paid_at": "2026-02-26 10:30:00"
    }
  ]
}
```

---

## Testing the Complete Flow

### Test Scenario 1: Happy Path (Sufficient Balance)

**Step 1: Admin Loads Balance**
```bash
curl -X POST http://localhost:8000/payments/load-balance \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test-user-123",
    "amount": 500.0,
    "payment_method": "admin_nfc",
    "card_id": "test-card-001"
  }'

# Response: ✅ Successfully loaded ₱500
```

**Step 2: User Taps Card at Exit → Entry Granted**
```bash
curl -X POST http://localhost:8000/payments/deduct-fare \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test-user-123",
    "amount": 15.0,
    "bus_id": "BUS-001",
    "driver_id": "DRIVER-001"
  }'

# Response: ✅ Entry Granted, new_balance: 485.0
```

**Step 3: Verify Updated Balance**
```bash
curl http://localhost:8000/payments/balance/test-user-123

# Response: balance: 485.0 ✅
```

### Test Scenario 2: Insufficient Balance

**Step 1: Load Small Amount**
```bash
curl -X POST http://localhost:8000/payments/load-balance \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "poor-user-456",
    "amount": 10.0,
    "payment_method": "admin_nfc"
  }'

# Response: ✅ Loaded ₱10
```

**Step 2: User Taps Card → Entry Denied**
```bash
curl -X POST http://localhost:8000/payments/deduct-fare \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "poor-user-456",
    "amount": 15.0,
    "bus_id": "BUS-001",
    "driver_id": "DRIVER-001"
  }'

# Response: ❌ Insufficient balance. Available: ₱10.00, Required: ₱15.00
```

---

## Files Modified/Created

### New Files Created
1. **`peak_map_mobile/lib/bus/bus_entry_scanner.dart`** (500 lines)
   - Complete bus entry terminal interface
   - NFC scanning and fare processing
   - Manual entry fallback dialog

### Modified Files
1. **`peak_map_mobile/lib/main.dart`**
   - Added imports for Provider, ApiService, BusEntryScanner
   - Wrapped app with Provider<ApiService>
   - Added "Bus Entry Terminal" button to home screen

2. **`peak_map_mobile/lib/services/api_service.dart`**
   - Added `deductFare()` method for fare deduction

3. **`peak-map-backend/app/routes/payments.py`**
   - Added `FareDeductPayload` model
   - Added `POST /payments/deduct-fare` endpoint (75 lines)
   - Includes balance verification and transaction recording

---

## Security Considerations

1. **NFC Data Validation**
   - Always verify user ID format (UUID)
   - Validate balance format (positive float)
   
2. **Transaction Verification**
   - Record all transactions in backend database
   - Never trust card data alone
   - Always verify balance on backend before deducting

3. **Card Tampering**
   - Verify card data against backend database
   - Use transaction IDs to prevent double-dipping
   - Implement timeout for card validity

4. **Access Control**
   - Bus Entry Terminal should be accessible only to authorized terminals/drivers
   - Admin balance loading requires admin authentication
   - Consider adding API key validation

---

## Future Enhancements

1. **Real-time Balance Sync**
   - Update card balance via NDEF records
   - Instead of storing balance on card, store transaction ID
   - Retrieve balance from backend on each scan

2. **Multi-Route Support**
   - Different fares for different routes
   - Loyalty rewards/discounts
   - Student rates, senior rates

3. **Transaction History**
   - User app showing all boarding history
   - Driver app showing daily fare collection
   - Admin dashboard with full analytics

4. **Card Management**
   - Card blocking/deactivation
   - Card replacement workflow
   - Automatic card balance expiry

5. **Payment Methods**
   - Load balance via QR code payment gateway
   - GCash/PayMaya integration
   - Bank transfer support

---

## Troubleshooting

### Issue: NFC Not Detected
**Solution:** 
- Ensure NFC device supports ISO-DEP protocol
- Device must have NFC hardware enabled
- Check NFC manager dependency in pubspec.yaml

### Issue: Fare Not Deducted
**Solution:**
- Verify backend is running on port 8000
- Check network connectivity
- Verify user balance >= fare amount

### Issue: Card Not Updated After Fare
**Solution:**
- Ensure NFC write permissions enabled
- Card must be NFC Type 4 compatible
- Keep card in range while writing

### Issue: Insufficient Balance Dialog Doesn't Appear
**Solution:**
- Check backend balance check endpoint
- Verify payment transactions recorded
- Check error response format from backend

---

## Deployment Checklist

- [ ] Backend `/payments/deduct-fare` endpoint deployed
- [ ] NFC permission added to AndroidManifest.xml
- [ ] Bus Entry Scanner screen added to navigation
- [ ] API Service updated with `deductFare()` method
- [ ] Test with real NFC cards
- [ ] Verify balance calculations
- [ ] Set correct base fare amount (currently ₱15.00)
- [ ] Configure bus ID and driver ID for each terminal
- [ ] Add bus entry scanner to driver dashboard
- [ ] Set up transaction monitoring
- [ ] Create admin reporting dashboard

---

## Summary

✅ Complete end-to-end NFC-based bus entry payment system
- Admin interface to load balance
- Bus entry terminal to process payments
- Automatic balance verification
- Real-time entry grant/deny
- Full transaction history
- Database persistence

**The flow is now complete:** Admin loads balance → User taps card → System validates & charges → Entry granted ✅
