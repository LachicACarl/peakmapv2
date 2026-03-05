@echo off
REM PEAK MAP - Admin Dashboard Startup Script
REM This script starts the backend server and opens the admin dashboard

echo ========================================
echo  PEAK MAP - Admin Dashboard Startup
echo ========================================
echo.

echo [1/3] Activating virtual environment...
call .venv\Scripts\activate.bat

echo.
echo [2/3] Starting backend server...
echo Backend will run on: http://127.0.0.1:8000
echo.

cd peak-map-backend
start "PEAK MAP Backend" cmd /k "..\\.venv\\Scripts\\python.exe run_server.py"

echo.
echo [3/3] Opening admin dashboard...
timeout /t 3 /nobreak > nul

start "" "admin_dashboard.html"

echo.
echo ========================================
echo  Admin Dashboard is now running!
echo ========================================
echo.
echo Backend: http://127.0.0.1:8000
echo Dashboard: admin_dashboard.html (opened in browser)
echo API Docs: http://127.0.0.1:8000/docs
echo.
echo Press Enter to keep this window open...
echo To stop the backend, close the "PEAK MAP Backend" window
echo.
pause
