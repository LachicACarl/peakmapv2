-- PEAK MAP - Supabase Database Tables
-- Copy and paste this entire file into Supabase SQL Editor

-- DROP existing tables if needed (uncomment to reset database)
-- DROP TABLE IF EXISTS payments CASCADE;
-- DROP TABLE IF EXISTS gps_logs CASCADE;
-- DROP TABLE IF EXISTS rides CASCADE;
-- DROP TABLE IF EXISTS fares CASCADE;
-- DROP TABLE IF EXISTS stations CASCADE;
-- DROP TABLE IF EXISTS passengers CASCADE;
-- DROP TABLE IF EXISTS drivers CASCADE;
-- DROP TABLE IF EXISTS users CASCADE;

-- 1. Users Table
CREATE TABLE IF NOT EXISTS users (
  id BIGSERIAL PRIMARY KEY, 
  email VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255),
  user_type VARCHAR(50),
  phone VARCHAR(20),
  avatar_url VARCHAR(500),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 2. Drivers Table
CREATE TABLE IF NOT EXISTS drivers (
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

-- 3. Passengers Table
CREATE TABLE IF NOT EXISTS passengers (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(id),
  phone VARCHAR(20),
  rating FLOAT DEFAULT 5.0,
  total_rides INT DEFAULT 0,
  total_spent DECIMAL(10,2) DEFAULT 0,
  preferred_payment VARCHAR(50),
  created_at TIMESTAMP DEFAULT NOW()
);

-- 4. Stations Table
CREATE TABLE IF NOT EXISTS stations (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  latitude FLOAT NOT NULL,
  longitude FLOAT NOT NULL,
  address VARCHAR(500),
  created_at TIMESTAMP DEFAULT NOW()
);

-- 5. Rides Table
CREATE TABLE IF NOT EXISTS rides (
  id BIGSERIAL PRIMARY KEY,
  driver_id BIGINT REFERENCES drivers(id),
  passenger_id BIGINT REFERENCES passengers(id),
  pickup_station_id BIGINT REFERENCES stations(id),
  dropoff_station_id BIGINT REFERENCES stations(id),
  status VARCHAR(50),
  fare DECIMAL(10,2),
  distance FLOAT,
  duration_minutes INT,
  rating INT,
  payment_method VARCHAR(50),
  paid BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 6. GPS Logs Table
CREATE TABLE IF NOT EXISTS gps_logs (
  id BIGSERIAL PRIMARY KEY,
  driver_id BIGINT REFERENCES drivers(id),
  ride_id BIGINT REFERENCES rides(id),
  latitude FLOAT NOT NULL,
  longitude FLOAT NOT NULL,
  speed FLOAT,
  timestamp TIMESTAMP DEFAULT NOW()
);

-- 7. Fares Table
CREATE TABLE IF NOT EXISTS fares (
  id BIGSERIAL PRIMARY KEY,
  base_fare DECIMAL(10,2),
  per_km_rate DECIMAL(10,2),
  per_minute_rate DECIMAL(10,2),
  minimum_fare DECIMAL(10,2),
  active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- 8. Payments Table
CREATE TABLE IF NOT EXISTS payments (
  id BIGSERIAL PRIMARY KEY,
  ride_id BIGINT REFERENCES rides(id),
  passenger_id BIGINT REFERENCES passengers(id),
  amount DECIMAL(10,2),
  payment_method VARCHAR(50),
  status VARCHAR(50),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Insert Sample Stations (if not exist)
INSERT INTO stations (name, latitude, longitude, address) 
SELECT 'Quezon Avenue Station', 14.6091, 121.0270, 'Quezon Avenue, QC'
WHERE NOT EXISTS (SELECT 1 FROM stations WHERE name = 'Quezon Avenue Station');

INSERT INTO stations (name, latitude, longitude, address)
SELECT 'Monumento Station', 14.6312, 120.9761, 'Monumento Circle, Caloocan'
WHERE NOT EXISTS (SELECT 1 FROM stations WHERE name = 'Monumento Station');

INSERT INTO stations (name, latitude, longitude, address)
SELECT 'Cubao Station', 14.5804, 121.0444, 'Cubao, Quezon City'
WHERE NOT EXISTS (SELECT 1 FROM stations WHERE name = 'Cubao Station');

INSERT INTO stations (name, latitude, longitude, address)
SELECT 'EDSA-Magallanes Station', 14.5333, 121.0226, 'Magallanes, Makati'
WHERE NOT EXISTS (SELECT 1 FROM stations WHERE name = 'EDSA-Magallanes Station');

INSERT INTO stations (name, latitude, longitude, address)
SELECT 'Buendia Station', 14.5633, 121.0128, 'Buendia Ave, Makati'
WHERE NOT EXISTS (SELECT 1 FROM stations WHERE name = 'Buendia Station');

-- Insert Default Fare Settings (if not exist)
INSERT INTO fares (base_fare, per_km_rate, per_minute_rate, minimum_fare, active)
SELECT 50.00, 15.00, 2.50, 50.00, TRUE
WHERE NOT EXISTS (SELECT 1 FROM fares WHERE base_fare = 50.00);
