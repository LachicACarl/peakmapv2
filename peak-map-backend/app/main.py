from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.database import Base, engine
from app.routes import alerts, admin, auth, drivers, eta, fares, gps, notifications, payments, rfid, ride_sessions, rides, stations, ws_gps

# Import all models to ensure tables are created
import app.models  # noqa: F401

Base.metadata.create_all(bind=engine)

app = FastAPI(title="PEAK MAP API")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://127.0.0.1:5500",
        "http://localhost:5500",
        "http://localhost:8080",
        "http://localhost:8000",
        "http://127.0.0.1:8080",
        "http://127.0.0.1:8000",
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "null",  # Allow file:// protocol for local HTML files
        # Production domains - UPDATE with your actual deployment URLs
        "https://*.netlify.app",
        "https://*.vercel.app",
    ],
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1)(:\d+)?$|https://.*\.(netlify|vercel)\.app$",
    allow_credentials=True,
    allow_methods=["*"],  # Allow all methods (GET, POST, PUT, DELETE, etc.)
    allow_headers=["*"],  # Allow all headers
)

# Include routers
app.include_router(auth.router)  # Authentication endpoints
app.include_router(drivers.router)  # Driver management endpoints
app.include_router(alerts.router)  # Driver/passenger alerts
app.include_router(stations.router)
app.include_router(fares.router)
app.include_router(gps.router)
app.include_router(eta.router)
app.include_router(rides.router)
app.include_router(ride_sessions.router)
app.include_router(payments.router)
app.include_router(rfid.router)
app.include_router(ws_gps.router)  # WebSocket for real-time GPS updates
app.include_router(admin.router)  # Admin dashboard endpoints
app.include_router(notifications.router)  # Push notifications


@app.get("/")
def root():
    return {"status": "PEAK MAP backend running"}


@app.get("/health")
def health_check():
    """Health check endpoint for deployment platforms (Render, Heroku, etc.)"""
    return {"status": "healthy", "service": "PEAK MAP API"}
