@echo off
REM Official Backend Start Script for PEAK MAP
REM Backend runs on PORT 8001 (Port 8000 has zombie processes that won't die)

echo ============================================
echo PEAK MAP Backend Server (PORT 8001)
echo ============================================
echo.
echo Starting backend on port 8001...
echo API will be available at: http://127.0.0.1:8001
echo API Docs: http://127.0.0.1:8001/docs
echo.
echo Press Ctrl+C to stop the server
echo.

cd /d "%~dp0peak-map-backend"
"%~dp0.venv312\Scripts\python.exe" run_server.py

pause
