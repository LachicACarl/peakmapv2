# ETA Live Validation Runbook

Use this to capture `ETA vs actual arrival` evidence for your capstone demo.

## 1. Start backend

Run from workspace root:

```powershell
$env:DATABASE_URL = 'sqlite:///C:/Users/Win11/Documents/GitHub/peakmapv2/peak-map-backend/peakmap.db'
C:/Users/Win11/AppData/Local/Python/pythoncore-3.14-64/python.exe C:/Users/Win11/Documents/GitHub/peakmapv2/peak-map-backend/run_server.py
```

## 2. Identify trip target

Choose:

- `driver_id` (the live driver on phone)
- `station_id` (destination station for validation)

Example destination:

- `station_id=10` (`Main Avenue (Cubao)`)

## 3. Run live capture

Open a second terminal and run:

```powershell
cd C:/Users/Win11/Documents/GitHub/peakmapv2/peak-map-backend
C:/Users/Win11/AppData/Local/Python/pythoncore-3.14-64/python.exe eta_trip_validator.py --driver-id 1 --station-id 10 --base-url http://192.168.5.32:8000 --max-minutes 45 --interval-seconds 5
```

Notes:

- Keep this running for the full live trip.
- The script auto-detects arrival by geofence and ETA state.
- It writes both CSV and JSON reports.

## 4. Output files

Generated in:

- `peak-map-backend/eta_validation_reports/`

Per run:

- `eta_validation_driver<id>_station<id>_<timestamp>.csv`
- `eta_validation_driver<id>_station<id>_<timestamp>.json`

## 5. Metrics to present

From JSON `result` section:

- `first_eta_minutes`
- `actual_arrival_seconds`
- `initial_prediction_error_seconds`
- `mae_seconds`

Interpretation:

- `initial_prediction_error_seconds > 0`: ETA initially over-estimated travel time.
- `initial_prediction_error_seconds < 0`: ETA initially under-estimated travel time.
- Lower `mae_seconds` means more stable ETA quality through the trip.

## 6. Demo evidence checklist

Capture these in video/screenshots:

1. Passenger screen showing ETA/stops progression at trip start.
2. Validator terminal sampling lines during trip.
3. Arrival moment (station reached).
4. Final JSON report with error metrics.
5. CSV opened (optional chart in Excel: elapsed seconds vs ETA minutes).

## 7. Fast sanity test (optional)

Short test only (not a real trip):

```powershell
cd C:/Users/Win11/Documents/GitHub/peakmapv2/peak-map-backend
C:/Users/Win11/AppData/Local/Python/pythoncore-3.14-64/python.exe eta_trip_validator.py --driver-id 1 --station-id 10 --base-url http://192.168.5.32:8000 --max-minutes 0.2 --interval-seconds 4
```
