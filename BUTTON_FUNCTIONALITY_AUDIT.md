# 🎮 BUTTON FUNCTIONALITY AUDIT & TESTING PLAN

## Overview
Complete audit of all buttons in the PeakMap mobile app for both Driver and Passenger flows.

---

## 📋 UI/UX Button Inventory

### 1. **HOME SCREEN (Initial Screen)**

| Button | Type | Action | Target | Status |
|--------|------|--------|--------|--------|
| **I'm a Driver** | ElevatedButton | Navigate | LoginScreen(driver) | ✅ Implemented |
| **I'm a Passenger** | ElevatedButton | Navigate | LoginScreen(passenger) | ✅ Implemented |

---

## 👨‍💼 DRIVER FLOW

### 1. **LOGIN SCREEN**

| Button | Type | Action | Target | Status |
|--------|------|--------|--------|--------|
| **Login** | ElevatedButton | POST /auth/login | DriverHome | ✅ Implemented |
| **Sign Up** | TextButton | Navigate | DriverRegisterScreen | ⚠️ Needs Implementation |
| **Forgot Password** | TextButton | Navigate | ForgotPasswordScreen | ⚠️ Needs Implementation |
| **Show/Hide Password** | IconButton | Toggle visibility | Local state | ✅ Implemented |

### 2. **DRIVER HOME (Navigation Hub)**

| Button | Type | Screen | Status |
|--------|------|--------|--------|
| Dashboard | BottomNavItem | DriverDashboard | ✅ Active |
| Routes | BottomNavItem | DriverRoutes | ✅ Active |
| About | BottomNavItem | DriverAbout | ✅ Active |

### 3. **DRIVER DASHBOARD**

| Button | Type | Action | Target | Status |
|--------|------|--------|--------|--------|
| **Accept Passengers (Toggle)** | Switch | Update online status | Backend | ⚠️ Needs API Connection |
| **View Alerts** | Card tap | Show alerts | Alerts screen | ❌ Implementation Missing |
| **Active Rides** | Card tap | Show active rides | Rides list | ❌ Implementation Missing |

### 4. **DRIVER MAP SCREEN**

| Button | Type | Action | Target | Status |
|--------|------|--------|--------|--------|
| **💚 Cash Payment (FAB)** | FloatingActionButton | Show dialog | Payment input | ✅ Implemented |
| **Start Tracking** | Status button | Begin GPS broadcast | WebSocket | ⚠️ Needs Testing |
| **Stop Tracking** | Status button | Stop GPS broadcast | WebSocket | ⚠️ Needs Testing |
| **Back Button** | AppBar | Navigate back | Previous screen | ✅ System default |

### 5. **CASH PAYMENT DIALOG**

| Button | Type | Action | Target | Status |
|--------|------|--------|--------|--------|
| **Enter Ride ID** | TextField | Input capture | Local state | ✅ Implemented |
| **Submit** | ElevatedButton | Navigate | CashConfirmScreen | ✅ Implemented |
| **Cancel** | TextButton | Close dialog | Map screen | ✅ Implemented |

### 6. **CASH CONFIRM SCREEN**

| Button | Type | Action | Target | Status |
|--------|------|--------|--------|--------|
| **✅ CONFIRM CASH RECEIVED** | ElevatedButton | POST /payments/cash/confirm | Backend | ✅ Implemented |
| **Retry** | TextButton | Retry last failed action | Local retry | ✅ Implemented |
| **Back** | AppBar | Pop screen | Map screen | ✅ Implemented |

---

## 👥 PASSENGER FLOW

### 1. **LOGIN SCREEN**

| Button | Type | Action | Target | Status |
|--------|------|--------|--------|--------|
| **Login** | ElevatedButton | POST /auth/login | PassengerHome | ✅ Implemented |
| **Sign Up** | TextButton | Navigate | PassengerRegisterScreen | ⚠️ Needs Implementation |
| **Forgot Password** | TextButton | Navigate | ForgotPasswordScreen | ✅ Implemented |
| **Show/Hide Password** | IconButton | Toggle visibility | Local state | ✅ Implemented |

### 2. **PASSENGER HOME (Navigation Hub)**

| Button | Type | Screen | Status |
|--------|------|--------|--------|
| Dashboard | BottomNavItem | PassengerDashboard | ✅ Active |
| Search/Alerts | BottomNavItem | PassengerSearchAlerts | ✅ Active |
| About | BottomNavItem | PassengerAbout | ✅ Active |

### 3. **PASSENGER DASHBOARD**

| Button | Type | Action | Target | Status |
|--------|------|--------|--------|--------|
| **Close Location Banner** | IconButton | Dismiss banner | Local state | ✅ Implemented |
| **Search Station** | Card tap | Show station picker | Selection | ❌ Implementation Missing |
| **Track Bus** | ElevatedButton | POST /rides/create | PassengerMapScreen | ❌ Implementation Missing |

### 4. **PASSENGER MAP SCREEN**

| Button | Type | Action | Target | Status |
|--------|------|--------|--------|--------|
| **Track Driver** | Status start | Connect WebSocket | /ws/passenger/{driverId} | ✅ Implemented |
| **Stop Tracking** | Status stop | Disconnect WebSocket | Current connection | ✅ Implemented |
| **Pay ₱XX.XX** | ElevatedButton | Navigate | PaymentScreen | ✅ Implemented |
| **Back Button** | AppBar | Navigate back | Previous screen | ✅ System default |

### 5. **PAYMENT SCREEN**

| Button | Type | Action | Target | Status |
|--------|------|--------|--------|--------|
| **💵 Cash** | ElevatedButton | POST /payments/initiate (cash) | PaymentConfirm | ✅ Implemented |
| **🔵 GCash** | ElevatedButton | POST /payments/initiate (gcash) | Mock checkout | ✅ Implemented |
| **💎 E-Wallet** | ElevatedButton | POST /payments/initiate (ewallet) | Mock checkout | ✅ Implemented |
| **Cancel** | TextButton | Pop screen | Map screen | ✅ Implemented |

---

## 🔧 IMPLEMENTATION STATUS SUMMARY

### ✅ FULLY IMPLEMENTED (17 buttons)
1. Home: "I'm a Driver" → DriverLogin
2. Home: "I'm a Passenger" → PassengerLogin
3. Login: Login button → Backend auth
4. Login: Show/Hide password toggle
5. DriverHome: Dashboard tab
6. DriverHome: Routes tab
7. DriverHome: About tab
8. DriverMap: Cash Payment FAB
9. CashPayment: Submit button
10. CashPayment: Cancel button
11. CashConfirm: Confirm button
12. CashConfirm: Retry button
13. PassengerHome: Dashboard tab
14. PassengerHome: Search tab
15. PassengerHome: About tab
16. PaymentScreen: Cash button
17. PaymentScreen: GCash button
18. PaymentScreen: E-Wallet button

### ⚠️ NEEDS TESTING/FIXING (6 buttons)
1. DriverDashboard: Accept Passengers toggle → Needs backend connection
2. DriverMap: Start/Stop Tracking → Needs GPS testing
3. PassengerDashboard: Close banner → Works, needs integration
4. PassengerDashboard: Search/Track buttons → Needs implementation
5. Login screens: Sign up buttons → Needs implementation
6. Forgot password flows → Partially implemented

### ❌ MISSING IMPLEMENTATION (4 areas)
1. DriverDashboard: View Alerts functionality
2. DriverDashboard: Active Rides list
3. PassengerDashboard: Station search picker
4. PassengerDashboard: Track bus (create ride)

---

## 🧪 TESTING CHECKLIST

### Test 1: Home Screen Navigation
```
[ ] Click "I'm a Driver" → Opens DriverLoginScreen
[ ] Click "I'm a Passenger" → Opens PassengerLoginScreen
```

### Test 2: Driver Login Flow
```
[ ] Enter valid driver credentials → Login successful
[ ] Enter invalid credentials → Shows error
[ ] Click "Show Password" → Toggles visibility
[ ] Click "Sign Up" link → Opens registration (if implemented)
[ ] Click "Forgot Password" → Opens recovery (if implemented)
```

### Test 3: Driver Dashboard
```
[ ] Toggle "Accept Passengers" switch → Updates backend
[ ] Verify online status changes in real-time
[ ] Check Today's Earnings display
[ ] Verify active rides counter updates
```

### Test 4: Driver Map & Cash Payment
```
[ ] Click "💚 Cash Payment" FAB → Shows dialog
[ ] Enter ride ID → Validates input
[ ] Click "Submit" → Navigates to CashConfirmScreen
[ ] See payment details on CashConfirmScreen
[ ] Click "✅ CONFIRM CASH RECEIVED" → Processes payment
[ ] Verify success message appears
[ ] Check payment status updated to "paid"
```

### Test 5: Driver GPS Tracking
```
[ ] Map loads successfully
[ ] Click "Start Tracking" → Begin WebSocket connection
[ ] GPS updates every 5 seconds
[ ] Backend receives location updates
[ ] Click "Stop Tracking" → WebSocket disconnects
[ ] Location broadcast stops
```

### Test 6: Passenger Login Flow
```
[ ] Enter valid passenger credentials → Login successful
[ ] Enter invalid credentials → Shows error
[ ] Click "Show Password" → Toggles visibility
[ ] Click "Sign Up" link → Opens registration (if implemented)
```

### Test 7: Passenger Dashboard
```
[ ] Display current location
[ ] Show location banner
[ ] Click close icon → Banner dismisses
[ ] View recent rides
[ ] See trip information card
```

### Test 8: Passenger Map Tracking
```
[ ] Input driver ID → Connects WebSocket
[ ] Map displays
[ ] Bus marker appears and moves
[ ] ETA updates in real-time
[ ] Driver location broadcasts update marker every 5 seconds
```

### Test 9: Payment Processing
```
[ ] Reach end of ride
[ ] Fare displays correctly
[ ] Click "💵 Cash" → Shows waiting dialog
[ ] Click "🔵 GCash" → Shows mock checkout
[ ] Click "💎 E-Wallet" → Shows mock checkout
[ ] Backend confirms payment
[ ] Status changes to "paid"
```

### Test 10: Error Handling
```
[ ] Test button action with no internet
[ ] Test button action with invalid data
[ ] Verify error messages are user-friendly
[ ] Verify retry mechanisms work
```

---

## 🚀 IMPLEMENTATION PRIORITY

### Phase 1: Critical (Required for MVP)
- [x] All home/login/navigation buttons
- [x] Driver GPS tracking buttons
- [x] Payment initiation buttons
- [x] Payment confirmation button

### Phase 2: Important (Required for v1.0)
- [ ] Dashboard toggle states with backend sync
- [ ] View alerts functionality
- [ ] Active rides display
- [ ] Station search and booking

### Phase 3: Enhancement (Nice to have)
- [ ] Sign up from login screen
- [ ] Forgot password flow
- [ ] Ride history view
- [ ] Driver statistics dashboard

---

## 🔗 Button-to-API Mapping

### Driver Buttons → API Endpoints
```
✅ Login → POST /auth/login
⚠️ Accept Passengers toggle → PUT /drivers/{id}/status  [NEEDS IMPL]
✅ Start Tracking → WebSocket /ws/driver/{driver_id}
✅ Cash Payment → POST /payments/initiate
✅ Confirm Payment → POST /payments/cash/confirm
```

### Passenger Buttons → API Endpoints
```
✅ Login → POST /auth/login
❌ Create Ride → POST /rides/create [NEEDS BUTTON]
✅ Track Driver → WebSocket /ws/passenger/{driver_id}
✅ Initiate Payment → POST /payments/initiate
```

---

## 📝 NEXT STEPS

### Immediate Actions Required:
1. **Test Driver Dashboard Toggle** - Ensure "Accept Passengers" syncs to backend
2. **Implement Station Search** - Add search functionality to PassengerDashboard
3. **Complete Forgot Password** - Ensure flow works end-to-end
4. **Test all WebSocket buttons** - Verify GPS tracking works correctly
5. **Test Payment Flow** - Do end-to-end payment from passenger to driver

### Code Files to Review:
- `lib/driver/driver_dashboard.dart` - Add backend API calls
- `lib/passenger/passenger_dashboard.dart` - Add ride creation
- `lib/driver/driver_map.dart` - Verify GPS tracking
- `lib/passenger/passenger_map.dart` - Verify payment button

---

## 📊 Button Functionality Status Matrix

```
Screen                  | Total | ✅ Implemented | ⚠️ Partial | ❌ Missing
Home                    |   2   |      2        |     0     |     0
Driver Login            |   4   |      2        |     2     |     0
Driver Dashboard        |   3   |      0        |     2     |     1
Driver Map              |   3   |      1        |     2     |     0
Cash Payment Dialog     |   3   |      3        |     0     |     0
Cash Confirm Screen     |   3   |      3        |     0     |     0
Passenger Login         |   4   |      2        |     2     |     0
Passenger Dashboard     |   3   |      1        |     1     |     1
Passenger Map           |   4   |      3        |     0     |     1
Payment Screen          |   4   |      3        |     0     |     1
────────────────────────────────────────────────────────────
TOTAL                   |  34   |     20        |     9     |     5
Success Rate: 59%
```

---

**Status**: 🔄 In Progress - Phase 1 Complete, Phase 2 In Progress
**Last Updated**: 2026-02-26
**Priority**: HIGH - Complete Phase 2 before production release
