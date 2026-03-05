# 🚀 Quick Start: Testing Real-Time WebSockets

## ⚡ Fastest Way to See WebSockets in Action

### Option 1: Browser Test (Instant - No Mobile Setup)

1. **Start Backend:**
   ```bash
   cd peak-map-backend
   python run_server.py
   ```

2. **Open Test Page:**
   - Open `websocket_test.html` in your browser
   - Or navigate to: `file:///C:/Users/Win11/Documents/GitHub/peakmap2.0/websocket_test.html`

3. **Run Test:**
   - Click "Connect Driver" (Driver ID: 1)
   - Open **new tab** → same file → Click "Connect Passenger" (Track Driver ID: 1)
   - In Driver tab: Click "Auto GPS: OFF" → Becomes "Auto GPS: ON"
   - **Watch Passenger tab receive GPS updates every 3 seconds! 🎉**

**Expected Result:**
```
Passenger tab shows:
📍 GPS Update: Lat 14.619900, Lng 121.054000, Speed 15.23
📍 GPS Update: Lat 14.619950, Lng 121.054100, Speed 12.45
📍 GPS Update: Lat 14.620000, Lng 121.054200, Speed 18.92
```

---

### Option 2: Flutter Apps

#### Step 1: Install WebSocket Package
```bash
cd peak_map_mobile
flutter pub get
```

#### Step 2: Run Driver App
```bash
flutter run
# Select "Driver" → Enter Driver ID: 1 → Tap Play button
```

**Expected:**
- Status: "WebSocket connected - Tracking active"
- Every 5 seconds: "📡 Live broadcasting - Speed: X.X m/s"

#### Step 3: Run Passenger App (Different Device/Emulator)
```bash
flutter run -d <device_id>
# Select "Passenger" → Enter Driver ID: 1, Station: 2, Ride: 1
```

**Expected:**
- Bus marker appears on map
- Bus marker moves smoothly every 5 seconds
- No lag, updates appear instantly

---

## 🧪 Verification Steps

### 1. Check Backend Console
When driver connects:
```
✅ Driver 1 connected to WebSocket
📍 Driver 1 GPS: 14.6199, 121.0540
📍 Driver 1 GPS: 14.6200, 121.0541
```

When passenger connects:
```
✅ Passenger connected to driver 1 WebSocket
```

### 2. Check Active Connections
```bash
curl http://127.0.0.1:8000/ws/connections
```

**Response:**
```json
{
  "total_drivers": 1,
  "connections": {
    "1": 2  // 1 driver + 1 passenger
  }
}
```

### 3. Test Multiple Passengers
- Open 3 passenger apps (different devices/emulators)
- All track same driver (ID: 1)
- **All 3 should receive updates simultaneously**

Check connections:
```bash
curl http://127.0.0.1:8000/ws/connections
# Should show: "1": 4  (1 driver + 3 passengers)
```

---

## 🎯 What to Look For

### ✅ Success Indicators
- [ ] Driver status: "WebSocket connected - Tracking active"
- [ ] Passenger sees bus marker moving
- [ ] Updates appear < 1 second after driver sends
- [ ] Multiple passengers receive same data
- [ ] Backend console shows GPS coordinates
- [ ] `/ws/connections` shows correct count

### ❌ Common Issues

**Issue:** "WebSocket connection failed"
- **Check:** Backend running? (curl http://127.0.0.1:8000/)
- **Fix:** Start backend with `python run_server.py`

**Issue:** "Passenger not receiving updates"
- **Check:** Driver and passenger use same Driver ID?
- **Fix:** Verify Driver ID matches in both apps

**Issue:** "Connection drops after 60 seconds"
- **Check:** Driver sending GPS every 5 seconds?
- **Fix:** Ensure driver app is in foreground

---

## 📊 Performance Test

### Test Latency
1. Open driver app on Device A
2. Open passenger app on Device B (next to Device A)
3. Move Device A (driver) around
4. **Observe:** Passenger map updates within 500ms

### Test Scalability
1. Start 1 driver
2. Connect 10 passengers (use multiple emulators)
3. **Check:** All 10 receive updates smoothly
4. **Backend CPU:** Should be < 5% (very efficient!)

---

## 🐛 Debugging

### Enable Verbose Logging

**Backend (app/routes/ws_gps.py):**
```python
print(f"📍 Driver {driver_id} GPS: {message.get('latitude')}, {message.get('longitude')}")
# Already included! ✅
```

**Flutter (passenger_map.dart):**
```dart
print('❌ Error parsing WebSocket message: $e');
print('📩 Received GPS: $data');
// Already included! ✅
```

### Check Network Traffic
- **Chrome DevTools:**
  1. Open `websocket_test.html`
  2. Press F12 → Network tab → WS filter
  3. See WebSocket messages in real-time

---

## 🎉 Success Criteria

After testing, you should have:

✅ **Driver Broadcasting:**
- WebSocket connection established
- GPS sent every 5 seconds
- Backend logs show coordinates

✅ **Passenger Receiving:**
- Map marker moves smoothly
- No delay (< 1 second)
- Updates continue indefinitely

✅ **Multiple Passengers:**
- All receive same data
- No conflicts or dropped messages

✅ **Performance:**
- Low latency (< 500ms)
- Low CPU usage (< 5%)
- No memory leaks

---

## 📝 Quick Commands Reference

```bash
# Start backend
cd peak-map-backend
python run_server.py

# Check if backend is running
curl http://127.0.0.1:8000/

# Check active WebSocket connections
curl http://127.0.0.1:8000/ws/connections

# Install Flutter dependencies
cd peak_map_mobile
flutter pub get

# Run Flutter app
flutter run

# Run on specific device
flutter devices  # List devices
flutter run -d chrome  # Run on Chrome
flutter run -d emulator-5554  # Run on Android emulator
```

---

## 🌟 Next Steps

After confirming WebSockets work:

1. **Phase 8:** Add authentication (JWT tokens for WebSocket)
2. **Phase 9:** Admin dashboard (monitor all connections)
3. **Phase 10:** Push notifications (when driver arrives)
4. **Phase 11:** Ratings system (passenger rates driver)

---

**🎊 Once you see the bus marker moving in real-time, WebSockets are working! 🚀**

Open `websocket_test.html` now to see it in action!
