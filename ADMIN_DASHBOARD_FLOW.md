# ADMIN DASHBOARD - Complete Flow Documentation

## 🎯 Overview

The PEAK MAP Admin Dashboard is a comprehensive web interface for system administrators to monitor and manage the transportation system in real-time. It provides live tracking, payment management, driver administration, and NFC card operations.

## 🌐 Access & Setup

### Starting the Dashboard

1. **Start Backend Server:**
```bash
cd peak-map-backend
..\.venv\Scripts\python.exe run_server.py
```
Backend runs on: `http://127.0.0.1:8000`

2. **Open Admin Dashboard:**
   - Open `admin_dashboard.html` in a web browser
   - Dashboard auto-connects to backend via WebSocket and REST APIs

### Live Connection Status
- **Green Indicator**: Connected - Real-time updates active
- **Red Indicator**: Disconnected - Auto-reconnects every 3 seconds

---

## 📊 Dashboard Features

### 1. **Top Statistics Cards**

Four real-time metric cards displaying:
- **Total Revenue**: Sum of all paid transactions (₱)
- **Active Rides**: Number of ongoing rides
- **Active Drivers**: Number of drivers in the system
- **Pending Payments**: Total pending payment amount (₱)

**Updates**: Every 30 seconds + real-time WebSocket updates

---

### 2. **Quick Action Buttons**

#### 🔵 NFC Balance Loader
**Purpose**: Load money onto passenger NFC cards

**Flow:**
1. Click "NFC Balance Loader" button
2. Enter User ID (UUID from Supabase)
3. Enter or select amount (₱100, ₱200, ₱500, ₱1000)
4. Click "Load Balance"
5. System confirms balance loaded
6. View recent loads in the table below

**Backend Endpoint:**
```
POST /payments/load-balance
{
    "user_id": "bb6e65b6-1cc5-4b63-8b99-0c80f86e0b9b",
    "amount": 100.00,
    "payment_method": "admin_nfc",
    "card_id": null
}
```

**Response:**
```json
{
    "success": true,
    "transaction_id": 123,
    "user_id": "bb6e65b6-...",
    "amount": 100.00,
    "timestamp": "2026-02-27T10:30:00"
}
```

**Recent Loads Table:**
- Transaction ID
- User ID (truncated)
- Amount loaded
- Date/Time
- Status (Paid)

---

#### 🟠 Refund Transaction
**Purpose**: Reverse a completed transaction and return money to user

**Flow:**
1. Click "Refund Transaction" button
2. Enter Transaction ID (from payment records)
3. Enter reason for refund
4. Click "Process Refund"
5. System creates reverse transaction
6. User balance updated automatically

**Backend Endpoint:**
```
POST /payments/refund/{transaction_id}
{
    "reason": "Duplicate charge",
    "refunded_by": "admin"
}
```

**Response:**
```json
{
    "success": true,
    "original_transaction_id": 123,
    "refund_transaction_id": 456,
    "refund_amount": 45.00,
    "user_id": "bb6e65b6-...",
    "new_user_balance": 155.00
}
```

**Use Cases:**
- Duplicate charges
- System errors
- Service complaints
- Fare disputes

---

#### 🟣 Card Management
**Purpose**: Block lost/stolen cards, request replacements

**Flow:**

**A. Block Card:**
1. Click "Card Management" button
2. Enter User ID
3. Enter reason (optional)
4. Click "Block Card"
5. Card immediately blocked (no new transactions allowed)

**Backend Endpoint:**
```
POST /payments/card/{user_id}/block
{
    "status": "blocked",
    "reason": "Lost card reported by user"
}
```

**B. Request Replacement:**
1. Enter User ID
2. Enter reason (e.g., "Damaged card")
3. Click "Request Replacement"
4. Replacement request created
5. Admin processes replacement offline

**Backend Endpoint:**
```
POST /payments/card/{user_id}/replace
{
    "status": "pending_replacement",
    "reason": "Card damaged"
}
```

**C. Check Card Status:**
- Click "Check Status" to view:
  - Current card status (active/blocked/pending_replacement)
  - Whether card is blocked
  - Whether replacement is pending

---

#### ⚙️ Settings
**Status**: Coming Soon
**Planned Features:**
- System configuration
- User management
- Report generation
- Backup/restore

---

### 3. **Live Driver Tracking Map**

**Features:**
- Google Maps integration
- Real-time driver positions via WebSocket
- Color-coded markers:
  - 🔵 Blue: Available driver
  - 🟤 Brown: Driver on active ride
- Driver labels show Driver ID
- Click marker for info:
  - Driver ID
  - Current Ride ID
  - Ride status
  - Fare amount
  - Speed (m/s)

**WebSocket Updates:**
- Receives GPS updates every few seconds
- Marker positions update instantly
- No page refresh needed

**Backend Endpoints:**
- `GET /admin/active_rides` - Initial driver positions
- `WS /ws/admin` - Real-time GPS updates

---

### 4. **Payment Breakdown Sidebar**

Shows payment distribution by method:
- 💵 **Cash**: Count and total amount
- 📱 **GCash**: Count and total amount
- 💳 **E-Wallet**: Count and total amount

**Updates**: Every 30 seconds

**Backend Endpoint:**
```
GET /admin/payments_by_method
```

**Response:**
```json
{
    "cash": {"count": 5, "amount": 225.00},
    "gcash": {"count": 3, "amount": 135.00},
    "ewallet": {"count": 2, "amount": 90.00}
}
```

---

### 5. **Recent Activity Feed**

Live feed of recent system events:
- 🎫 Ride created/completed
- 💳 Payments processed
- Status badges (ongoing/completed)

Shows last 10 activities with:
- Timestamp
- Activity type (ride/payment)
- Key details (IDs, amounts, methods)
- Status badges

**Updates**: Every 30 seconds + real-time via WebSocket

**Backend Endpoint:**
```
GET /admin/recent_activity?limit=10
```

---

### 6. **Ride Statistics Table**

Breakdown of all rides by status:
- Ongoing
- Completed
- Dropped (passenger got off)
- Missed (passenger didn't board)
- Cancelled

For each status:
- Count
- Percentage of total
- Visual progress bar

**Backend Endpoint:**
```
GET /admin/rides_stats
```

---

### 7. **Active Drivers Table**

List of all drivers with:
- Driver ID
- Active Rides count
- Status (Online/Offline)
  - Online: Last GPS update within 60 seconds
  - Offline: No recent updates

**Add Driver Button:**
- Opens modal to register new driver
- Required fields:
  - Full Name
  - Email
  - Phone Number
  - License Number
  - Vehicle Plate
  - Vehicle Model
  - Initial Password (min 6 chars)

**Backend Endpoints:**
- `GET /admin/all_drivers` - List all drivers
- `POST /auth/register` - Register new driver

---

## 🔄 Data Flow

### On Dashboard Load:
1. Initialize Google Maps
2. Connect to WebSocket (`/ws/admin`)
3. Fetch initial data:
   - Dashboard overview
   - Active rides (with GPS)
   - Payment breakdown
   - Ride statistics
   - Recent activity
   - Driver list

### Real-Time Updates:
- **WebSocket** pushes GPS updates → Updates map markers
- **Polling** (every 30s) refreshes:
  - Statistics cards
  - Payment breakdown
  - Activity feed
  - Ride stats
  - Driver list

### User Actions:
```
User Click → Open Modal → Fill Form → Submit
    ↓
Backend API Call (POST/GET)
    ↓
Success Response → Close Modal → Refresh Data
    or
Error Response → Show Error Message
```

---

## 🛠️ Backend API Endpoints Summary

### Admin Endpoints (`/admin`)
- `GET /dashboard_overview` - Top statistics
- `GET /active_rides` - Rides with driver GPS
- `GET /all_drivers` - Driver list
- `GET /payments_by_method` - Payment breakdown
- `GET /rides_stats` - Ride status counts
- `GET /recent_activity?limit=10` - Activity feed

### Payment Endpoints (`/payments`)
- `POST /load-balance` - Load NFC balance
- `GET /transactions/admin` - All NFC transactions
- `POST /refund/{transaction_id}` - Refund transaction
- `POST /card/{user_id}/block` - Block card
- `POST /card/{user_id}/replace` - Request replacement
- `GET /card/{user_id}/status` - Check card status

### Auth Endpoints (`/auth`)
- `POST /register` - Register new driver/user

### WebSocket (`/ws`)
- `WS /ws/admin` - Real-time GPS updates

---

## 🎨 UI/UX Features

### Color Scheme
- **Primary**: Blue (#7AAACE)
- **Secondary**: Dark Blue (#355872)
- **Success**: Green (#4CAF50)
- **Warning**: Orange (#FF9800)
- **Error**: Red (#F44336)

### Responsive Design
- Desktop: Grid layout with sidebar
- Tablet: Single column layout
- Mobile: Stacked cards

### Animations
- Hover effects on cards
- Modal slide-in animations
- Fade-in transitions
- Pulse effect on WebSocket indicator

### Accessibility
- Proper form labels
- Keyboard navigation
- Error messages
- Loading states

---

## 🚦 Testing the Flow

### Test Scenario 1: Load Balance via NFC
1. Open dashboard
2. Click "NFC Balance Loader"
3. Enter user ID: `bb6e65b6-1cc5-4b63-8b99-0c80f86e0b9b`
4. Select ₱100
5. Click "Load Balance"
6. ✅ Success message appears
7. ✅ Transaction appears in Recent Loads table

### Test Scenario 2: Refund Transaction
1. Note a transaction ID from Recent Loads
2. Click "Refund Transaction"
3. Enter the transaction ID
4. Enter reason: "Test refund"
5. Click "Process Refund"
6. ✅ Refund confirmation shows new balance
7. ✅ User balance calculated correctly

### Test Scenario 3: Block Card
1. Click "Card Management"
2. Enter user ID
3. Enter reason: "Card lost"
4. Click "Block Card"
5. ✅ Block confirmation appears
6. Click "Check Status"
7. ✅ Status shows "blocked"

### Test Scenario 4: Add Driver
1. Click "Add Driver" button
2. Fill all required fields
3. Click "Add Driver"
4. ✅ Driver registered successfully
5. ✅ Driver appears in Active Drivers table

---

## 🔐 Security Considerations

### Production Checklist:
- [ ] Add admin authentication
- [ ] Implement role-based access control (RBAC)
- [ ] Add HTTPS for dashboard
- [ ] Verify WebSocket authentication
- [ ] Add rate limiting on sensitive endpoints
- [ ] Log all admin actions
- [ ] Add confirmation dialogs for destructive actions
- [ ] Encrypt sensitive data in transit

### Current Security:
- ⚠️ No authentication required (development only)
- ⚠️ Full access to all admin functions
- ⚠️ No audit logging

**DO NOT USE IN PRODUCTION WITHOUT ADDING AUTHENTICATION!**

---

## 📝 Troubleshooting

### Dashboard not loading?
- Check backend is running on port 8000
- Check browser console for errors
- Verify CORS is enabled in backend

### WebSocket disconnected?
- Backend may have restarted
- Dashboard auto-reconnects every 3 seconds
- Check network connectivity

### Map not displaying?
- Verify Google Maps API key in HTML
- Check API key has Maps JavaScript API enabled
- Check browser console for API errors

### Buttons not working?
- Open browser console (F12)
- Check for JavaScript errors
- Verify backend endpoints are responding
- Test endpoints manually with curl/Postman

### Empty data tables?
- No data in database yet
- Run `seed_data.py` to populate test data
- Check backend logs for database errors

---

## 🎯 Next Steps

### Enhancements Needed:
1. **Authentication & Authorization**
   - Admin login system
   - Session management
   - Role-based permissions

2. **Advanced Features**
   - Export reports (PDF/CSV)
   - Date range filters
   - Advanced search
   - Bulk operations

3. **Analytics**
   - Revenue charts (daily/weekly/monthly)
   - Driver performance metrics
   - Route popularity heatmap
   - Peak hours analysis

4. **Notifications**
   - Real-time alerts for issues
   - Email notifications for critical events
   - SMS alerts for drivers

5. **Settings Page**
   - Fare rate configuration
   - System parameters
   - Payment gateway settings
   - Map customization

---

## ✅ Summary

The Admin Dashboard provides a **complete, working system** for managing PEAK MAP operations:

✅ Real-time driver tracking with live GPS updates
✅ NFC balance loading with transaction history
✅ Transaction refund system with balance recalculation
✅ Card management (block, replace, check status)
✅ Driver registration and monitoring
✅ Payment method breakdown
✅ Activity feed with live updates
✅ Ride statistics and analytics
✅ WebSocket integration for instant updates
✅ Responsive design for all devices

**All buttons are functional and connected to working backend endpoints!**

---

## 📞 Support

For issues or questions:
1. Check backend logs: `peak-map-backend/` terminal
2. Check browser console (F12) for JavaScript errors
3. Verify all endpoints with: `GET http://127.0.0.1:8000/docs`
4. Test WebSocket: Connect to `ws://127.0.0.1:8000/ws/admin`

---

**Document Version**: 1.0
**Last Updated**: February 27, 2026
**Author**: PEAK MAP Development Team
