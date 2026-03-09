@echo off
setlocal
REM PEAK MAP - Admin Dashboard Startup Script
REM This script starts the backend server and opens the admin dashboard

set "ROOT=%~dp0"
set "BACKEND_DIR=%ROOT%peak-map-backend"
set "PYTHON_EXE=%ROOT%.venv312\Scripts\python.exe"

echo ========================================
echo  PEAK MAP - Admin Dashboard Startup
echo ========================================
echo.

echo [1/3] Validating Python environment...
if exist "%PYTHON_EXE%" (
	echo Using venv Python: %PYTHON_EXE%
) else (
	echo WARNING: %PYTHON_EXE% not found. Falling back to system python.
	set "PYTHON_EXE=python"
)

echo.
echo [2/3] Starting backend server...
echo Backend will run on: http://127.0.0.1:8000
echo.

start "PEAK MAP Backend" cmd /k "cd /d \"%BACKEND_DIR%\" && \"%PYTHON_EXE%\" run_server.py"

echo.
echo [3/3] Opening admin dashboard...
timeout /t 3 /nobreak > nul

start "" "%ROOT%admin_dashboard.html"

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
