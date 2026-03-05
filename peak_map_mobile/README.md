# PEAK MAP Mobile - Flutter App

Live GPS tracking mobile application for EDSA bus passengers and drivers.

## Features

### Driver App
- ✅ Real-time GPS tracking (updates every 5 seconds)
- ✅ Live map display with current location
- ✅ Automatic location broadcast to backend
- ✅ Speed tracking
- ✅ Start/stop tracking controls

### Passenger App  
- ✅ Live bus tracking on map
- ✅ Real-time ETA updates
- ✅ Distance to destination
- ✅ Automatic drop-off detection
- ✅ Missed stop alerts
- ✅ Traffic-aware calculations

## Setup Instructions

### 1. Install Flutter

Download and install Flutter SDK from: https://flutter.dev/docs/get-started/install

Verify installation:
```bash
flutter doctor
```

### 2. Install Dependencies

```bash
cd peak_map_mobile
flutter pub get
```

### 3. Configure Google Maps API

#### Get API Key
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable these APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Distance Matrix API
   - Directions API
4. Create credentials → API Key

#### Add API Key to Android

Edit `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ACTUAL_API_KEY_HERE"/>
```

#### Add API Key to iOS

Edit `ios/Runner/AppDelegate.swift`:
```swift
GMSServices.provideAPIKey("YOUR_ACTUAL_API_KEY_HERE")
```

### 4. Configure Backend URL

Edit `lib/services/api_service.dart`:
```dart
static const String baseUrl = "http://YOUR_BACKEND_URL";
```

**For local development:**
- Android Emulator: `http://10.0.2.2:8000`
- iOS Simulator: `http://localhost:8000`
- Real device: `http://YOUR_COMPUTER_IP:8000`

### 5. Run the App

#### Android
```bash
flutter run
```

#### iOS (Mac only)
```bash
cd ios
pod install
cd ..
flutter run
```

## Project Structure

```
peak_map_mobile/
├── lib/
│   ├── main.dart                    # App entry point & home screen
│   ├── services/
│   │   └── api_service.dart        # Backend API calls
│   ├── driver/
│   │   └── driver_map.dart         # Driver GPS tracking screen
│   └── passenger/
│       └── passenger_map.dart      # Passenger bus tracking screen
├── android/                         # Android configuration
├── ios/                            # iOS configuration
└── pubspec.yaml                    # Dependencies
```

## Dependencies

- `google_maps_flutter` - Google Maps integration
- `geolocator` - GPS location services
- `http` - API communication
- `qr_code_scanner` - QR code scanning
- `qr_flutter` - QR code generation
- `provider` - State management

## How It Works

### Driver Flow
1. Open app → Select "I'm a Driver"
2. GPS tracking starts automatically
3. Location sent to backend every 5 seconds
4. Driver sees their position on map

### Passenger Flow
1. Open app → Select "I'm a Passenger"
2. See bus location on map
3. ETA updates automatically every 5 seconds
4. Get notified when:
   - Approaching station
   - Arrived at station
   - Missed the stop

## API Endpoints Used

- `POST /gps/update` - Send driver GPS
- `GET /gps/latest/{driver_id}` - Get driver location
- `GET /eta/` - Get ETA to station
- `POST /rides/check/{ride_id}` - Check drop-off status

## Permissions Required

### Android
- `ACCESS_FINE_LOCATION` - Precise GPS
- `ACCESS_COARSE_LOCATION` - Approximate location
- `INTERNET` - API communication
- `ACCESS_BACKGROUND_LOCATION` - Background tracking

### iOS
- Location When In Use
- Location Always (for background tracking)
- Camera (for QR scanning)

## Testing

### Test Driver GPS
1. Run driver app
2. Grant location permissions
3. Move around (or use location simulation)
4. Check backend receives GPS updates

### Test Passenger Tracking
1. Start driver app (sends GPS)
2. Run passenger app
3. Should see bus marker moving
4. ETA should update every 5 seconds

## Troubleshooting

### Maps not showing
- Verify Google Maps API key is correct
- Check API is enabled in Google Cloud Console
- Ensure billing is enabled on Google Cloud

### GPS not working
- Check location permissions are granted
- Enable location services on device
- For emulator, use location simulation

### Backend connection failed
- Verify backend URL in `api_service.dart`
- Check backend is running
- For real device, ensure same network

## Next Steps (TODO)

- [ ] Add authentication (login/signup)
- [ ] Integrate QR code pairing
- [ ] Add station selection UI
- [ ] Implement ride history
- [ ] Add payment integration
- [ ] Push notifications for alerts
- [ ] Offline mode support

## License

This project is part of the PEAK MAP thesis project.
