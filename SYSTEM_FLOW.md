# 🔄 PEAK MAP - Complete System Flow (Step-by-Step)

**Version:** 2.0 (With Card Tap & Payment System)  
**Last Updated:** March 8, 2026  
**Status:** Production-Ready

---

## 📋 Table of Contents

1. [System Overview](#system-overview)
2. [User Roles & Permissions](#user-roles--permissions)
3. [Complete User Journeys](#complete-user-journeys)
4. [Payment & Card System](#payment--card-system)
5. [Real-Time Features](#real-time-features)
6. [Admin Operations](#admin-operations)
7. [Error Handling & Recovery](#error-handling--recovery)
8. [Data Flow Diagrams](#data-flow-diagrams)

---

## 🏗️ System Overview

### Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│              Presentation Layer (User Interfaces)            │
│  ┌──────────────────┐  ┌──────────────────┐  ┌────────────┐ │
│  │  Passenger App   │  │   Driver App     │  │ Admin UI   │ │
│  │    (Flutter)     │  │   (Flutter)      │  │  (HTML)    │ │
│  └────────┬─────────┘  └────────┬─────────┘  └───────┬────┘ │
└───────────┼──────────────────────┼──────────────────────┼─────┘
            │                      │                      │
            └──────────────────────┼──────────────────────┘
                                   │
            ┌──────────────────────┴──────────────────────┐
            │                                             │
┌───────────v──────────────────────────────────────────v─────────┐
│                 Application Layer (FastAPI)                     │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │  Auth APIs  │  │  Ride Logic  │  │  Payment Processing  │   │
│  ├─────────────┤  ├──────────────┤  ├──────────────────────┤   │
│  │ Login       │  │ Tracking     │  │ Tap-In/Tap-Out       │   │
│  │ Register    │  │ ETA Calc     │  │ Balance Management   │   │
│  │ Session Mgmt│  │ QR Pairing   │  │ Fare Deduction       │   │
│  │             │  │ Drop-off     │  │ Card Matching        │   │
│  └─────────────┘  └──────────────┘  └──────────────────────┘   │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │  GPS Service │  │  RFID System │  │   Admin Services     │   │
│  ├──────────────┤  ├──────────────┤  ├──────────────────────┤   │
│  │ Location     │  │ Card Tap     │  │ Dashboard Control    │   │
│  │ Broadcast    │  │ Recognition  │  │ Fleet Monitoring     │   │
│  │ Tracking     │  │ Balance Calc │  │ Revenue Reports      │   │
│  └──────────────┘  └──────────────┘  └──────────────────────┘   │
└────────────────────────────────────────────────────────────────┘
            │
┌───────────v──────────────────────────────────────────────────────┐
│                  Data Layer (Databases)                          │
│  ┌─────────────────┐  ┌──────────────────┐  ┌────────────────┐  │
│  │  Users Table    │  │  Payments Table  │  │  Rides Table   │  │
│  ├─────────────────┤  ├──────────────────┤  ├────────────────┤  │
│  │ Drivers         │  │ Transactions     │  │ Active Journeys│  │
│  │ Passengers      │  │ Balance History  │  │ Tap Records    │  │
│  │ Admin Users     │  │ Fare Logs        │  │ Sessions       │  │
│  └─────────────────┘  └──────────────────┘  └────────────────┘  │
│                                                                   │
│  ┌──────────────────┐  ┌──────────────────┐  ┌────────────────┐  │
│  │  Stations Table  │  │  GPS Logs Table  │  │  RFID Cards    │  │
│  ├──────────────────┤  ├──────────────────┤  ├────────────────┤  │
│  │ Bus Stops        │  │ Location History │  │ Card Registry  │  │
│  │ GPS Coords       │  │ Driver Tracking  │  │ Owner Mapping  │  │
│  │ Fare Zones       │  │ Route Analysis   │  │ Balance Linked │  │
│  └──────────────────┘  └──────────────────┘  └────────────────┘  │
└───────────────────────────────────────────────────────────────────┘
```

---

## 👥 User Roles & Permissions

### Passenger
- **Can Do:**
  - Register with email/phone
  - View live bus tracking on map
  - Scan QR code to board bus
  - Tap card to board (with balance checking)
  - Receive real-time ETA updates
  - Receive stop alerts (approaching/arrived)
  - View trip history
  - Manage account balance
  - Tap card to exit and auto-pay fare

- **Cannot Do:**
  - See other passengers
  - Access driver data
  - Modify fares
  - Access admin functions

### Driver
- **Can Do:**
  - Register with email/code
  - Go online/offline
  - Broadcast GPS location every 5 seconds
  - See assigned bus info
  - See passenger list (on bus)
  - Manage active route
  - Update status

- **Cannot Do:**
  - See all passengers in system
  - Modify fares
  - Access admin functions
  - See other drivers' routes

### Admin
- **Can Do:**
  - View all users and rides
  - Monitor all drivers (real-time location)
  - View revenue and payments
  - Configure fares
  - Manage system settings
  - View analytics and reports
  - Test system (RFID manager, simulate functions)

- **Cannot Do:**
  - (Full system access)

---

## 🚀 Complete User Journeys

### JOURNEY 1: Driver Morning Startup

```
START: Driver Launches App
│
├─ STEP 1: Open Flutter App
│  └─ App loads with home screen
│
├─ STEP 2: Select "I'm a Driver"
│  └─ Redirected to driver login screen
│
├─ STEP 3: Enter Credentials
│  ├─ Email: driver@peakmap.com
│  ├─ Password: securepass123
│  └─ POST /drivers/login
│      ├─ Backend validates credentials
│      ├─ Checks Supabase user table
│      ├─ Generates JWT token
│      └─ Returns: {driver_id, token, bus_id}
│
├─ STEP 4: App Receives Token
│  ├─ Stores in local storage
│  ├─ Sets up API headers with token
│  └─ Redirects to driver map screen
│
├─ STEP 5: Driver Map Loads
│  ├─ Calculates driver's current GPS location
│  ├─ Requests assigned bus info: GET /buses/{bus_id}
│  ├─ Gets station list: GET /stations
│  ├─ Renders map with driver marker
│  └─ Map shows: Bus info, routes, stations
│
├─ STEP 6: Driver Clicks "Go Online"
│  ├─ POST /drivers/{driver_id}/status
│  │  └─ Body: {is_online: true}
│  ├─ Backend updates drivers table
│  │  └─ Sets: online_status = true, last_online_at = NOW()
│  ├─ Broadcasting system activates
│  └─ Response: {status: "online", driver_id: 1, bus_id: 1}
│
├─ STEP 7: GPS Broadcasting Starts
│  ├─ App activates location tracking every 5 seconds
│  ├─ Gets current GPS: {latitude, longitude, accuracy}
│  ├─ POST /gps/update
│  │  └─ Body: {driver_id: 1, bus_id: 1, lat, lng, timestamp}
│  ├─ Backend stores in gps_logs table
│  │  └─ Creates: {driver_id, lat, lng, timestamp, accuracy}
│  ├─ WebSocket broadcasts to all connected passenger apps
│  │  └─ Sends: Bus location update
│  └─ Repeats every 5 seconds while online
│
├─ STEP 8: Passenger Sees Bus on Map
│  ├─ Passenger app receives WebSocket update
│  ├─ Updates bus marker on map in real-time
│  ├─ Calculates ETA using Google Maps API
│  │  └─ Route: Current Bus Location → Passenger's Station
│  ├─ Displays: "Your bus is 2.3 km away, ETA: 8 minutes"
│  └─ Updates every 5-10 seconds
│
└─ END: Driver is Broadcasting, Passengers See Live Tracking
```

### JOURNEY 2: Passenger Boarding (Card Tap System)

```
START: Passenger at Bus Station (Waiting)
│
├─ STEP 1: Passenger Opens App
│  ├─ Logged in as passenger (or logs in first)
│  └─ Sees: "Your buses departing now" -> list of available buses
│
├─ STEP 2: Passenger Selects Bus
│  ├─ Taps on bus from the list
│  ├─ App shows: Bus route, current location, next stations
│  └─ Displays: "Bus arriving in 5 minutes"
│
├─ STEP 3: Bus Arrives at Station
│  ├─ Driver maintains route
│  ├─ Passenger sees: "Your bus has arrived!"
│  └─ Alert: "Please tap your card to board"
│
├─ STEP 4a: CARD TAP RECOGNITION (NEW SYSTEM)
│  ├─ Passenger taps NFC/RFID card
│  │  └─ Card has UID: "1603310630"
│  ├─ Hardware reader sends UID to backend
│  │  └─ Or QR code embedded with card UID
│  ├─ Backend receives tap-in request
│  │  └─ POST /payments/tap-in
│  │     └─ Body: {user_id: 5, bus_id: 1, station_id: 1, card_uid: "1603310630"}
│  ├─ Tap-In Processing:
│  │  ├─ Check 1: Does the card exist?
│  │  │  └─ Query rfid_cards table for card_uid
│  │  │  └─ Result: Found (owner: user_id 5 = carllachica)
│  │  ├─ Check 2: Is card active?
│  │  │  └─ Query rfid_cards.status
│  │  │  └─ Result: status = "active" ✅
│  │  ├─ Check 3: What's the current balance?
│  │  │  └─ Query payments table
│  │  │  └─ Calculate: SUM(admin_nfc) - SUM(bus_fare_nfc)
│  │  │  └─ Result: ₱500.00 ✅
│  │  ├─ Check 4: Is balance above minimum (₱50)?
│  │  │  └─ Result: ₱500 >= ₱50 ✅
│  │  ├─ Check 5: Any existing open trips?
│  │  │  └─ Query rides table where user_id=5 and status='pending'
│  │  │  └─ Result: None found ✅
│  │  ├─ Create Tap-In Record:
│  │  │  └─ INSERT INTO rides:
│  │  │     ├─ user_id: 5
│  │  │     ├─ driver_id: 1
│  │  │     ├─ bus_id: 1
│  │  │     ├─ boarding_station_id: 1
│  │  │     ├─ status: "pending" (waiting for tap-out)
│  │  │     ├─ tap_in_time: 2026-03-08 10:30:45
│  │  │     └─ card_uid: "1603310630" ← STORED FOR LATER VALIDATION
│  │  ├─ Create Payment Log Entry:
│  │  │  └─ INSERT INTO payments:
│  │  │     ├─ user_id: 5
│  │  │     ├─ type: "tap_in"
│  │  │     ├─ reference: "TAPIN-1603310630-5-1-1-1709865432.123"
│  │  │     │  └─ Format: TAPIN-{card_uid}-{user_id}-{bus_id}-{station_id}-{timestamp}
│  │  │     ├─ amount: 0 (no charge yet)
│  │  │     └─ status: "recorded"
│  │  └─ Response:
│  │     ├─ {success: true, status: "boarded"}
│  │     ├─ message: "Welcome aboard! Your balance: ₱500.00"
│  │     ├─ boarding_time: "2026-03-08 10:30:45"
│  │     └─ card_uid: "1603310630"
│
├─ STEP 4b: UI Feedback
│  ├─ App shows green checkmark: "Boarding Successful!"
│  ├─ Displays: "You boarded at Station 1"
│  ├─ Shows: "Balance: ₱500.00"
│  ├─ Vibrates and plays success sound
│  └─ Redirects to in-journey screen
│
├─ STEP 5: Passenger on Board
│  ├─ Ride status changes from "pending" to "active"
│  ├─ Backend monitors for passenger's destination
│  ├─ Passenger sees: Current station, next stations, route
│  ├─ GPS broadcast from driver updates every 5 seconds
│  ├─ Passenger receives alerts:
│  │  ├─ "Approaching Station 3..." (100m away)
│  │  ├─ "Station 3 - Your stop! Prepare to exit"
│  │  └─ "Arriving at Station 3..."
│  └─ Driver sees passenger in list
│
├─ STEP 6a: CARD TAP AT EXIT STATION
│  ├─ Passenger sees: "Station 3 - Tap card to exit"
│  ├─ Passenger taps SAME card at reader
│  │  └─ Card UID: "1603310630" (MUST MATCH tap-in)
│  ├─ Hardware reader sends exit tap
│  │  └─ POST /payments/tap-out
│  │     └─ Body: {user_id: 5, bus_id: 1, station_id: 3, card_uid: "1603310630"}
│  ├─ Tap-Out Processing:
│  │  ├─ Check 1: Is there a pending ride for this user?
│  │  │  └─ Query rides where user_id=5 AND status='active'
│  │  │  └─ Result: Found (boarding_station=1, exit_station=NULL)
│  │  ├─ Check 2: CRITICAL - Does card UID match tap-in card?
│  │  │  ├─ Extract from ride.card_uid: "1603310630"
│  │  │  ├─ Compare with current tap: "1603310630"
│  │  │  ├─ Result: ✅ MATCH! Same card used
│  │  │  └─ (If mismatch: REJECT with error message)
│  │  ├─ Check 3: Is balance sufficient for fare?
│  │  │  ├─ Query current balance: ₱500.00
│  │  │  ├─ Calculate fare (Station 1→3): ₱35.00
│  │  │  ├─ Check: ₱500 >= ₱35? YES ✅
│  │  │  └─ If insufficient: REJECT and suggest load balance
│  │  ├─ Deduct Fare:
│  │  │  └─ INSERT INTO payments:
│  │  │     ├─ user_id: 5
│  │  │     ├─ type: "bus_fare_nfc"
│  │  │     ├─ reference: "BUSFARE-1603310630-5-1-1-3-1709865453.234"
│  │  │     ├─ amount: -35.00 (DEDUCTION)
│  │  │     └─ status: "completed"
│  │  ├─ Close Ride:
│  │  │  ├─ UPDATE rides SET:
│  │  │  │  ├─ status: "completed"
│  │  │  │  ├─ exit_station_id: 3
│  │  │  │  └─ tap_out_time: 2026-03-08 10:45:30
│  │  │  └─ Calculate trip duration: 14 minutes 45 seconds
│  │  └─ Final Response:
│  │     ├─ {success: true, status: "exit_granted"}
│  │     ├─ message: "Exit successful. Fare deducted."
│  │     ├─ card_uid: "1603310630"
│  │     ├─ card_matched: true ← CONFIRMS SAME CARD
│  │     ├─ fare_amount: 35.00
│  │     ├─ previous_balance: 500.00
│  │     ├─ new_balance: 465.00
│  │     └─ trip_duration: "14 minutes 45 seconds"
│
├─ STEP 6b: U Case - DIFFERENT CARD REJECTED ❌
│  ├─ Passenger tries to use different card: "ABCD1234"
│  ├─ Tap-Out Processing:
│  │  ├─ Check: Does card UID match tap-in card?
│  │  │  ├─ Expected: "1603310630"
│  │  │  ├─ Provided: "ABCD1234"
│  │  │  └─ Result: ❌ MISMATCH! Different card
│  │  └─ Response:
│  │     ├─ {success: false, status: "card_mismatch"}
│  │     ├─ error: "Card mismatch! You tapped in with card 1603310630 but tapping out with ABCD1234"
│  │     ├─ expected_card: "1603310630"
│  │     └─ provided_card: "ABCD1234"
│  ├─ UI Shows:
│  │  ├─ Red error message
│  │  ├─ "ERROR: Wrong card! Please use the same card you tapped with."
│  │  ├─ "Your card: 1603310630"
│  │  └─ Sound alert (3 beeps)
│  ├─ Ride Remains "active"
│  │  └─ Passenger must tap same card again
│  └─ PREVENTS FRAUD: Can't use different card to avoid payment
│
├─ STEP 7: Exit Confirmation
│  ├─ App shows green checkmark: "Exit Successful!"
│  ├─ Displays: "New balance: ₱465.00"
│  ├─ Shows: "Fare paid: ₱35.00"
│  ├─ Trip marked as completed
│  ├─ Driver sees passenger removed from list
│  ├─ Admin system logs the trip
│  └─ Device vibrates and plays success sound
│
└─ END: Passenger Exited, Fare Auto-Paid, Balance Updated
```

### JOURNEY 3: Passenger Loading Balance (Top-Up)

```
START: Passenger Wants to Add Funds
│
├─ STEP 1: Open App → Wallet Section
│  └─ View current balance: ₱465.00
│
├─ STEP 2: Click "Load Balance"
│  ├─ Dialog appears with amount options:
│  │  ├─ ₱100
│  │  ├─ ₱200
│  │  ├─ ₱500
│  │  └─ Custom amount
│  └─ Select: ₱500
│
├─ STEP 3: Tap Card to Load
│  ├─ Hardware reader detects card tap
│  ├─ System sends: POST /payments/load-balance
│  │  └─ Body: {user_id: 5, card_uid: "1603310630", amount: 500}
│  ├─ Backend processes:
│  │  ├─ Verify card exists and is active
│  │  ├─ Create payment record:
│  │  │  └─ INSERT INTO payments:
│  │  │     ├─ user_id: 5
│  │  │     ├─ type: "admin_nfc"
│  │  │     ├─ reference: "LOAD-1603310630-5-500-1709865460.500"
│  │  │     ├─ amount: +500.00
│  │  │     └─ status: "completed"
│  │  └─ New balance calculated:
│  │     ├─ Previous: ₱465.00
│  │     ├─ Added: +₱500.00
│  │     └─ Result: ₱965.00
│  └─ Response: {success: true, new_balance: 965.00}
│
├─ STEP 4: Confirmation
│  ├─ App shows: "✅ Balance loaded successfully!"
│  ├─ Updated balance display: ₱965.00
│  ├─ Receipt shown:
│  │  ├─ Amount: ₱500.00
│  │  ├─ Date: 2026-03-08 10:47:20
│  │  ├─ Card: 1603310630
│  │  └─ New Balance: ₱965.00
│  └─ Sound: Success chime
│
└─ END: Balance Updated, Ready to Travel Again
```

### JOURNEY 4: Admin Monitoring Dashboard

```
START: Admin Opens Dashboard
│
├─ STEP 1: Navigate to admin_dashboard.html
│  └─ Web browser loads the admin interface
│
├─ STEP 2: Real-Time Dashboard View
│  ├─ GET /admin/dashboard_overview
│  └─ Response:
│     ├─ Total Drivers Online: 24
│     ├─ Total Passengers Today: 1,247
│     ├─ Rides Completed: 892
│     ├─ Revenue Today: ₱31,220
│     ├─ Average Fare: ₱35.00
│     └─ System Status: ✅ Operational
│
├─ STEP 3: Live Driver Monitoring
│  ├─ GET /admin/all_drivers
│  ├─ Response: List of all drivers with:
│  │  ├─ Driver ID, Name, Status (Online/Offline)
│  │  ├─ Current Location: (lat, lng)
│  │  ├─ Bus ID assigned
│  │  ├─ Passengers onboard
│  │  └─ Last GPS update timestamp
│  └─ Map displays:
│     ├─ All bus locations (green markers)
│     ├─ Passenger pickup points (blue markers)
│     └─ Stations (red markers)
│
├─ STEP 4: Individual Driver Status
│  ├─ Admin clicks on a driver marker
│  ├─ Sidebar shows detailed info:
│  │  ├─ Driver Name: John Santos
│  │  ├─ Status: Online
│  │  ├─ Current Location: Makati Avenue
│  │  ├─ Bus: Bus #5, Capacity: 50, Onboard: 23
│  │  ├─ Route: EDSA Express
│  │  ├─ GPS Accuracy: ±5m
│  │  └─ Last Update: 2 seconds ago
│  └─ Action buttons:
│     ├─ Force Offline (emergency)
│     ├─ Message Driver
│     └─ View History
│
├─ STEP 5: Revenue Monitoring
│  ├─ GET /admin/payments/today
│  └─ Response:
│     ├─ Fares Collected: ₱28,750
│     ├─ Balance Loads: ₱2,470
│     ├─ Refunds: ₱0
│     ├─ Net Revenue: ₱31,220
│     ├─ Transactions: 892
│     └─ By Payment Type:
│        ├─ Card Tap (RFID): 847 trips, ₱29,645
│        ├─ QR Code: 45 trips, ₱1,575
│        └─ Manual: 0 trips, ₱0
│
├─ STEP 6: RFID Manager (Card System)
│  ├─ Admin clicks: "RFID Manager"
│  ├─ Screen shows:
│  │  ├─ Registered Cards: 247
│  │  ├─ Active Cards: 235
│  │  ├─ Inactive/Blocked: 12
│  │  └─ Search bar for card UID
│  ├─ Actions available:
│  │  ├─ Register new card
│  │  ├─ Manage card balance
│  │  ├─ Block/Unblock card
│  │  ├─ Reassign card to different user
│  │  └─ View transaction history
│  └─ Test Functions (Removed "Simulate Tap" for production)
│
├─ STEP 7: Ride Analytics
│  ├─ View ride statistics:
│  │  ├─ Total Rides Today: 892
│  │  ├─ Average Passengers per Ride: 25
│  │  ├─ Busiest Time: 8:00 AM - 9:00 AM
│  │  ├─ Most Popular Route: EDSA Express
│  │  └─ Peak Boarding Station: Makati
│  └─ Charts show:
│     ├─ Revenue over time (hourly)
│     ├─ Passenger volume (hourly)
│     ├─ Driver utilization
│     └─ Vehicle efficiency
│
├─ STEP 8: Alert Management
│  ├─ System alerts displayed:
│  │  ├─ ⚠️ Driver #5 offline for 15 minutes
│  │  ├─ ⚠️ Bus #12 low on fuel
│  │  ├─ ✅ All cards synched
│  │  └─ 📊 Revenue target: 94% of daily goal
│  └─ Actions:
│     ├─ Click alert to view details
│     ├─ Mark as resolved
│     └─ Set custom reminders
│
├─ STEP 9: Settings & Configuration
│  ├─ Admin can configure:
│  │  ├─ Fare pricing by route
│  │  ├─ Minimum balance requirement
│  │  ├─ Card load limits
│  │  ├─ Payment processing options
│  │  └─ System notifications
│  └─ Save settings
│
└─ END: Admin Dashboard Updated in Real-Time Every 5-10 Seconds
```

---

## 💳 Payment & Card System (Detailed)

### Card Tap Flow Architecture

```
Physical Card Reader (ESP32 + RC522 RFID)
        │
        ├─ Detects card proximity
        ├─ Reads NFC UID: "1603310630"
        └─ Sends via serial/API to backend
                │
                v
         Backend Endpoint
                │
        ├─ POST /payments/tap-in (boarding)
        └─ POST /payments/tap-out (exit)
                │
                v
         Validation Layer
                │
        ├─ Check: Card exists in rfid_cards?
        ├─ Check: Card is active?
        ├─ Check: User has valid record?
        ├─ Check: Balance available?
        └─ For exit: Check: Same card as tap-in?
                │
                v
         Payment Processing
                │
        ├─ Tap-In: Record ride start, NO charge
        ├─ Tap-Out: Calculate fare, DEDUCT from balance
        └─ Log in payments table with reference
                │
                v
         Database Update
                │
        ├─ Update rides table (status, times)
        ├─ Insert payments table (transaction log)
        ├─ Update rfid_cards.last_tapped_at
        └─ Update user balance cache
                │
                v
         Response to Client
                │
        ├─ Success/Failure status
        ├─ Card information
        ├─ Balance information
        ├─ For tap-out: Fare amount, trip time
        └─ For errors: Detailed error message
                │
                v
         UI Display
                │
        ├─ Green checkmark + sound (success)
        ├─ Updated balance display
        ├─ Trip information shown
        └─ Or red error message with reason
```

### Balance Calculation Logic

```
BALANCE = Total Admin Loads - Total Bus Fares

SELECT 
    COALESCE(SUM(CASE WHEN type='admin_nfc' THEN amount ELSE 0 END), 0) -
    COALESCE(SUM(CASE WHEN type='bus_fare_nfc' THEN amount ELSE 0 END), 0)
FROM payments
WHERE user_id = ?

Example:
    Loads:    +₱500.00 (initial)
              +₱500.00 (top-up 1)
              +₱500.00 (top-up 2)
              = ₱1,500.00 TOTAL ADDED
    
    Fares:    -₱35.00 (trip 1)
              -₱40.00 (trip 2)
              -₱35.00 (trip 3)
              = ₱110.00 TOTAL DEDUCTED
    
    BALANCE:  ₱1,500.00 - ₱110.00 = ₱1,390.00
```

### Card Matching Security

```
TAP-IN Transaction:
├─ User taps card: "1603310630"
├─ System records in rides table:
│  └─ rides.card_uid = "1603310630"
├─ Reference saved:
│  └─ "TAPIN-1603310630-5-1-1-1709865432.123"
└─ Ride status: "pending"

TAP-OUT Transaction:
├─ User taps card: "1603310630" (or different: "ABCD1234")
├─ System looks up pending trip
├─ Extracts expected card: "1603310630"
├─ Compares with received card: "1603310630"
├─ If MATCH:
│  ├─ Calculate fare
│  ├─ Deduct from balance
│  ├─ Close ride (status: "completed")
│  └─ Return success
└─ If MISMATCH:
   ├─ Reject tap-out
   ├─ Return error with both card UIDs
   ├─ Ride remains "pending"
   └─ User must use correct card
```

---

## ⚡ Real-Time Features

### GPS Broadcasting (WebSocket)

```
Driver GPS Broadcast Loop
├─ Every 5 seconds:
│  ├─ Get driver's GPS location
│  ├─ POST /gps/update
│  │  └─ {driver_id, bus_id, lat, lng, timestamp}
│  ├─ Backend stores in gps_logs table
│  └─ Backend broadcasts via WebSocket to all passenger apps
│
Passenger WebSocket Listener
├─ Connected to backend WebSocket
├─ Receives GPS updates every 5 seconds
├─ Updates bus marker on map
├─ Calculates new ETA
├─ Shows updated distance
└─ Displays: "2.3 km away, ETA: 8 minutes"
```

### ETA Calculation

```
Google Maps API Integration
├─ Input:
│  ├─ Current Bus Location (lat, lng)
│  ├─ Passenger's Destination Station
│  └─ Traffic conditions (optional)
├─ Process:
│  ├─ Call: Google Maps Directions API
│  ├─ Parameters:
│  │  ├─ origin=Bus_GPS
│  │  ├─ destination=Station_GPS
│  │  └─ departure_time=now (for traffic)
│  └─ Returns:
│     ├─ distance_km
│     ├─ duration_minutes (with traffic)
│     └─ polyline (route)
├─ Frontend Calculations:
│  ├─ arrival_time = now + duration
│  ├─ Format for display:
│  │  ├─ "ETA: 8 minutes" (if < 60 min)
│  │  └─ "Arrives: 10:45 AM" (if > 60 min)
│  └─ Update every GPS refresh (5 seconds)
└─ Passenger Alerts:
   ├─ When 1 km away: "Approaching your station"
   ├─ When < 100m: "Your stop is next!"
   └─ At station: "Bus has arrived!"
```

### Push Notifications (Firebase FCM)

```
Notification Trigger Scenarios:
├─ Passenger Notifications:
│  ├─ Bus approaching: "Your bus is 1 km away"
│  ├─ Bus arrived: "Your bus has arrived!"
│  ├─ Missed stop alert: "Did you miss your stop?"
│  ├─ Low balance: "Your card balance is low (₱45)"
│  └─ Ride completed: "Journey complete! Fare: ₱35"
│
├─ Driver Notifications:
│  ├─ New passenger: "Passenger alighting at Station 5"
│  ├─ Passenger waiting: "Passenger waiting at Station 3"
│  └─ Low fuel: "Fuel level low"
│
└─ Admin Notifications:
   ├─ Driver offline: "Driver #5 offline for 15 minutes"
   ├─ High balance: "Revenue alert: ₱50k collected today"
   └─ System issue: "Payment processing delay detected"

Message Format:
{
  "notification": {
    "title": "Your bus has arrived!",
    "body": "Station 1 - Tap your card to board"
  },
  "data": {
    "action": "board_bus",
    "bus_id": "1",
    "station_id": "1"
  }
}
```

---

## 🛠️ Admin Operations

### Admin Functions Available

```
Dashboard Controls:
├─ Driver Management
│  ├─ View all drivers with real-time location
│  ├─ Force driver offline (emergency)
│  ├─ Send message to driver
│  └─ View driver statistics
│
├─ Bus Management  
│  ├─ Assign driver to bus
│  ├─ Update bus status
│  ├─ View bus utilization
│  └─ Maintenance alerts
│
├─ Payment Management
│  ├─ View revenue dashboard
│  ├─ Monitor transaction logs
│  ├─ Adjust/refund transactions (if needed)
│  ├─ Export reports
│  └─ Configure fare pricing
│
├─ RFID Card Management
│  ├─ Register new cards
│  ├─ Block/Unblock cards
│  ├─ Reassign cards to users
│  ├─ View card history
│  ├─ Manage card balances
│  └─ (NO "Simulate Tap" in production)
│
├─ Station Management
│  ├─ Add/edit station locations
│  ├─ Configure fare zones
│  ├─ Set station capacity
│  └─ View station traffic
│
└─ System Configuration
   ├─ Minimum balance requirements
   ├─ Maximum card load limit
   ├─ Fare schedules
   ├─ Notification settings
   └─ System maintenance mode
```

---

## ⚠️ Error Handling & Recovery

### Common Errors & Resolution

```
ERROR 1: Card Not Recognized
├─ Message: "Card not found in system"
├─ Cause: 
│  ├─ Card UID doesn't exist in rfid_cards table
│  ├─ Card reader malfunction
│  └─ Card not registered
├─ Resolution:
│  ├─ Register card in admin dashboard
│  ├─ Check card reader hardware
│  └─ Rescan card
└─ API Response:
   {
     "success": false,
     "error": "Card UID not found in system",
     "suggestion": "Please register this card with admin"
   }

ERROR 2: Insufficient Balance
├─ Message: "Insufficient balance to complete trip"
├─ Cause: 
│  ├─ User balance < fare amount
│  └─ Card has insufficient funds
├─ Resolution:
│  ├─ User must load more balance
│  ├─ Tap card at load balance kiosk
│  └─ Retry journey
└─ API Response:
   {
     "success": false,
     "error": "Insufficient balance",
     "current_balance": 35.00,
     "required_amount": 50.00,
     "shortfall": 15.00,
     "suggestion": "Please load at least ₱15 more"
   }

ERROR 3: Card Mismatch (Exit with Different Card)
├─ Message: "Card mismatch! Wrong card for exit"
├─ Cause: 
│  ├─ User tapped with card A for entry
│  ├─ User attempting to exit with card B
│  └─ Fraud prevention triggered
├─ Resolution:
│  ├─ User must use same card (A) for exit
│  ├─ Check that correct card is being used
│  └─ Retry exit tap
└─ API Response:
   {
     "success": false,
     "error": "Card mismatch! You tapped in with card 1603310630 but tapping out with ABCD1234",
     "expected_card": "1603310630",
     "provided_card": "ABCD1234",
     "suggestion": "Please use the same card you tapped with"
   }

ERROR 4: Duplicate Tap-Out
├─ Message: "You've already exited this journey"
├─ Cause: 
│  ├─ User taps card twice at exit
│  └─ System already processed first tap
├─ Resolution:
│  ├─ Move away from card reader
│  ├─ Get new journey if desired
│  └─ Check confirmation message
└─ API Response:
   {
     "success": false,
     "error": "No active journey found for this card/user",
     "suggestion": "This journey was already completed"
   }

ERROR 5: Network Disconnection
├─ Message: "Cannot connect to server"
├─ Cause: 
│  ├─ Backend server offline
│  ├─ No internet connection
│  └─ Network timeout
├─ Resolution:
│  ├─ Verify internet connection (WiFi or mobile data)
│  ├─ Retry tap after 5 seconds
│  ├─ If persistent, contact admin support
│  └─ Use manual fallback (admin assistance)
└─ UI Handling:
   {
     "offline_mode": true,
     "message": "Network issue. Retrying...",
     "retry_count": 1,
     "max_retries": 3
   }

ERROR 6: Card Blocked/Inactive
├─ Message: "This card is blocked"
├─ Cause: 
│  ├─ Admin blocked the card (lost, stolen, fraud)
│  ├─ Card was never activated
│  └─ Card membership expired
├─ Resolution:
│  ├─ Contact admin to unblock
│  ├─ Verify identity with admin
│  └─ Get new card or reactivate
└─ API Response:
   {
     "success": false,
     "error": "Card status is 'blocked'",
     "card_status": "blocked",
     "suggestion": "Contact support: admin@peakmap.com"
   }
```

### System Recovery Procedures

```
Scenario 1: Backend Server Down
├─ Status: Trip in progress when server crashes
├─ Recovery Steps:
│  ├─ Backend detects no new GPS updates coming in
│  ├─ Automatically restart backend service
│  ├─ Passengers see: "Reconnecting..." indicator
│  ├─ Drivers continue broadcasting (buffered)
│  ├─ When backend recovers:
│  │  ├─ Processes buffered GPS updates
│  │  ├─ Confirms all pending transactions
│  │  ├─ Syncs passenger locations
│  │  └─ Resumes real-time features
│  └─ Users see: "✅ Connected"
└─ Data Safety: No transaction loss (queued locally)

Scenario 2: Payment Processing Failure
├─ Status: Tap-out received but payment not processed
├─ Recovery Steps:
│  ├─ System detects payment IN error after tap-out
│  ├─ Automatically REJECT the tap-out
│  ├─ Keep ride status as "active"
│  ├─ Log failed transaction attempt
│  ├─ Retry payment 3 times
│  ├─ If persistent failure:
│  │  ├─ Alert admin
│  │  ├─ Notify driver
│  │  ├─ Manually process transaction
│  │  └─ Allow passenger to exit
│  └─ Alert & compensation handled
└─ Data Safety: Transaction logged, no double charges

Scenario 3: GPS Data Corruption
├─ Status: Driver location appears in wrong city
├─ Detection: System identifies location jump > 100km in 5 seconds
├─ Recovery:
│  ├─ System flags abnormal update
│  ├─ Does NOT update map (keeps last valid location)
│  ├─ Logs suspicious activity
│  ├─ Requests driver to confirm location
│  ├─ If confirmed: Accepts new location
│  ├─ If not confirmed: Keeps previous valid location
│  └─ Admin can manually investigate
└─ Data Safety: Passenger not misled, integrity maintained
```

---

## 📊 Data Flow Diagrams

### Complete Tap-In/Tap-Out Flow

```
                        ┌─ PASSENGER BOARDING FLOW ─┐

Passenger at Station
        │
        ├─ Taps Card: "1603310630"
        │
        v
Card Reader (ESP32 RC522)
        │
        ├─ Detects NFC UID
        └─ Sends to backend
        │
        v
Backend: POST /payments/tap-in
        │
        ├─ Validate request
        ├─ Query: Card exists?
        ├─ Query: Card active?
        ├─ Query: User exists?
        ├─ Query: Current balance?
        ├─ Query: Existing open trip?
        │
        ├─ All checks PASS ✅
        │
        ├─ INSERT rides:
        │  ├─ user_id: 5
        │  ├─ driver_id: 1
        │  ├─ bus_id: 1
        │  ├─ boarding_station_id: 1
        │  ├─ status: "pending"
        │  ├─ card_uid: "1603310630" ← STORED FOR EXIT VALIDATION
        │  └─ tap_in_time: NOW()
        │
        ├─ INSERT payments (tap-in log):
        │  └─ reference: "TAPIN-1603310630-5-1-1-{timestamp}"
        │
        ├─ Response to Frontend
        │  └─ {success, card_uid, balance: ₱500}
        │
        v
Passenger Mobile App
        │
        ├─ Shows: ✅ "Boarded Successfully!"
        ├─ Displays: "Balance: ₱500.00"
        ├─ Vibrates + Sound
        └─ Transitions to in-journey screen

        ╌─ PASSENGER IN TRANSIT ─╌

Passenger Nearing Exit Station
        │
        ├─ App shows: "Station 3 - Tap to exit"
        │
        v
Passenger Taps Card: "1603310630" (SAME CARD)
        │
        v
Card Reader
        │
        ├─ Reads same UID: "1603310630"
        └─ Sends to backend
        │
        v
Backend: POST /payments/tap-out
        │
        ├─ Validate request
        ├─ Query: Open trip exists?
        │  └─ Found: rides(user_id=5, status='pending')
        │
        ├─ CRITICAL CHECK: Card UID Match?
        │  ├─ From rides table: card_uid = "1603310630"
        │  ├─ From tap: card_uid = "1603310630"
        │  ├─ Result: ✅ MATCH!
        │  └─ (If no match: REJECT with error message)
        │
        ├─ Calculate fare:
        │  ├─ from_station: 1
        │  ├─ to_station: 3
        │  └─ fare_amount: ₱35.00
        │
        ├─ Check balance:
        │  ├─ Current: ₱500.00
        │  ├─ Required: ₱35.00
        │  ├─ Result: ✅ SUFFICIENT
        │  └─ (If insufficient: REJECT)
        │
        ├─ Deduct fare:
        │  └─ INSERT payments:
        │     ├─ type: "bus_fare_nfc"
        │     ├─ amount: -35.00
        │     └─ reference: "BUSFARE-1603310630-5-1-1-3-{timestamp}"
        │
        ├─ Close trip:
        │  └─ UPDATE rides SET:
        │     ├─ status: "completed"
        │     ├─ exit_station_id: 3
        │     └─ tap_out_time: NOW()
        │
        ├─ Response:
        │  └─ {
        │      success: true,
        │      card_uid: "1603310630",
        │      card_matched: true,
        │      fare: 35.00,
        │      new_balance: 465.00
        │    }
        │
        v
Passenger Mobile App
        │
        ├─ Shows: ✅ "Exit Successful!"
        ├─ Displays: "Fare: ₱35.00"
        ├─ Updated: "New Balance: ₱465.00"
        ├─ Vibrates + Success Sound
        └─ Trip marked complete

                └─────────────────────────────┘
```

### Alternative Path: Card Mismatch Rejection

```
Passenger Attempts to Exit with DIFFERENT Card

Passenger Taps Card: "ABCD1234" (DIFFERENT CARD)
        │
        v
Card Reader
        │
        ├─ Reads: "ABCD1234"
        └─ Sends to backend
        │
        v
Backend: POST /payments/tap-out
        │
        ├─ Query: Open trip exists?
        │  └─ Found: rides(user_id=5, status='pending')
        │
        ├─ CRITICAL CHECK: Card UID Match?
        │  ├─ From rides table: card_uid = "1603310630"
        │  ├─ From tap: card_uid = "ABCD1234"
        │  ├─ Result: ❌ MISMATCH!
        │  └─ REJECT immediately
        │
        ├─ Response:
        │  └─ {
        │      success: false,
        │      status: "card_mismatch",
        │      error: "Card mismatch! You tapped in with card 1603310630 but tapping out with ABCD1234",
        │      expected_card: "1603310630",
        │      provided_card: "ABCD1234"
        │    }
        │
        ├─ NO transaction created
        ├─ NO fare deducted
        ├─ Trip remains "pending"
        └─ User MUST use card "1603310630"

        v
Passenger Mobile App
        │
        ├─ Shows: ❌ "ERROR!"
        ├─ Message: "Wrong card! Please use the same card you tapped with."
        ├─ Expected: "1603310630"
        ├─ Provided: "ABCD1234"
        ├─ Alert Sound (3 beeps)
        └─ Screen stays on journey screen (not closed)

Passenger Uses Correct Card
        │
        └─ Retaps card "1603310630" → See previous flow (exit successful)
```

---

## 📚 Database Reference

### Key Tables

```sql
-- Users (Drivers & Passengers)
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    email VARCHAR UNIQUE,
    name VARCHAR,
    role VARCHAR, -- 'driver', 'passenger', 'admin'
    status VARCHAR, -- 'active', 'inactive', 'suspended'
    created_at TIMESTAMP,
    is_online BOOLEAN DEFAULT false,
    last_online_at TIMESTAMP
);

-- RFID Cards
CREATE TABLE rfid_cards (
    card_uid VARCHAR PRIMARY KEY,
    user_id INT,
    alias VARCHAR,
    status VARCHAR, -- 'active', 'blocked', 'lost'
    issued_at TIMESTAMP,
    last_tapped_at TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Rides (Journeys)
CREATE TABLE rides (
    ride_id SERIAL PRIMARY KEY,
    user_id INT,
    driver_id INT,
    bus_id INT,
    boarding_station_id INT,
    exit_station_id INT,
    status VARCHAR, -- 'pending' (waiting for exit), 'completed'
    card_uid VARCHAR, -- ← ADDED: For card matching
    tap_in_time TIMESTAMP,
    tap_out_time TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (driver_id) REFERENCES users(user_id)
);

-- Payments (Transactions)
CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    user_id INT,
    type VARCHAR, -- 'tap_in', 'tap_out', 'admin_nfc', 'bus_fare_nfc'
    reference VARCHAR, -- 'TAPIN-carduid-userid-busid-station-timestamp'
    amount DECIMAL(10, 2),
    previous_balance DECIMAL(10, 2),
    new_balance DECIMAL(10, 2),
    status VARCHAR,
    created_at TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- GPS Logs (Location History)
CREATE TABLE gps_logs (
    log_id SERIAL PRIMARY KEY,
    driver_id INT,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    accuracy FLOAT,
    timestamp TIMESTAMP,
    FOREIGN KEY (driver_id) REFERENCES users(user_id)
);

-- Stations
CREATE TABLE stations (
    station_id SERIAL PRIMARY KEY,
    name VARCHAR,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    zone_id INT,
    sequence_on_route INT
);

-- Fares (Pricing Matrix)
CREATE TABLE fares (
    fare_id SERIAL PRIMARY KEY,
    from_station_id INT,
    to_station_id INT,
    fare_amount DECIMAL(10, 2),
    route_id INT,
    FOREIGN KEY (from_station_id) REFERENCES stations(station_id),
    FOREIGN KEY (to_station_id) REFERENCES stations(station_id)
);
```

---

## 🔑 Key Endpoints Reference

### Card Tap Endpoints
```
GET  /rfid/cards/tap/{card_uid}
     - Quickly retrieve card info and balance
     - Response: {card, user, balance}

POST /payments/tap-in
     - Record passenger boarding
     - Body: {user_id, bus_id, driver_id, station_id, card_uid}
     - Response: {success, ride_id, balance}

POST /payments/tap-out
     - Record passenger exit and deduct fare
     - Body: {user_id, bus_id, driver_id, station_id, card_uid}
     - Response: {success, card_matched, fare, new_balance}
     - ERROR if card_uid doesn't match tap-in card

POST /payments/load-balance
     - Add funds to card/user account
     - Body: {user_id, amount}
     - Response: {success, new_balance}
```

### Driver Endpoints
```
POST /drivers/login
     - Authenticate driver
     - Response: {driver_id, token, bus_id}

POST /drivers/{driver_id}/status
     - Set online/offline status
     - Body: {is_online: true/false}
     - Response: {status, driver_id}

POST /gps/update
     - Record GPS location
     - Body: {driver_id, bus_id, lat, lng, timestamp}
     - Response: {success, broadcasted_to_passengers}
```

### Passenger Endpoints
```
GET  /gps/latest/{driver_id}
     - Get current driver location
     - Response: {driver_id, bus_id, lat, lng, timestamp}

GET  /eta/{passenger_station}/{bus_location}
     - Calculate ETA using Google Maps API
     - Response: {distance_km, duration_minutes, arrival_time}

POST /rides/check-arrival
     - Check if passenger reached destination
     - Triggers arrival notifications
```

### Admin Endpoints
```
GET  /admin/all_drivers
     - Real-time driver list with locations
     - Response: [{driver_id, location, status, passengers_onboard}...]

GET  /admin/dashboard_overview
     - System statistics and metrics
     - Response: {total_drivers, total_passengers, revenue, metrics}

GET  /admin/payments/{date}
     - Revenue for specific date
     - Response: Total by type, transaction count, etc.

POST /admin/rfid/{action}
     - Manage RFID cards (register, block, etc.)
     - Action: "register", "block", "reassign", etc.
```

---

## 📈 System Metrics & Monitoring

### Real-Time Metrics Tracked

```
Performance Metrics:
├─ API Response Time (target: < 200ms)
├─ GPS Broadcast Frequency (every 5 seconds)
├─ Card Tap Recognition Time (target: < 1 second)
├─ Payment Processing Time (target: < 2 seconds)
└─ WebSocket Connection Stability (target: 99.9%)

Business Metrics:
├─ Drivers Online: Current count, peak hours
├─ Passengers Active: Current count, peak times
├─ Revenue: Real-time total, hourly breakdowns
├─ Trips Completed: Daily count, trends
├─ Average Fare: Overall average, by route
├─ Card Tap Success Rate: % of successful taps
├─ Card Mismatch Prevention: # of fraud attempts blocked
└─ System Uptime: % operational (target: 99%)

Alert Triggers:
├─ Driver offline > 15 minutes: Send admin alert
├─ Revenue drop > 10% vs average: Send admin notification
├─ Card tap failure rate > 5%: Investigate system
├─ Payment processing delay > 5 seconds: Retry & alert
├─ Server response time > 500ms: Check server resources
└─ WebSocket disconnections: Automatic reconnection
```

---

## 🎯 Summary: System Flow at a Glance

1. **Driver** opens app, logs in, goes online
2. **Driver** broadcasts GPS every 5 seconds
3. **Passenger** sees live bus on map
4. **Passenger** waits at station
5. **Bus arrives** at station
6. **Passenger taps card** at reader
7. **System validates** card, checks balance, records tap-in
8. **Passenger boards** and sees arrival confirmation
9. **Bus travels** to next station
10. **Passenger gets alerts** as bus approaches exit station
11. **Passenger taps SAME card** at exit
12. **System validates** card matches tap-in, calculates fare
13. **Fare deducted** from balance automatically
14. **Passenger exits** with updated balance
15. **Admin sees** all this in real-time on dashboard
16. **Revenue is logged** with card UID for audit trail

**Security Feature:** If passenger tries to use different card at exit, system rejects with error.

---

**Version History:**
- v1.0: Initial architecture (GPS, ETA, QR, Android deployment)
- v1.5: Added real-time passenger count
- v2.0: Added card tap system with card matching for fraud prevention
- v2.1: Current - Complete system flow documentation

