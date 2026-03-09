# CORS Error Fix - Port Change to 8001 ✅

## What Was Fixed

### Issue
1. **CORS errors** - Backend wasn't allowing requests from `file://` protocol (origin: 'null')
2. **Zombie processes on port 8000** - PIDs 12404, 8916, 25080 wouldn't die

### Solution
1. ✅ **Added `"null"` to CORS allowed origins** - Now works with file:// protocol
2. ✅ **Changed backend port from 8000 → 8001** - Avoids zombie process conflicts
3. ✅ **Updated admin_dashboard.html** - Now connects to port 8001
4. ✅ **Updated run_server.py** - Defaults to port 8001 with auto-reload

## Current Status

🟢 **Backend is running on port 8001**

Test it:
```powershell
# Test API
Invoke-RestMethod http://127.0.0.1:8001/

# Test Admin Endpoint
Invoke-RestMethod http://127.0.0.1:8001/admin/dashboard_overview
```

## How to Use Now

### Option 1: Double-click HTML (file:// protocol) ✅ WORKING NOW
Just open: `admin_dashboard.html` directly in browser
- CORS now allows file:// protocol
- Connects to backend at port 8001

### Option 2: Run backend manually
```powershell
cd c:\Users\User\Documents\peakmapv2\peak-map-backend
& "c:\Users\User\Documents\peakmapv2\.venv312\Scripts\python.exe" run_server.py
```

### Option 3: Use the batch file
Double-click: `start_backend_8001.bat`

## What Changed

### Files Modified:
1. **peak-map-backend/app/main.py**
   - Added `"null"` to CORS `allow_origins` for file:// protocol support

2. **admin_dashboard.html**
   - Changed: `API_BASE = ...8000` → `...8001`
   - Changed: `WS_URL = ...8000` → `...8001`

3. **peak-map-backend/run_server.py**
   - Changed: `port=8000` → `port=8001`
   - Added: `reload=True` for auto-reload
   - Added: Helpful startup messages

### Files Created:
- `start_backend_8001.bat` - Quick start script

## Verification

✅ Backend running: http://127.0.0.1:8001
✅ API responding: `{"status":"PEAK MAP backend running"}`
✅ Admin endpoints working: `/admin/dashboard_overview`
✅ CORS configured: Allows `null` origin

## Next Steps

1. **Refresh your browser** (Ctrl+Shift+R)
2. The CORS errors should be gone
3. Dashboard should load data successfully

## Note About Port 8000

Port 8000 still has zombie processes that won't die:
- PID 12404
- PID 8916  
- PID 25080

**To clean them up:**
- Restart your computer, OR
- Wait a few hours for Windows to clean up, OR
- Just keep using port 8001 (recommended ✅)

## Future Runs

From now on:
- Backend will start on **port 8001** by default
- Admin dashboard is configured for **port 8001**
- No more port conflicts!

Enjoy your working dashboard! 🎉
