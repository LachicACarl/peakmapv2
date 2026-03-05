# 🚀 HOW TO RUN PEAK MAP - COMPLETE GUIDE

**Last Updated:** February 18, 2026  
**Status:** All 9 Phases Ready to Run

---

## 🎯 Quick Start (2 minutes)

### For the Impatient:

```bash
# Terminal 1: Backend
cd peak-map-backend
python run_server.py

# Terminal 2: Flutter App
cd peak_map_mobile
flutter run

# Terminal 3: Admin Dashboard
# Open admin_dashboard.html in your browser
```

That's it! ✅

---

## 📋 Full Setup Guide

### Prerequisites

Make sure you have installed:

```
✅ Python 3.8+
✅ Flutter 3.0+
✅ Dart SDK (comes with Flutter)
✅ Google Chrome or Firefox (for admin dashboard)
✅ Android Emulator or iOS Simulator (for mobile)
✅ Git
```

**Check installations:**

```powershell
python --version        # Should be 3.8+
flutter --version       # Should be 3.0+
dart --version         # Should be 2.18+
```

---

## 🖥️ PART 1: BACKEND (FastAPI)

### Step 1: Navigate to Backend

```powershell
cd peak-map-backend
```

### Step 2: Create & Activate Virtual Environment

**Windows (PowerShell):**
```powershell
python -m venv venv
.\venv\Scripts\Activate.ps1
```

**Windows (Command Prompt):**
```cmd
python -m venv venv
venv\Scripts\activate.bat
```

**Linux/Mac:**
```bash
python -m venv venv
source venv/bin/activate
```

### Step 3: Install Dependencies

```powershell
pip install -r requirements.txt
```

**Expected output:**
```
Successfully installed fastapi-0.100.0 uvicorn[standard]-0.23.2 sqlalchemy-2.0.20 ...
```

### Step 4: Initialize Database

```powershell
python -c "from app.database import Base, engine; Base.metadata.create_all(bind=engine); print('✅ Database initialized')"
```

**Expected output:**
```
✅ Database initialized
```

### Step 5: Run Backend Server

```powershell
python run_server.py
```

**Expected output:**
```
INFO:     Uvicorn running on http://127.0.0.1:8000
INFO:     Application startup complete
```

**✅ Backend is running!**

- **API Docs:** http://127.0.0.1:8000/docs
- **Admin Endpoints:** http://127.0.0.1:8000/admin/dashboard_overview
- **WebSocket:** ws://127.0.0.1:8000/ws/driver/1

---

## 📱 PART 2: FLUTTER MOBILE APPS

### Option A: Run on Android Emulator

#### Step 1: Check Devices

```powershell
flutter devices
```

**Expected output:**
```
2 connected devices:
Android Emulator (mobile) • emulator-5554 • android • Android 14 (API 34)
Windows (desktop)         • windows      • windows • Windows
```

#### Step 2: Navigate to Flutter Project

```powershell
cd peak_map_mobile
```

#### Step 3: Get Dependencies

```powershell
flutter pub get
```

**Expected output:**
```
Running "flutter pub get" in peak_map_mobile...
✅ Downloading packages...
✅ Resolving dependencies...
```

#### Step 4: Run App

```powershell
flutter run
```

**Expected output:**
```
Using virtual device 'emulator-5554' running Android 14.
✅ app/lib/main.dart
Install and launch app...
✅ App launched
```

**Device will show:**
```
PEAK MAP
Live GPS Tracking for EDSA Buses

[I'm a Driver]  [I'm a Passenger]
```

✅ **App is running!**

### Option B: Run on iOS Simulator

**Mac only:**

```powershell
open -a Simulator
flutter run
```

### Option C: Run Multiple Instances

**Terminal 1 (Driver):**
```powershell
cd peak_map_mobile
flutter run
```
Then select emulator/device, choose "I'm a Driver"

**Terminal 2 (Passenger):**
```powershell
cd peak_map_mobile
flutter run -d emulator-5555  # Different emulator
```
Then choose "I'm a Passenger"

---

## 🖥️ PART 3: ADMIN DASHBOARD

### Step 1: Open Admin HTML File

**Option A: Using VS Code**
- Open `admin_dashboard.html` in VS Code
- Right-click → "Open with Live Server"

**Option B: Using File Browser**
- Navigate to `admin_dashboard.html`
- Double-click to open in default browser

**Option C: Using Python Server**
```powershell
cd <project_root>
python -m http.server 8080
# Then open http://127.0.0.1:8080/admin_dashboard.html
```

### Step 2: Configure Google Maps API Key

1. Open `admin_dashboard.html` in a text editor
2. Find this line:
```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_GOOGLE_MAPS_API_KEY&callback=initMap"></script>
```

3. Replace `YOUR_GOOGLE_MAPS_API_KEY` with your actual API key
   - Get key from [Google Cloud Console](https://console.cloud.google.com)
   - Enable "Maps JavaScript API" and "Distance Matrix API"

4. Save and refresh browser

### Step 3: Verify Connection

You should see:
- 🟢 **"Connected - Live Updates Active"** indicator
- Google Map centered on EDSA
- Statistics cards (if data exists)

✅ **Admin Dashboard is running!**

---

## 🧪 PART 4: TESTING THE SYSTEM

### Setup Checklist

```
☑️  Backend running on http://127.0.0.1:8000
☑️  Flutter app running (Driver or Passenger)
☑️  Admin dashboard open in browser
☑️  Google Maps API key configured
```

### Test 1: Create Test Data

**Create a driver:**
```bash
curl -X POST http://127.0.0.1:8000/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Driver 1", "role": "driver"}'
```

**Create a passenger:**
```bash
curl -X POST http://127.0.0.1:8000/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Passenger 1", "role": "passenger"}'
```

**Create stations:**
```bash
curl -X POST http://127.0.0.1:8000/stations \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Ayala Station",
    "latitude": 14.5812,
    "longitude": 121.0502,
    "radius": 0.1
  }'

curl -X POST http://127.0.0.1:8000/stations \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Cubao Station",
    "latitude": 14.6199,
    "longitude": 121.0540,
    "radius": 0.1
  }'
```

### Test 2: Start Driver App

1. Open Flutter app on device/emulator
2. Tap **"I'm a Driver"**
3. Enter Driver ID: **1**
4. Tap **"Start Tracking"**
5. You should see:
   - 📍 Blue marker on map (your location)
   - 📡 Status: "Live Broadcasting"
   - GPS coordinates updating

### Test 3: Start Passenger App

1. Open Flutter app on different device/emulator
2. Tap **"I'm a Passenger"**
3. Enter Driver ID: **1**, Station: **1**, Ride ID: **1**
4. You should see:
   - 🚍 Blue marker (driver location)
   - 📌 Moving marker as driver GPS updates
   - ⏱️ ETA countdown
   - Real-time distance

### Test 4: Admin Dashboard

1. Refresh admin dashboard
2. Check top statistics:
   - **Active Rides:** Should show 1 (if ride is ongoing)
   - **Active Drivers:** Should show 1
3. Check **Live Map:**
   - Blue marker for driver
   - Auto-updates every 5 seconds
4. Check **Recent Activity:**
   - New rides appear in feed

### Test 5: Send Test Notification

```bash
curl -X POST http://127.0.0.1:8000/notifications/tests/ride_started/1 \
  -H "Content-Type: application/json" \
  -d '{"eta_minutes": 15}'
```

**Expected:** Notification appears on passenger's device

### Test 6: Test Payment

1. Simulate drop-off: Go to terminal and run
```bash
curl -X POST http://127.0.0.1:8000/rides/1/mark-dropped
```

2. Passenger app should:
   - Show "🎉 You've Arrived!" notification
   - Display payment button

3. Passenger taps payment button
4. Choose payment method (Cash recommended)
5. Driver confirms cash receipt

✅ **Full flow tested!**

---

## 📊 MONITORING & DEBUGGING

### View Backend Logs

**All requests shown in backend terminal:**
```
127.0.0.1:12345 - "GET /admin/active_rides HTTP/1.1" 200
127.0.0.1:12346 - "POST /gps/update HTTP/1.1" 201
127.0.0.1:12347 - "WS /ws/driver/1" 200
```

### View Mobile App Logs

**Flutter console (in terminal where you ran `flutter run`):**
```
I/flutter ( 1234): ✅ WebSocket connected
I/flutter ( 1234): 📡 GPS broadcast every 5 seconds
I/flutter ( 1234): 📡 Broadcasting: {"lat": 14.5547, "lng": 121.0244, ...}
I/flutter ( 1234): ✅ Received GPS update
I/flutter ( 1234): 🗺️ Map marker updated
```

### Check Backend Status

```bash
# Verify backend is running
curl http://127.0.0.1:8000/

# Expected:
# {"status": "PEAK MAP backend running"}
```

### Check Admin Dashboard Console

1. Open browser DevTools (F12)
2. Go to **Console** tab
3. You should see:
```javascript
✅ Admin WebSocket Connected
📡 Fetching dashboard data...
✅ Dashboard data updated
🗺️ Map marker updated for driver 1
```

---

## 🔧 TROUBLESHOOTING

### Issue: "Address already in use" on port 8000

**Cause:** Another service is using port 8000

**Solution:**
```bash
# Find what's using port 8000
netstat -ano | findstr :8000

# Kill the process
taskkill /PID <PID> /F

# Or run on different port
python -c "from app.main import app; import uvicorn; uvicorn.run(app, host='0.0.0.0', port=8001)"
```

### Issue: Flutter app can't connect to backend

**Cause:** Wrong backend URL or backend not running

**Solution:**
1. Verify backend is running: `http://127.0.0.1:8000`
2. Check in `lib/services/api_service.dart`:
```dart
static String baseUrl = "http://127.0.0.1:8000";  // On Android emulator
// OR (if on physical device):
// static String baseUrl = "http://192.168.1.100:8000";  // Your PC IP
```

3. If using physical device, replace `127.0.0.1` with your PC's IP address
```bash
# Get your IP address:
ipconfig  # Windows
ifconfig  # Linux/Mac
```

### Issue: Admin dashboard shows "Disconnected"

**Cause:** WebSocket connection failed

**Solution:**
1. Check backend is running
2. Check browser console (F12) for errors
3. Verify in `admin_dashboard.html`:
```javascript
const WS_URL = "ws://127.0.0.1:8000/ws/admin";  // Should match your backend
```
4. Refresh browser

### Issue: No data in admin dashboard

**Cause:** No rides created yet

**Solution:**
1. Follow "Test 2: Start Driver App" above
2. Create a ride entry in database
3. Admin dashboard should update automatically

### Issue: Flutter app crashes on startup

**Cause:** Missing or incorrect dependency

**Solution:**
```bash
cd peak_map_mobile
flutter clean
flutter pub get
flutter run
```

### Issue: GPS not updating on map

**Cause:** WebSocket not connected or GPS permission denied

**Solution:**
1. Check device permissions (Location)
2. Check Flutter console for errors
3. Verify backend WebSocket is accepting connections:
```bash
# In backend logs, you should see:
# WebSocket connection established: /ws/driver/1
```

---

## 📈 SYSTEM STATUS CHECK

Create a quick status check script:

**check_system.sh (Linux/Mac):**
```bash
#!/bin/bash

echo "🔍 PEAK MAP System Status Check"
echo "================================"
echo ""

# Check backend
echo "🚀 Backend: ", 
if curl -s http://127.0.0.1:8000/ > /dev/null; then
    echo "✅ Running"
else
    echo "❌ Not running"
fi

# Check database
echo "💾 Database: ",
if test -f "peak-map-backend/peakmap.db"; then
    echo "✅ Exists"
else
    echo "❌ Not found"
fi

# Check Flutter project
echo "📱 Flutter Project: ",
if test -d "peak_map_mobile"; then
    echo "✅ Exists"
else
    echo "❌ Not found"
fi

# Check admin dashboard
echo "🖥️  Admin Dashboard: ",
if test -f "admin_dashboard.html"; then
    echo "✅ Exists"
else
    echo "❌ Not found"
fi

echo ""
echo "✅ System ready to run!"
```

**check_system.ps1 (Windows PowerShell):**
```powershell
Write-Host "🔍 PEAK MAP System Status Check"
Write-Host "================================"
Write-Host ""

# Check backend
Write-Host "🚀 Backend: " -NoNewline
try {
    if ((Invoke-WebRequest -Uri http://127.0.0.1:8000/ -UseBasicParsing).StatusCode -eq 200) {
        Write-Host "✅ Running"
    }
} catch {
    Write-Host "❌ Not running"
}

# Check database
Write-Host "💾 Database: " -NoNewline
if (Test-Path "peak-map-backend\peakmap.db") {
    Write-Host "✅ Exists"
} else {
    Write-Host "❌ Not found"
}

# Check Flutter project
Write-Host "📱 Flutter Project: " -NoNewline
if (Test-Path "peak_map_mobile") {
    Write-Host "✅ Exists"
} else {
    Write-Host "❌ Not found"
}

# Check admin dashboard
Write-Host "🖥️  Admin Dashboard: " -NoNewline
if (Test-Path "admin_dashboard.html") {
    Write-Host "✅ Exists"
} else {
    Write-Host "❌ Not found"
}

Write-Host ""
Write-Host "✅ System ready to run!"
```

---

## 📚 ACCESSING KEY URLs

Once everything is running:

| Component | URL | Purpose |
|-----------|-----|---------|
| **Backend API** | http://127.0.0.1:8000 | Main API server |
| **API Docs (Swagger)** | http://127.0.0.1:8000/docs | Interactive API testing |
| **Admin Dashboard** | file:///C:/path/to/admin_dashboard.html | Fleet monitoring |
| **WebSocket (Driver)** | ws://127.0.0.1:8000/ws/driver/1 | Real-time GPS |
| **WebSocket (Admin)** | ws://127.0.0.1:8000/ws/admin | Admin monitoring |

---

## 🎮 FULL END-TO-END TEST SCENARIO

**Time: ~5 minutes**

### Setup (1 min)
```
Terminal 1: Start Backend
Terminal 2: Run Flutter App 1 (Driver)
Terminal 3: Run Flutter App 2 (Passenger)
Browser: Open Admin Dashboard
```

### Execute (4 min)

**Minute 0:**
- Backend running ✅
- Apps running ✅
- Admin dashboard ready ✅

**Minute 1:**
- Driver taps "Start Tracking"
- See live GPS on driver map

**Minute 2:**
- Passenger taps "I'm a Passenger"
- See driver marker on map
- Watch marker move in real-time

**Minute 3:**
- Admin dashboard shows:
  - Active Drivers: 1
  - Active Rides: 1
  - Real-time GPS updates

**Minute 4:**
- Create test notification:
```bash
curl -X POST http://127.0.0.1:8000/notifications/tests/dropped_off/1
```
- Passenger receives notification
- Payment screen shown

✅ **Full system validated!**

---

## 🚀 DEPLOYMENT VARIATIONS

### Development Environment
```
SQLite database (file-based)
localhost:8000
No authentication
Verbose logging
```

### Production Environment
```
PostgreSQL database
Cloud server (AWS/Heroku)
JWT authentication
Minimal logging
HTTPS/WSS
Firebase FCM configured
Google Maps API with quota
```

**See SYSTEM_ARCHITECTURE.md for production setup details.**

---

## 📞 QUICK COMMAND REFERENCE

```bash
# Backend
cd peak-map-backend && python run_server.py

# Flutter (Driver)
cd peak_map_mobile && flutter run
# Then select "I'm a Driver"

# Flutter (Passenger)  
cd peak_map_mobile && flutter run -d <device_id>
# Then select "I'm a Passenger"

# Test API endpoints
curl http://127.0.0.1:8000/admin/active_rides

# Send test notification
curl -X POST http://127.0.0.1:8000/notifications/tests/ride_started/1

# Clear all data (reset database)
cd peak-map-backend && rm peakmap.db

# Install dependencies
cd peak-map-backend && pip install -r requirements.txt
cd peak_map_mobile && flutter pub get
```

---

## ✅ SUCCESS CHECKLIST

When you see these signals, the system is working:

- ✅ Backend terminal shows `Application startup complete`
- ✅ Flutter app displays home screen with "I'm a Driver" and "I'm a Passenger" buttons
- ✅ Admin dashboard shows green "Connected - Live Updates Active"
- ✅ Google Map loads in admin dashboard
- ✅ Driver app shows "📡 Live Broadcasting" status
- ✅ Passenger app shows driver marker moving on map in real-time
- ✅ Admin dashboard updates every 5 seconds
- ✅ Test notifications appear on mobile devices

All checked? 🎉 **SYSTEM IS FULLY OPERATIONAL!**

---

**Next Steps:**
- 📖 Read SYSTEM_ARCHITECTURE.md for detailed technical overview
- 🔐 Review security checklist in SYSTEM_ARCHITECTURE.md
- 🚀 Set up production deployment when ready
- 📊 Monitor system using logging & metrics

**Happy testing! 🚀**
