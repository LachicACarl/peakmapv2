# 📱 Build APK for PEAK MAP Mobile App

**Status:** ⚠️ Android SDK Setup Required

---

## Current Situation

✅ **Backend Running:** http://127.0.0.1:8001  
✅ **Flutter Installed:** Ready  
✅ **Android Studio Installed:** C:\Program Files\Android\Android Studio  
❌ **Android SDK:** Not configured yet

---

## Option 1: Setup Android SDK (Recommended - 10 minutes)

### Step 1: Open Android Studio

```powershell
# Launch Android Studio
Start-Process "C:\Program Files\Android\Android Studio\bin\studio64.exe"
```

### Step 2: Install Android SDK

1. Android Studio will open
2. Go to: **Tools → SDK Manager** (or **Configure → SDK Manager** on welcome screen)
3. In **SDK Platforms** tab:
   - ✅ Check **Android 13.0 (Tiramisu)** or latest
   - ✅ Check **Android 12.0 (S)** (recommended for compatibility)
4. In **SDK Tools** tab, check:
   - ✅ Android SDK Build-Tools
   - ✅ Android SDK Command-line Tools
   - ✅ Android SDK Platform-Tools
   - ✅ Android Emulator (optional)
5. Click **Apply** → Wait for download (5-10 minutes)
6. Click **OK** when done

### Step 3: Set Environment Variables

```powershell
# Add to your PowerShell profile or run each time:
$env:ANDROID_HOME = "C:\Users\User\AppData\Local\Android\Sdk"
$env:ANDROID_SDK_ROOT = "C:\Users\User\AppData\Local\Android\Sdk"
$env:PATH = "$env:ANDROID_HOME\platform-tools;$env:ANDROID_HOME\tools;$env:PATH"

# Make permanent (requires admin):
[System.Environment]::SetEnvironmentVariable('ANDROID_HOME', 'C:\Users\User\AppData\Local\Android\Sdk', 'User')
[System.Environment]::SetEnvironmentVariable('ANDROID_SDK_ROOT', 'C:\Users\User\AppData\Local\Android\Sdk', 'User')
```

### Step 4: Build APK

```powershell
# Set SDK path
$env:ANDROID_HOME = "C:\Users\User\AppData\Local\Android\Sdk"
$env:ANDROID_SDK_ROOT = "C:\Users\User\AppData\Local\Android\Sdk"

# Navigate to Flutter project
cd C:\Users\User\Documents\peakmapv2\peak_map_mobile

# Build APK
& "C:\Users\User\flutter_clean\flutter\bin\flutter.bat" build apk --release

# APK will be at:
# C:\Users\User\Documents\peakmapv2\peak_map_mobile\build\app\outputs\flutter-apk\app-release.apk
```

---

## Option 2: Use Flutter Web on Phone (Fastest - 2 minutes)

Instead of building an APK, run the Flutter web version and access it from your phone browser!

### Step 1: Start Flutter Web Server

```powershell
cd C:\Users\User\Documents\peakmapv2\peak_map_mobile

# Get your local IP
$localIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -like '*Wi-Fi*' -or $_.InterfaceAlias -like '*Ethernet*'} | Select-Object -First 1).IPAddress
Write-Output "Your IP: $localIP"

# Start Flutter web on port 8080 (accessible from phone)
& "C:\Users\User\flutter_clean\flutter\bin\flutter.bat" run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

### Step 2: Update Backend to Accept Phone Connections

```powershell
# Backend is running on 127.0.0.1:8001 (localhost only)
# Need to restart on 0.0.0.0:8001 to accept connections from phone

# Stop current backend (if running)
Get-Process | Where-Object {$_.CommandLine -like '*uvicorn*'} | Stop-Process -Force

# Start backend accessible from network
cd C:\Users\User\Documents\peakmapv2\peak-map-backend
& "C:\Users\User\Documents\peakmapv2\.venv312\Scripts\python.exe" -m uvicorn app.main:app --host 0.0.0.0 --port 8001 --reload
```

### Step 3: Access from Phone

1. Make sure phone and PC are on same Wi-Fi network
2. Get your PC's IP address (shown in Step 1)
3. On your phone browser, open:
   ```
   http://YOUR_PC_IP:8080
   ```
   Example: `http://192.168.1.100:8080`

---

## Option 3: Build via Android Studio (Alternative)

### Step 1: Open Project in Android Studio

```powershell
# Open Android Studio with the Flutter project
Start-Process "C:\Program Files\Android\Android Studio\bin\studio64.exe" -ArgumentList "C:\Users\User\Documents\peakmapv2\peak_map_mobile\android"
```

### Step 2: Build APK in Android Studio

1. Wait for Gradle sync to complete
2. Go to: **Build → Build Bundle(s) / APK(s) → Build APK(s)**
3. Wait for build (5-10 minutes)
4. APK will be at: `app\build\outputs\apk\release\app-release.apk`

---

## Option 4: Quick Test with Debug APK (Faster Build)

Debug APK builds faster than release APK. Good for testing:

```powershell
# Set SDK path
$env:ANDROID_HOME = "C:\Users\User\AppData\Local\Android\Sdk"

# Build debug APK (faster, ~3-5 minutes)
cd C:\Users\User\Documents\peakmapv2\peak_map_mobile
& "C:\Users\User\flutter_clean\flutter\bin\flutter.bat" build apk --debug

# APK location:
# build\app\outputs\flutter-apk\app-debug.apk
```

---

## Transferring APK to Phone

Once you have the APK:

### Method 1: USB Cable
```powershell
# Copy to phone storage
Copy-Item "build\app\outputs\flutter-apk\app-release.apk" -Destination "E:\Downloads\" 
# (E: is your phone drive when connected)
```

### Method 2: Cloud Upload
Upload to Google Drive, Dropbox, or OneDrive, then download on phone

### Method 3: Email
Email the APK to yourself

### Method 4: Local Web Server
```powershell
# Serve APK via web server
cd C:\Users\User\Documents\peakmapv2\peak_map_mobile\build\app\outputs\flutter-apk
python -m http.server 8888

# Download on phone from: http://YOUR_PC_IP:8888/app-release.apk
```

---

## Installing APK on Phone

1. **Enable Unknown Sources:**
   - Settings → Security → Unknown Sources (enable)
   - Or: Settings → Apps → Special Access → Install Unknown Apps → Enable for your file manager

2. **Install APK:**
   - Open file manager on phone
   - Navigate to Downloads folder
   - Tap the APK file
   - Tap "Install"
   - Tap "Open" when done

---

## Troubleshooting

### "SDK Not Found" Error
- Install Android SDK via Android Studio SDK Manager
- Set `ANDROID_HOME` environment variable
- Restart PowerShell terminal

### "License Not Accepted" Error
```powershell
# Accept Android licenses
& "C:\Users\User\AppData\Local\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat" --licenses
```

### Build Fails
```powershell
# Clean Flutter build cache
cd C:\Users\User\Documents\peakmapv2\peak_map_mobile
& "C:\Users\User\flutter_clean\flutter\bin\flutter.bat" clean
& "C:\Users\User\flutter_clean\flutter\bin\flutter.bat" pub get

# Try again
& "C:\Users\User\flutter_clean\flutter\bin\flutter.bat" build apk --release
```

### Can't Connect to Backend from Phone
- Make sure PC firewall allows connections on port 8001
- Backend must be started with `--host 0.0.0.0` not `127.0.0.1`
- Phone and PC must be on same Wi-Fi network

---

## Quick Commands Summary

```powershell
# 1. Start Backend (accessible from network)
cd C:\Users\User\Documents\peakmapv2\peak-map-backend
& "C:\Users\User\Documents\peakmapv2\.venv312\Scripts\python.exe" -m uvicorn app.main:app --host 0.0.0.0 --port 8001 --reload

# 2. Set Android SDK
$env:ANDROID_HOME = "C:\Users\User\AppData\Local\Android\Sdk"
$env:ANDROID_SDK_ROOT = "C:\Users\User\AppData\Local\Android\Sdk"

# 3. Build APK
cd C:\Users\User\Documents\peakmapv2\peak_map_mobile
& "C:\Users\User\flutter_clean\flutter\bin\flutter.bat" build apk --release

# 4. APK Location
Get-Item "C:\Users\User\Documents\peakmapv2\peak_map_mobile\build\app\outputs\flutter-apk\app-release.apk"
```

---

## Recommended Path

**For immediate testing:** Use **Option 2 (Flutter Web)** - Access from phone browser  
**For permanent install:** Use **Option 1 (Build APK)** - After SDK setup

**Estimated Time:**
- Option 1 (Build APK): 10-15 minutes (first time with SDK setup)
- Option 2 (Flutter Web): 2 minutes
- Option 3 (Android Studio): 15-20 minutes
- Option 4 (Debug APK): 5-8 minutes

---

*Created: March 9, 2026*  
*Status: Waiting for Android SDK setup*
