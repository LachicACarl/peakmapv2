"""
Vercel Serverless Function Entry Point for Peak Map API
This file adapts the FastAPI app to work with Vercel's serverless functions.
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from mangum import Mangum
import sys
import os

# Add the peak-map-backend directory to the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from app.routes import alerts, admin, auth, drivers, eta, fares, gps, notifications, payments, rfid, ride_sessions, rides, stations, ws_gps

app = FastAPI(title="PEAK MAP API")

# Configure CORS for Vercel deployment
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://*.vercel.app",
        "https://peakmap.vercel.app",
        "http://localhost:3000",
        "http://localhost:8080",
        "http://localhost:5500",
        "http://127.0.0.1:5500",
        "http://127.0.0.1:8080",
        "null",  # Allow file:// protocol
    ],
    allow_origin_regex=r"https://.*\.vercel\.app$",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router)
app.include_router(drivers.router)
app.include_router(alerts.router)
app.include_router(stations.router)
app.include_router(fares.router)
app.include_router(gps.router)
app.include_router(eta.router)
app.include_router(rides.router)
app.include_router(ride_sessions.router)
app.include_router(payments.router)
app.include_router(rfid.router)
app.include_router(ws_gps.router)
app.include_router(admin.router)
app.include_router(notifications.router)

@app.get("/")
def read_root():
    return {
        "message": "Peak Map API",
        "status": "online",
        "docs": "/docs",
        "version": "1.0.0"
    }

@app.get("/health")
def health_check():
    return {"status": "healthy", "service": "peakmap-api"}

# Mangum handler for Vercel
handler = Mangum(app)
