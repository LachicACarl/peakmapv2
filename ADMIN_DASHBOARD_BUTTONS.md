# ADMIN DASHBOARD - Quick Button Reference

## 🎯 All Buttons & Their Functions

### 📱 NFC Balance Loader
**What it does:** Loads money onto a passenger's NFC card for bus fare payments

**How to use:**
1. Click button → Modal opens
2. Enter User ID (UUID from Supabase)
3. Enter amount or click preset (₱100/₱200/₱500/₱1000)
4. Click "💾 Load Balance"
5. Success! Money added to user's account

**Backend:** `POST /payments/load-balance`

**Use case:** Passenger visits admin office to load cash onto their card

---

### ↩️ Refund Transaction
**What it does:** Reverses a transaction and returns money to user's balance

**How to use:**
1. Click button → Modal opens
2. Enter Transaction ID (from payment logs)
3. Enter reason for refund
4. Click "💰 Process Refund"
5. Money returned to user, balance updated

**Backend:** `POST /payments/refund/{transaction_id}`

**Use case:** System error, duplicate charge, fare dispute

---

### 🔒 Card Management
**What it does:** Block lost/stolen cards or request replacements

**How to use:**

**Option A - Block Card:**
1. Enter User ID
2. Enter reason (optional)
3. Click "🚫 Block Card"
4. Card immediately blocked

**Option B - Request Replacement:**
1. Enter User ID
2. Enter reason
3. Click "🔄 Request Replacement"
4. Replacement request created

**Option C - Check Status:**
1. Enter User ID
2. Click "🔍 Check Status"
3. View card status (active/blocked/pending_replacement)

**Backend:** 
- `POST /payments/card/{user_id}/block`
- `POST /payments/card/{user_id}/replace`
- `GET /payments/card/{user_id}/status`

**Use case:** User reports lost card, damaged card, or suspected fraud

---

### ➕ Add Driver
**What it does:** Registers a new driver in the system

**How to use:**
1. Click "➕ Add Driver" in Active Drivers section
2. Fill in required info:
   - Full Name
   - Email (must be unique)
   - Phone Number
   - License Number
   - Vehicle Plate
   - Vehicle Model
   - Initial Password (min 6 chars)
3. Click "Add Driver"
4. Driver account created, can now log in

**Backend:** `POST /auth/register`

**Use case:** Onboarding new drivers to the system

---

### ⚙️ Settings
**Status:** Coming Soon
**Planned:** System configuration, user management, reports

---

## 🔄 Complete Admin Workflows

### Workflow 1: Daily Balance Loading Operation
```
1. Passenger arrives with cash
2. Admin opens "NFC Balance Loader"
3. Admin asks for passenger's User ID (from app)
4. Admin enters User ID and amount
5. Admin clicks "Load Balance"
6. System confirms load
7. Passenger can now use NFC card on bus
8. Admin marks cash as received
```

### Workflow 2: Lost Card Scenario
```
1. Passenger reports lost card via phone/email
2. Admin opens "Card Management"
3. Admin enters passenger's User ID
4. Admin clicks "Check Status" to verify current status
5. Admin clicks "Block Card" to prevent unauthorized use
6. Admin clicks "Request Replacement"
7. Admin processes replacement offline (new physical card)
8. Passenger's balance is preserved on new card
```

### Workflow 3: Fare Dispute Resolution
```
1. Passenger complains about double charge
2. Admin checks payment history
3. Admin confirms duplicate transaction
4. Admin opens "Refund Transaction"
5. Admin enters Transaction ID
6. Admin enters reason: "Duplicate charge"
7. Admin clicks "Process Refund"
8. Money returned to passenger's balance
9. Admin notifies passenger of resolution
```

### Workflow 4: Driver Onboarding
```
1. New driver completes application
2. Admin verifies documents
3. Admin clicks "Add Driver" button
4. Admin fills in all driver details
5. Admin creates initial password (give to driver)
6. Admin clicks "Add Driver"
7. System creates driver account
8. Driver can now log in to driver app
9. Driver appears in Active Drivers list
```

---

## 📞 Button Troubleshooting

### "Load Balance" does nothing
- Check backend is running
- Verify User ID is valid UUID format
- Check amount is > 0
- Open console (F12) for errors

### "Refund" fails
- Verify Transaction ID exists
- Check transaction wasn't already refunded
- Ensure transaction status is "paid"

### "Block Card" not working
- Verify User ID format
- Check backend connection
- View network tab for API response

### "Add Driver" fails
- Email might already be registered
- Check all required fields filled
- Password must be 6+ characters
- Verify backend /auth/register endpoint

---

## 🎨 Visual Indicators

### Colors
- **Blue buttons**: Info/view actions
- **Green buttons**: Positive actions (load, confirm)
- **Orange buttons**: Warning actions (refund, refresh)
- **Red buttons**: Destructive actions (block, delete)
- **Gray buttons**: Cancel/close

### Status Indicators
- **Green dot**: Connected, live updates active
- **Red dot**: Disconnected, reconnecting...

### Badges
- **Blue badge**: Ride-related
- **Green badge**: Payment success
- **Orange badge**: Ongoing/pending
- **Red badge**: Failed/cancelled

---

## ⚡ Keyboard Shortcuts (Future Enhancement)

Planned shortcuts:
- `Ctrl+B` - Open NFC Balance Loader
- `Ctrl+R` - Open Refund Transaction
- `Ctrl+K` - Open Card Management
- `Ctrl+D` - Open Add Driver
- `Esc` - Close modal

---

## 💡 Best Practices

### For Load Balance:
- ✅ Always verify User ID before loading
- ✅ Count cash twice before confirming
- ✅ Keep transaction logs
- ❌ Don't load negative amounts
- ❌ Don't load without receiving payment

### For Refunds:
- ✅ Always document reason
- ✅ Verify transaction details first
- ✅ Keep audit trail
- ❌ Don't refund without approval
- ❌ Don't refund same transaction twice

### For Card Management:
- ✅ Verify user identity before blocking
- ✅ Document all card actions
- ✅ Check status before taking action
- ❌ Don't block cards without reason
- ❌ Don't unblock without verification

### For Driver Registration:
- ✅ Verify all documents first
- ✅ Use secure initial password
- ✅ Give password to driver securely
- ❌ Don't use weak passwords
- ❌ Don't share credentials via insecure channels

---

## 📋 Testing Checklist

Before going live, test each button:

- [ ] **NFC Balance Loader**
  - [ ] Load ₱100 successfully
  - [ ] View transaction in Recent Loads
  - [ ] Verify balance increased
  - [ ] Test with invalid User ID
  - [ ] Test with negative amount

- [ ] **Refund Transaction**
  - [ ] Refund a valid transaction
  - [ ] Check balance updated correctly
  - [ ] Try refunding twice (should fail)
  - [ ] Test with invalid Transaction ID

- [ ] **Card Management**
  - [ ] Block a card
  - [ ] Check status shows "blocked"
  - [ ] Request replacement
  - [ ] Verify request created
  - [ ] Test with invalid User ID

- [ ] **Add Driver**
  - [ ] Add driver with all fields
  - [ ] Verify driver appears in list
  - [ ] Try duplicate email (should fail)
  - [ ] Test with missing fields

---

## 🔗 Related Documentation

- **Full Flow Guide**: `ADMIN_DASHBOARD_FLOW.md`
- **API Documentation**: `http://127.0.0.1:8000/docs`
- **Payment System**: `PAYMENT_SYSTEM_GUIDE.md`
- **NFC Guide**: `NFC_BALANCE_LOADING_GUIDE.md`

---

**Last Updated**: February 27, 2026
**Version**: 1.0
