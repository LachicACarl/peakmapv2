# Integration Audit & Cleanup Plan
**Date:** March 5, 2026  
**Status:** ⚠️ PARTIAL IMPLEMENTATION

---

## Executive Summary

The system has been built with multiple integrations in progress, but several have demo fallbacks that need to be removed and replaced with real implementations. Here's the comprehensive audit:

| Integration | Status | Issue | Priority |
|------------|--------|-------|----------|
| **Supabase Auth** | ⚠️ Partial | Unreliable; local fallback added but not complete | 🔴 HIGH |
| **Google Maps** | ❌ Missing | API key not configured; ETA broken without it | 🔴 HIGH |
| **NFC/Card Balance** | ⚠️ Partial | Demo mode responses; should fail properly | 🟡 MEDIUM |
| **Location/GPS** | ✅ Working | WebSocket GPS impl exists; demo data in seed | 🟡 MEDIUM |
| **ETA Calculation** | ⚠️ Partial | Service exists but needs Google Maps API key | 🔴 HIGH |

---

## 1. DUMMY DATA TO REMOVE

### A. Seed Data (`peak-map-backend/seed_data.py`)

**Current State:** Dummy hardcoded names like "Juan dela Cruz", "Maria Garcia"

**Action:** Remove or make seed_data.py production-ready:

```python
# Current (dummy)
drivers_data = [
    {"full_name": "Juan dela Cruz", ...},
    {"full_name": "Pedro Santos", ...},
]

# Should be:
# - Empty by default, OR
# - Load from environment variables, OR
# - Load from CSV/JSON file
```

**Files to modify:**
- `peak-map-backend/seed_data.py` (lines 112-155, 161-195, 201-225)

---

### B. Admin Dashboard Demo Data

**Current State:** Uses hardcoded test endpoints returning fake data

**Files affected:**
- `admin_dashboard.html` - WebSocket test data
- `peak_map_mobile/lib/admin/` - Demo screens

**Action:** Add database validation checks before rendering

---

### C. NFC/Card System Demo Responses

**Current State:** Falls back to demo "success" responses in `peak-map-backend/app/routes/payments.py`

**Lines to fix:**
- Line 414-424 in `load_balance()` - Demo fallback response
- Line 391-410 in `check_balance_nfc()` - Demo response

**Action:** Convert demo responses to proper error returns

---

## 2. MISSING INTEGRATIONS TO COMPLETE

### 🔴 HIGH PRIORITY: Google Maps API Key

**What's broken:**
- ETA calculation returns error without API key
- Mobile maps don't display
- Distance matrix API calls fail
- Admin dashboard map won't load

**Files affected:**
- `peak-map-backend/app/services/eta_service.py` (line 8-35)
- `peak_map_mobile/lib/driver/driver_map.dart`
- `peak_map_mobile/lib/passenger/passenger_dashboard.dart`
- `admin_dashboard.html` (line with API key placeholder)

**Required Action:**
```bash
# 1. Get Google Maps API key from https://console.cloud.google.com
# 2. Enable these APIs in Google Cloud:
#    - Maps SDK for Android
#    - Maps SDK for iOS
#    - Distance Matrix API
#    - Directions API
#
# 3. Set in backend:
#    - Create peak-map-backend/.env file
#    - Add: GOOGLE_MAPS_API_KEY=your_key_here
#
# 4. Set in mobile (Android):
#    - Edit: android/app/src/main/AndroidManifest.xml
#    - Add meta-data with API key
#
# 5. Set in mobile (iOS):
#    - Edit: ios/Runner/AppDelegate.swift
#    - Call GMSServices.provideAPIKey("YOUR_KEY")
#
# 6. Set in admin:
#    - Edit: admin_dashboard.html
#    - Replace YOUR_GOOGLE_MAPS_API_KEY with actual key
```

---

### 🔴 HIGH PRIORITY: Supabase Configuration

**Current State:** Local fallback auth works but primary Supabase is unreliable

**Files affected:**
- `peak-map-backend/app/supabase_client.py` (line 1-50)
- `peak_map_mobile/lib/auth/` screens

**Required Action:**
```bash
# 1. Get Supabase credentials from https://supabase.io
# 2. Set in backend:
#    - peak-map-backend/.env
#    - SUPABASE_URL=your_url
#    - SUPABASE_KEY=your_key
#
# 3. Set in mobile:
#    - peak_map_mobile/lib/firebase_options.dart
#    - Update Supabase config (currently has placeholders)
#
# 4. Test connection:
#    - Run backend: python run_server.py
#    - Test: GET /health endpoint should show Supabase status
```

---

### 🟡 MEDIUM PRIORITY: NFC Card System Cleanup

**Current State:**
- Has demo fallback responses that return `success: true` even on errors
- Balance check returns fake data when backend fails
- Should fail gracefully instead of pretending success

**Files to fix:**
- `peak-map-backend/app/routes/payments.py` (lines 414-424)
  ```python
  # Remove this demo fallback:
  except Exception as e:
      return {
          "success": True,  # ❌ WRONG - should be False
          "message": f"Balance of ₱{payload.amount} loaded (demo mode)",  # Remove demo
          ...
      }
  
  # Replace with:
  except Exception as e:
      raise HTTPException(status_code=500, detail=f"Balance load failed: {str(e)}")
  ```

- `peak_map_mobile/lib/services/nfc_service.dart`
  - Add real error handling instead of fallback to 0 balance

---

### 🟡 MEDIUM PRIORITY: Location/GPS Real Integration

**Current State:** WebSocket connection works but demo data in seed

**Action:**
- Clean up seed rides to be realistic (not all completed)
- Verify WebSocket GPS broadcast in `peak-map-backend/app/routes/ws_gps.py`
- Test mobile GPS permission handling

**Files to test:**
- `peak_map_mobile/lib/driver/driver_map.dart` - GPS sending
- `peak_map_mobile/lib/passenger/passenger_dashboard.dart` - GPS receiving
- `peak-map-backend/app/routes/ws_gps.py` - Real-time updates

---

## 3. INTEGRATION CHECKLIST FOR SATURDAY

### Prerequisites
- [ ] Google Maps API key obtained and configured
- [ ] Supabase credentials obtained and configured
- [ ] `.env` file created in `peak-map-backend/` with real credentials
- [ ] Backend `.env` has: `GOOGLE_MAPS_API_KEY`, `SUPABASE_URL`, `SUPABASE_KEY`

### Backend Verification
- [ ] `python run_server.py` starts without errors
- [ ] `GET /health` endpoint works
- [ ] `GET /eta/?driver_id=1&station_id=1` returns real ETA (not error)
- [ ] `GET /alerts/` returns real alerts (200 OK)
- [ ] No demo responses in error cases

### Mobile Verification
- [ ] Android: API key in `AndroidManifest.xml`
- [ ] iOS: API key in `AppDelegate.swift`
- [ ] Maps display on passenger/driver screens
- [ ] GPS location streaming works
- [ ] ETA updates in real-time

### Admin Dashboard Verification
- [ ] `admin_dashboard.html` has API key configured
- [ ] Google Map displays EDSA area
- [ ] Live driver markers appear when GPS updates sent
- [ ] No demo/fake data shown

### NFC/Card System Verification
- [ ] Balance load returns error on invalid input (not demo success)
- [ ] Balance check against backend (not hardcoded 0)
- [ ] Bus entry deduction validates balance properly
- [ ] All errors logged (no silent fallback)

### Supabase Verification
- [ ] Auth register works with real Supabase (not just fallback)
- [ ] Auth login works with real Supabase
- [ ] User data persists across sessions
- [ ] Session tokens are real (not demo tokens)

---

## 4. FILES TO MODIFY

| File | Changes | Reason |
|------|---------|--------|
| `peak-map-backend/seed_data.py` | Remove hardcoded names or make parameterized | Production readiness |
| `peak-map-backend/app/routes/payments.py` | Remove demo fallback responses | Proper error handling |
| `peak-map-backend/app/services/eta_service.py` | Verify Google API calls | Real ETA calculation |
| `peak-map-backend/.env` (CREATE) | Add real API keys | Integration credentials |
| `admin_dashboard.html` | Add real Google Maps API key | Working maps |
| `android/app/src/main/AndroidManifest.xml` | Add real maps API key | Working mobile maps |
| `ios/Runner/AppDelegate.swift` | Add real maps API key | Working iOS maps |
| `peak_map_mobile/lib/services/nfc_service.dart` | Remove hardcoded fallback balances | Real card reading |

---

## 5. TESTING COMMANDS

```bash
# Backend health check
curl http://127.0.0.1:8000/health

# ETA calculation (will fail without Google API key)
curl "http://127.0.0.1:8000/eta/?driver_id=1&station_id=1"

# Check Supabase integration
curl -X POST http://127.0.0.1:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test123","user_type":"passenger","name":"Test User"}'

# Get alerts
curl http://127.0.0.1:8000/alerts/

# Load balance (should fail gracefully without valid ride_id)
curl -X POST http://127.0.0.1:8000/payments/load-balance \
  -H "Content-Type: application/json" \
  -d '{"user_id":"test123","amount":100,"card_id":"card123"}'
```

---

## 6. TIMELINE & PRIORITY

| Priority | Item | Effort | Deadline |
|----------|------|--------|----------|
| 🔴 CRITICAL | Get Google Maps API key | 30 min | TODAY |
| 🔴 CRITICAL | Configure API key in all 3 places | 20 min | TODAY |
| 🔴 CRITICAL | Get Supabase credentials | 30 min | TODAY |
| 🔴 CRITICAL | Test E2E with real integrations | 1 hour | TODAY |
| 🟡 HIGH | Remove demo fallback responses | 30 min | TODAY |
| 🟡 HIGH | Verify ETA working with maps | 20 min | TODAY |
| 🟡 MEDIUM | Clean seed data (or parameterize) | 30 min | FRIDAY |
| 🟡 MEDIUM | Full system regression test | 2 hours | FRIDAY |

---

## 7. KNOWN LIMITATIONS (Post-Saturday)

- Payment gateway integration (GCash, PayMaya) is mocked - needs real integration
- NFC is mocked on non-NFC devices - needs real hardware
- Supabase database persistence varies by environment
- Rate limiting not implemented
- Database migrations not set up

---

## Summary

✅ **What's working:** Core API, WebSocket GPS, NFC balance system, authentication fallback, E2E flows  
⚠️ **What needs configuration:** Google Maps API key, Supabase credentials  
❌ **What needs removal:** Demo fallback responses in payment system

**ETA to Saturday-ready:** 4-5 hours after obtaining API credentials
