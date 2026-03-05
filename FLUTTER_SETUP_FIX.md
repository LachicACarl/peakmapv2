# 🔧 FLUTTER SETUP FIX - Windows PowerShell

## Problem
```
flutter : The term 'flutter' is not recognized
```

This means Flutter SDK is either not installed or not added to your system PATH.

---

## ✅ SOLUTION

### Step 1: Check if Flutter is Installed

```powershell
# Check if Flutter exists anywhere
Get-Command flutter -ErrorAction SilentlyContinue
```

If nothing appears, Flutter is not installed.

### Step 2: Download & Install Flutter

**Option A: Automatic (Recommended)**

If you have **Chocolatey** installed:
```powershell
choco install flutter
```

**Option B: Manual Download**

1. Go to [Flutter Downloads](https://flutter.dev/docs/get-started/install/windows)
2. Download the latest Windows release (flutter_windows_x.x.x-stable.zip)
3. Extract to a folder like: `C:\src\flutter`
4. Keep the path without spaces (important!)

### Step 3: Add Flutter to System PATH

**Method 1: Using PowerShell (Recommended)**

```powershell
# Run PowerShell as Administrator
# Then run this command:

$flutterPath = "C:\src\flutter\bin"
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($currentPath -notlike "*$flutterPath*") {
    [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$flutterPath", "User")
    Write-Host "✅ Flutter added to PATH"
} else {
    Write-Host "✅ Flutter already in PATH"
}
```

**Method 2: Manual (GUI)**

1. Open **Settings** → **System** → **Advanced system settings**
2. Click **Environment Variables** button
3. Under "User variables", click **New**
4. Variable name: `PATH`
5. Variable value: `C:\src\flutter\bin` (adjust path to where you extracted Flutter)
6. Click **OK** three times
7. **Restart PowerShell**

### Step 4: Verify Installation

```powershell
flutter --version
```

**Expected output:**
```
Flutter 3.16.0 • channel stable
Dart 3.2.0
```

If you see this, Flutter is installed! ✅

### Step 5: Run Flutter Doctor

```powershell
flutter doctor
```

**Expected output includes:**
```
✓ Flutter (Channel stable, ...)
✓ Windows Version (...)
✓ Android toolchain (...)
✓ Chrome - ...
✓ Android Studio - ...
✓ VS Code (...)
```

Some items may have warnings ⚠️ - that's OK. As long as no ❌ errors, you're good.

---

## 🚀 NOW RUN THE APP

### Terminal 1: Backend

```powershell
cd peak-map-backend
python run_server.py
```

Wait for: `Application startup complete`

### Terminal 2: Flutter App

```powershell
cd peak_map_mobile
flutter pub get
flutter run
```

**Choose device from the prompt:**
```
? Which device do you want to target?
[1] Android Emulator (emulator-5554)
[2] Windows (desktop)
```

Select option `[1]` for Android Emulator (or `[2]` for Windows Desktop)

---

## ❌ STILL NOT WORKING?

### Issue: "Flutter not found after restart"

**Solution:**
1. Close ALL PowerShell windows
2. Open a NEW PowerShell window
3. Try `flutter --version` again

### Issue: "Multiple versions of Flutter"

**Solution:**
```powershell
# Find all Flutter installs
Get-Command flutter -All

# Remove old one and keep only the latest
```

### Issue: "Android SDK not found"

**Solution:**
```powershell
# Let Flutter set it up automatically
flutter doctor --android-licenses
# Say 'y' to all prompts
```

### Issue: "No supported devices found"

**Solution:**
1. Start Android Emulator first:
   - Open Android Studio
   - Click **Virtual Device Manager**
   - Click **Play** on any device
2. Then run `flutter devices` to see it

### Issue: PATH changes not taking effect

**Solution:**
```powershell
# Restart PowerShell completely
# Or run:
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")
flutter --version
```

---

## 🎯 CORRECT COMMAND SYNTAX

### WRONG ❌
```powershell
flutter run& C:\path\activate.ps1    # Wrong - ampersand error
flutter pub get && python run.py     # Wrong - mixing commands
```

### CORRECT ✅
```powershell
# Run separately in different terminals
flutter pub get
flutter run

# Or chain with semicolon
flutter pub get ; flutter run
```

---

## 📋 QUICK CHECKLIST

```
☑️  Flutter installed: flutter --version
☑️  Dart installed: dart --version
☑️  Android Emulator running (or iOS Simulator)
☑️  Backend running: http://127.0.0.1:8000
☑️  In peak_map_mobile directory
☑️  Run: flutter pub get
☑️  Run: flutter run
```

All checked? 🎉 **APP LAUNCHING NOW!**

---

## 🌐 Useful Flutter Commands

```powershell
# Check everything
flutter doctor

# Update Flutter
flutter upgrade

# List devices
flutter devices

# Run on specific device
flutter run -d emulator-5554

# Run in release mode (faster)
flutter run --release

# Clean build
flutter clean
flutter pub get
flutter run

# View logs
flutter logs

# Stop app
# Press 'q' in the terminal
```

---

## 💡 Pro Tips

**1. Make Flutter easier to access:**
```powershell
# Add this to your PowerShell profile
# Edit: $PROFILE
alias fl='flutter'
alias flr='flutter run'
alias flg='flutter pub get'
```

**2. Use VS Code for Flutter:**
- Install "Flutter" extension
- Press `Ctrl+Shift+D` to run
- Much easier interface!

**3. Clean slate if broken:**
```powershell
flutter clean
rm -r .dart_tool
rm pubspec.lock
flutter pub get
flutter run
```

**4. Update dependencies:**
```powershell
flutter pub upgrade
```

---

## ✅ FINAL TEST

Once everything is set up:

```powershell
# Terminal 1
cd peak-map-backend
python run_server.py

# Terminal 2
cd peak_map_mobile
flutter run
```

You should see:
```
✅ Launching build...
✅ Build complete
✅ Installing and launching the app on emulator...
[PEAK MAP home screen appears on device]
```

🎉 **SUCCESS!**

---

**If you're still stuck, reply with the exact error message and I'll help debug!**
