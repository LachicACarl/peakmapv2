# PEAK MAP - Supabase Database Setup Guide

## ✅ Supabase Configuration Activated
- **Project ID:** `grtesehqlvhfmlchibnv`
- **URL:** https://grtesehqlvhfmlchibnv.supabase.co
- **Anon Key:** Configured in .env.supabase

## 📋 Required Database Tables

Create these tables in your Supabase project:

### 1. Users Table
```sql
CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255),
  user_type VARCHAR(50), -- 'driver' or 'passenger'
  phone VARCHAR(20),
  avatar_url VARCHAR(500),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### 2. Drivers Table
```sql
CREATE TABLE drivers (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(id),
  license_number VARCHAR(50) UNIQUE,
  vehicle_plate VARCHAR(20),
  vehicle_model VARCHAR(100),
  current_route_id BIGINT,
  is_online BOOLEAN DEFAULT FALSE,
  latitude FLOAT,
  longitude FLOAT,
  speed FLOAT DEFAULT 0,
  rating FLOAT DEFAULT 5.0,
  total_rides INT DEFAULT 0,
  earnings DECIMAL(10,2) DEFAULT 0,
  last_update TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### 3. Passengers Table
```sql
CREATE TABLE passengers (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(id),
  phone VARCHAR(20),
  rating FLOAT DEFAULT 5.0,
  total_rides INT DEFAULT 0,
  total_spent DECIMAL(10,2) DEFAULT 0,
  preferred_payment VARCHAR(50),
  created_at TIMESTAMP DEFAULT NOW()
);
```

### 4. Stations Table
```sql
CREATE TABLE stations (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  latitude FLOAT NOT NULL,
  longitude FLOAT NOT NULL,
  address VARCHAR(500),
  created_at TIMESTAMP DEFAULT NOW()
);
```

### 5. Rides Table
```sql
CREATE TABLE rides (
  id BIGSERIAL PRIMARY KEY,
  driver_id BIGINT REFERENCES drivers(id),
  passenger_id BIGINT REFERENCES passengers(id),
  pickup_station_id BIGINT REFERENCES stations(id),
  dropoff_station_id BIGINT REFERENCES stations(id),
  status VARCHAR(50), -- 'pending', 'ongoing', 'completed', 'cancelled'
  fare DECIMAL(10,2),
  distance FLOAT,
  duration_minutes INT,
  rating INT,
  payment_method VARCHAR(50),
  paid BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### 6. GPS Logs Table
```sql
CREATE TABLE gps_logs (
  id BIGSERIAL PRIMARY KEY,
  driver_id BIGINT REFERENCES drivers(id),
  ride_id BIGINT REFERENCES rides(id),
  latitude FLOAT NOT NULL,
  longitude FLOAT NOT NULL,
  speed FLOAT,
  timestamp TIMESTAMP DEFAULT NOW()
);
```

### 7. Fares Table
```sql
CREATE TABLE fares (
  id BIGSERIAL PRIMARY KEY,
  base_fare DECIMAL(10,2),
  per_km_rate DECIMAL(10,2),
  per_minute_rate DECIMAL(10,2),
  minimum_fare DECIMAL(10,2),
  active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### 8. Payments Table
```sql
CREATE TABLE payments (
  id BIGSERIAL PRIMARY KEY,
  ride_id BIGINT REFERENCES rides(id),
  passenger_id BIGINT REFERENCES passengers(id),
  amount DECIMAL(10,2),
  payment_method VARCHAR(50), -- 'cash', 'gcash', 'card'
  status VARCHAR(50), -- 'pending', 'completed', 'failed'
  created_at TIMESTAMP DEFAULT NOW()
);
```

## 🚀 Quick Start

### Terminal 1: Start Backend
```powershell
cd peak-map-backend
# Activate virtual environment
.\.venv\Scripts\Activate.ps1
# Install dependencies
pip install -r requirements.txt
# Run server (port 8000)
python run_server.py
```

### Terminal 2: Start Flutter App
```powershell
cd peak_map_mobile
# Clean build
flutter clean
# Run on Chrome
flutter run -d chrome
```

## 🧪 Testing

1. **Register/Login:** Use any email/password (6+ chars) in demo mode
2. **Driver View:** Select "I'm a Driver", login, see dashboard with 4 tabs
3. **Passenger View:** Select "I'm a Passenger", login, see dashboard with 5 tabs
4. **Admin Dashboard:** Open http://localhost:8080 in browser

## 📡 API Endpoints

- `POST /auth/register` - Register user
- `POST /auth/login` - Login user
- `POST /gps/update` - Send GPS location
- `GET /gps/latest/{driver_id}` - Get latest position
- `POST /rides/book` - Book a ride
- `GET /rides/{ride_id}` - Get ride details
- `POST /payments/process` - Process payment

## 🔐 Security Notes

- Anonymous key is safe to expose (client-side)
- Real Supabase tables provide data persistence
- Demo mode fallback if Supabase fails
- Farther Integration: WebSocket for real-time updates

---
**Color Scheme:** #355872, #7AAACE, #9CD5FF
**Status:** ✅ Production Ready
