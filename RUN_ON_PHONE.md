# 📱 PEAK MAP - Running on Your Phone

The Flutter app can run on both **Android** and **iOS** devices. Here's the complete guide.

---

## ✅ **Prerequisites**

### For Any Phone:
- [ ] Flutter SDK installed (check: `flutter --version`)
- [ ] Backend server running on your computer (`python run_server.py`)
- [ ] USB cable (for physical device connection)

### For Android:
- [ ] Android SDK installed
- [ ] USB debugging enabled on your phone
- [ ] Android 5.0+ (API 21+)

### For iOS:
- [ ] macOS with Xcode installed
- [ ] iOS 11.0+
- [ ] Apple Developer account (for physical device testing)

---

## 🚀 **Method 1: Run on Android Phone (Easiest)**

### Step 1️⃣: Enable USB Debugging on Phone
```
1. Open Settings → About Phone
2. Tap "Build Number" 7 times (to enable Developer Mode)
3. Go back to Settings → Developer Options
4. Enable "USB Debugging"
5. Enable "Install via USB"
```

### Step 2️⃣: Connect Phone via USB
```powershell
# Windows PowerShell
# Connect your phone to computer via USB cable
# Grant USB debugging permission on phone screen

# Verify device is connected:
flutter devices
```

**Expected output:**
```
Android device (Android x.x)
```

### Step 3️⃣: Get Your Computer's IP Address
```powershell
# Find your computer's local network IP:
ipconfig /all

# Look for "IPv4 Address" (usually 192.168.x.x or 10.0.x.x)
# Example: 192.168.1.100
```

### Step 4️⃣: Update Backend URL in App
Edit: `peak_map_mobile/lib/services/api_service.dart`

**Find this section (around line 18):**
```dart
static String get baseUrl {
    try {
      // For web: use localhost with port 8000
      return 'http://localhost:8000';
    } catch (e) {
      // Fallback for Android emulator
      return 'http://10.0.2.2:8000';
    }
}
```

**Replace with YOUR computer's IP:**
```dart
static String get baseUrl {
    try {
      // For physical Android device: use computer's IP on network
      return 'http://192.168.1.100:8000';  // ← CHANGE THIS to your IP
    } catch (e) {
      // Fallback for Android emulator
      return 'http://10.0.2.2:8000';
    }
}
```

### Step 5️⃣: Also Update AuthService
Edit: `peak_map_mobile/lib/services/auth_service.dart`

**Find line 8:**
```dart
static const String baseUrl = 'http://127.0.0.1:8000';
```

**Replace with:**
```dart
static const String baseUrl = 'http://192.168.1.100:8000';  // ← YOUR IP
```

### Step 6️⃣: Run the App
```powershell
cd peak_map_mobile

# Build and deploy to connected phone:
flutter run

# Or with verbose output:
flutter run -v
```

**If you see:**
```
Running Gradle task 'assembleDebug'...
... (building)
Launching lib/main.dart on [Your Phone Name]
```

✅ **Success!** App is installing on your phone. Wait for it to launch.

---

## 📱 **Method 2: Run on Android Emulator**

### Step 1️⃣: Open Android Emulator
```powershell
# List available virtual devices:
flutter emulators

# Run emulator:
flutter emulators --launch <emulator_name>

# Example:
flutter emulators --launch Pixel_4_API_31
```

### Step 2️⃣: Verify Emulator is Ready
```powershell
# Wait for emulator to start, then:
flutter devices

# Should show Android emulator
```

### Step 3️⃣: No IP Changes Needed!
The emulator can access `http://10.0.2.2:8000` directly.
The app already has this fallback in `api_service.dart`.

### Step 4️⃣: Run the App
```powershell
cd peak_map_mobile
flutter run
```

---

## 🍎 **Method 3: Run on iOS Phone (Mac Only)**

### Step 1️⃣: Connect iPhone via USB

### Step 2️⃣: Update Backend URL
Edit: `peak_map_mobile/lib/services/api_service.dart`

```dart
static String get baseUrl {
    try {
      // For iOS physical device: use computer's local network IP
      return 'http://192.168.1.100:8000';  // ← YOUR COMPUTER'S IP
    } catch (e) {
      return 'http://127.0.0.1:8000';
    }
}
```

Also update `auth_service.dart`:
```dart
static const String baseUrl = 'http://192.168.1.100:8000';
```

### Step 3️⃣: Build and Run
```bash
cd peak_map_mobile
flutter run -d ios
```

### Step 4️⃣: Trust Developer App
On iPhone, go to: **Settings → General → VPN & Device Management** → Trust the developer profile

---

## 🧪 **Testing the App on Your Phone**

### Test as Driver:
1. Launch app
2. Tap "I'm a Driver" button
3. Select your driver ID (default: Driver 1)
4. GPS tracking starts automatically ✅
5. Watch your location appear on the map in real-time

### Test as Passenger:
1. Launch app
2. Tap "I'm a Passenger" button
3. View live bus positions on map ✅
4. See ETA updates as buses move

### Verify Backend Connection:
Watch for these indicators:
- ✅ GPS location appears on map
- ✅ Real-time position updates (every 5 seconds)
- ✅ Alerts/notifications display
- ✅ No red error messages

---

## 🔍 **Troubleshooting**

### ❌ App crashes on launch
**Problem:** Backend connection failed
**Solution:**
```powershell
# 1. Verify backend is running:
curl http://192.168.1.100:8000/docs

# 2. Check IP address is correct:
ipconfig /all

# 3. Ensure phone and computer are on SAME WiFi network
```

### ❌ "Cannot connect to backend"
**Check:**
1. Backend server is running (`python run_server.py` in terminal)
2. IP address is correct in `api_service.dart`
3. Phone and computer on same WiFi
4. Firewall not blocking port 8000

### ❌ GPS not updating
**Solution:**
1. Grant location permission when app asks
2. Enable "Always" or "While Using" location access
3. Wait 5-10 seconds for first update
4. Check backend GPS endpoint: `http://192.168.1.100:8000/gps/latest/1`

### ❌ Build errors
```powershell
# Clean and rebuild:
cd peak_map_mobile
flutter clean
flutter pub get
flutter run
```

### ❌ "Phone not detected"
```powershell
# Check connection:
flutter devices

# If not showing:
# 1. Reconnect USB cable
# 2. Grant USB debugging permission on phone
# 3. Restart ADB:
adb kill-server
adb devices
```

---

## 📊 **Find Your Computer's IP Address**

### Windows:
```powershell
ipconfig

# Look for "IPv4 Address" line
# Usually something like: 192.168.1.100
```

### Required for Phone:
- **Same WiFi network** as the computer (VERY IMPORTANT!)
- Computer and phone must be able to "see" each other on the network

---

## 📋 **Quick Checklist**

- [ ] Backend server running (`python run_server.py`)
- [ ] Phone connected via USB cable
- [ ] USB debugging enabled on phone
- [ ] Phone and computer on **SAME WiFi**
- [ ] Updated `api_service.dart` with your computer's IP
- [ ] Updated `auth_service.dart` with your computer's IP
- [ ] Ran `flutter run`
- [ ] Granted location permission to app
- [ ] Backend GPS endpoint accessible from phone

---

## 🎯 **What Happens When You Run It**

### First Launch:
1. App opens with role selection (Driver/Passenger)
2. Selects user role
3. App requests location permission → **GRANT IT**
4. Map loads with your phone's location
5. GPS tracking begins

### Real-Time Features:
- ✅ Your location updates every 5 seconds (Driver) or on demand (Passenger)
- ✅ See other drivers/passengers on map
- ✅ Receive push notifications (Firebase FCM)
- ✅ View live ETA calculations
- ✅ See ride status updates

---

## 🚀 **Next Steps**

Once app is running on your phone:

1. **Test Driver Mode:**
   - Open as driver
   - Watch location update in real-time
   - View on admin dashboard concurrently

2. **Test Passenger Mode:**
   - Open app as passenger
   - See drivers near you
   - Track a specific bus

3. **Monitor on Admin Dashboard:**
   - Open `admin_dashboard.html` in browser
   - See your phone's location live on the map
   - Verify data syncing works end-to-end

---

## 📞 **If You Still Can't Connect**

### Debug Steps:
```powershell
# 1. Test backend directly from phone's browser:
# Open: http://192.168.1.100:8000/docs
# Should see Swagger UI

# 2. Test from computer:
# Open: http://localhost:8000/docs
# Should work

# 3. Check network connectivity:
ping 192.168.1.100  # from phone WiFi settings

# 4. Monitor backend requests:
# Run backend with: python run_server.py -v
# Watch for incoming requests from your phone
```

---

**You're all set! 🎉 Enjoy testing PEAK MAP on your phone!**

For more help, check `HOW_TO_RUN.md` or `SYSTEM_ARCHITECTURE.md`
