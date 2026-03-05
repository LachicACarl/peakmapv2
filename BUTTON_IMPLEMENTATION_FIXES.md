# 🎯 BUTTON IMPLEMENTATION FIXES & COMPLETIONS

## Priority 1: CRITICAL FIXES (Must implement immediately)

### 1. Driver Dashboard - "Accept Passengers" Toggle
**Current Issue**: Toggle exists but doesn't send to backend

**Location**: `lib/driver/driver_dashboard.dart` (line ~100)

**Required Changes**:
```dart
// ADD THIS METHOD
Future<void> _updateDriverStatus(bool isOnline) async {
  setState(() => _isOnline = isOnline);
  
  try {
    final response = await ApiService.updateDriverStatus(
      driverId: widget.driverId,
      isOnline: isOnline,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isOnline ? 'You are now ONLINE' : 'You are now OFFLINE'),
        backgroundColor: isOnline ? Colors.green : Colors.orange,
      ),
    );
  } catch (e) {
    setState(() => _isOnline = !isOnline); // Revert on error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
    );
  }
}

// UPDATE THE SWITCH
Switch(
  value: _isOnline,
  onChanged: _updateDriverStatus, // Call method instead of setState
  activeColor: const Color(0xFF4CAF50),
)
```

**Backend API Required**:
```
PUT /drivers/{driver_id}/status
Request: {"is_online": true}
Response: {"status": "updated", "is_online": true}
```

---

### 2. Driver Dashboard - "View Alerts" Card
**Current Issue**: Card exists but no onTap handler

**Location**: `lib/driver/driver_dashboard.dart` (around line ~180)

**Required Implementation**:
```dart
// ADD NAVIGATION
onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => DriverAlerts(driverId: widget.driverId),
    ),
  );
},
```

---

### 3. Driver Dashboard - "View All Trips"  Button
**Current Issue**: Button likely exists but goes nowhere

**Find and Add**:
```dart
ElevatedButton(
  onPressed: () {
    // Navigate to DriverRoutes
    Navigator.of(context).pushNamed('/driver-routes');
  },
  child: const Text('View all trips'),
)
```

---

### 4. Passenger Dashboard - "Search Station" Button
**Current Issue**: Missing implementation

**Required Implementation**:
```dart
ElevatedButton(
  onPressed: _showStationPicker,
  child: const Text('Search Bus Route'),
)

Future<void> _showStationPicker() async {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Select Departure Station'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Cubao'),
              onTap: () => _selectStation(1, 'Cubao'),
            ),
            ListTile(
              title: const Text('Ayala'),
              onTap: () => _selectStation(2, 'Ayala'),
            ),
            ListTile(
              title: const Text('Legaspi'),
              onTap: () => _selectStation(3, 'Legaspi'),
            ),
          ],
        ),
      ),
    ),
  );
}
```

---

### 5. Passenger Dashboard - "Track Bus" Button
**Current Issue**: Missing implementation

**Required Implementation**:
```dart
ElevatedButton(
  onPressed: _startTrackingBus,
  child: const Text('Track Bus'),
)

Future<void> _startTrackingBus() async {
  if (_selectedStationId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select a station first')),
    );
    return;
  }

  try {
    // Create a ride
    final result = await ApiService.createRide(
      passengerId: widget.passengerId,
      stationId: _selectedStationId!,
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PassengerMapScreen(
            driverId: result['driver_id'],
            stationId: _selectedStationId!,
            rideId: result['ride_id'],
          ),
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
```

---

## Priority 2: IMPORTANT FEATURES (Should implement soon)

### 6. Login - "Sign Up" Buttons
**Location**: `lib/auth/login_screen.dart`

**Implementation**:
```dart
TextButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterScreen(
          userType: widget.userType,
        ),
      ),
    );
  },
  child: const Text("Don't have an account? Sign Up"),
)
```

---

### 7. Driver Routes - View Selector Buttons
**Location**: `lib/driver/driver_routes.dart` (line ~100)

**Status**: Already implemented! ✅
```dart
GestureDetector(
  onTap: () {
    setState(() {
      _selectedView = label;
    });
  },
  // ...
)
```

---

## Priority 3: ENHANCEMENT FEATURES (Nice to have)

### 8. Driver Map - "Start/Stop Tracking" Button States
**Current**: Likely just shows status

**Enhancement**:
```dart
ElevatedButton(
  onPressed: _isTracking ? _stopTracking : _startTracking,
  style: ElevatedButton.styleFrom(
    backgroundColor: _isTracking ? Colors.red : Colors.green,
  ),
  child: Text(_isTracking ? 'Stop Broadcasting' : 'Start Broadcasting'),
)
```

---

### 9. Passenger Map - "Call Driver" Button (Future)
```dart
FloatingActionButton(
  onPressed: _callDriver,
  backgroundColor: Colors.blue,
  child: const Icon(Icons.call),
)

Future<void> _callDriver() async {
  // Future implementation for calling driver
}
```

---

### 10. Payment Screen - "View Receipt" Button (Future)
```dart
ElevatedButton(
  onPressed: _viewReceipt,
  child: const Text('View Receipt'),
)

Future<void> _viewReceipt() async {
  // Generate and show receipt
}
```

---

## API SERVICE METHODS NEEDED

Add these to `lib/services/api_service.dart`:

```dart
// Update driver online status
static Future<Map<String, dynamic>> updateDriverStatus({
  required int driverId,
  required bool isOnline,
}) async {
  final response = await http.put(
    Uri.parse('$baseUrl/drivers/$driverId/status'),
    headers: headers,
    body: jsonEncode({'is_online': isOnline}),
  );
  
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to update driver status');
  }
}

// Create ride (passenger)
static Future<Map<String, dynamic>> createRide({
  required int passengerId,
  required int stationId,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/rides'),
    headers: headers,
    body: jsonEncode({
      'passenger_id': passengerId,
      'station_id': stationId,
      'status': 'pending',
    }),
  );
  
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to create ride');
  }
}
```

---

## TESTING CHECKLIST

### ✅ Test Driver Dashboard Toggle
- [ ] Toggle "Accept Passengers" ON → Verify online status updates
- [ ] Toggle OFF → Verify offline status updates
- [ ] Check backend receives updates
- [ ] Verify error handling on network failure

### ✅ Test Driver Routes View Selector
- [ ] Click "Active" tab → Shows active routes
- [ ] Click "Completed" tab → Shows completed routes
- [ ] Click "Scheduled" tab → Shows scheduled routes

### ✅ Test Payment Screen Buttons
- [ ] Click "💵 Cash" → Shows waiting dialog
- [ ] Click "🔵 GCash" → Shows checkout URL
- [ ] Click "💎 E-Wallet" → Shows checkout URL

### ✅ Test Passenger Dashboard
- [ ] Display station options
- [ ] Click station → Shows on map
- [ ] Click "Track Bus" → Creates ride and opens map

### ✅ Test Driver Map GPS
- [ ] GPS starts when map opens
- [ ] Marker updates every 5 seconds
- [ ] Stop broadcasting stops GPS
- [ ] WebSocket connection shows real-time data

---

## IMPLEMENTATION STATUS

| Feature | Status | Priority | ETA |
|---------|--------|----------|-----|
| Driver Toggle Status | ⚠️ Partial | 🔴 Critical | Today |
| Driver View Alerts | ❌ Missing | 🔴 Critical | Today |
| View All Trips | ⚠️ Partial | 🔴 Critical | Today |
| Passenger Station Search | ❌ Missing | 🔴 Critical | Tomorrow |
| Passenger Track Bus | ❌ Missing | 🔴 Critical | Tomorrow |
| Login Sign Up | ⚠️ Partial | 🟡 Important | This week |
| Driver Routes Tabs | ✅ Complete | 🟢 Done | - |
| Forgot Password | ⚠️ Partial | 🟡 Important | This week |

---

## CODE ORGANIZATION

### Files to Modify:
1. `lib/driver/driver_dashboard.dart` - Add toggle API call
2. `lib/driver/driver_alerts.dart` - Create new file for alerts
3. `lib/passenger/passenger_dashboard.dart` - Add station search & track
4. `lib/services/api_service.dart` - Add missing API methods
5. `lib/driver/driver_map.dart` - Enhance tracking buttons

### New Files to Create:
1. `lib/driver/driver_alerts.dart` - Driver alerts screen
2. `lib/passenger/station_picker.dart` - Station selection widget

---

## NEXT IMMEDIATE ACTIONS

1. **Today**:
   - [ ] Implement Driver Status Toggle API connection
   - [ ] Create DriverAlerts screen
   - [ ] Add API methods to ApiService

2. **Tomorrow**:
   - [ ] Implement Passenger Station Search
   - [ ] Implement Passenger "Track Bus" button
   - [ ] Test end-to-end passenger flow

3. **This Week**:
   - [ ] Complete Sign Up flow
   - [ ] Complete Forgot Password flow
   - [ ] Full system testing

---

**Current Success Rate**: 59% (20/34 buttons functional)
**Target**: 95% (32/34 buttons functional) by Friday
**Status**: 🔄 In Progress
