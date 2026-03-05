from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from typing import List, Dict
import json

router = APIRouter(prefix="/ws", tags=["WebSocket"])

# Connected clients per driver
# Format: {driver_id: [WebSocket connections]}
connections: Dict[int, List[WebSocket]] = {}

# Admin dashboard connections
admin_connections: List[WebSocket] = []


@router.websocket("/driver/{driver_id}")
async def driver_websocket(websocket: WebSocket, driver_id: int):
    """
    WebSocket endpoint for drivers to broadcast GPS updates.
    
    Driver sends GPS data, backend broadcasts to all connected passengers.
    
    Message format from driver:
    {
        "latitude": 14.5547,
        "longitude": 121.0244,
        "speed": 15.5,
        "eta": "12 mins",  # optional
        "distance": "5.2 km"  # optional
    }
    """
    await websocket.accept()
    print(f"✅ Driver {driver_id} connected to WebSocket")

    if driver_id not in connections:
        connections[driver_id] = []

    connections[driver_id].append(websocket)

    try:
        while True:
            # Receive GPS data from driver
            data = await websocket.receive_text()
            message = json.loads(data)
            
            print(f"📍 Driver {driver_id} GPS: {message.get('latitude')}, {message.get('longitude')}")
            
            # Broadcast to all connected passengers (excluding sender)
            disconnected = []
            for conn in connections.get(driver_id, []):
                if conn != websocket:  # Don't echo back to driver
                    try:
                        await conn.send_text(data)
                    except Exception as e:
                        print(f"❌ Failed to send to passenger: {e}")
                        disconnected.append(conn)
            
            # Broadcast to admin dashboards
            admin_disconnected = []
            admin_message = {
                "type": "gps_update",
                "driver_id": driver_id,
                **message
            }
            for admin_conn in admin_connections:
                try:
                    await admin_conn.send_json(admin_message)
                except Exception as e:
                    print(f"❌ Failed to send to admin: {e}")
                    admin_disconnected.append(admin_conn)
            
            # Remove disconnected connections
            for conn in disconnected:
                if conn in connections[driver_id]:
                    connections[driver_id].remove(conn)
            
            for conn in admin_disconnected:
                if conn in admin_connections:
                    admin_connections.remove(conn)

    except WebSocketDisconnect:
        print(f"🔌 Driver {driver_id} disconnected")
    except Exception as e:
        print(f"❌ Driver {driver_id} error: {e}")
    finally:
        if websocket in connections.get(driver_id, []):
            connections[driver_id].remove(websocket)
        print(f"🧹 Cleaned up driver {driver_id} connection")


@router.websocket("/passenger/{driver_id}")
async def passenger_websocket(websocket: WebSocket, driver_id: int):
    """
    WebSocket endpoint for passengers to receive real-time GPS updates.
    
    Passenger listens for GPS broadcasts from driver.
    
    Message format to passenger:
    {
        "latitude": 14.5547,
        "longitude": 121.0244,
        "speed": 15.5,
        "eta": "12 mins",
        "distance": "5.2 km"
    }
    """
    await websocket.accept()
    print(f"✅ Passenger connected to driver {driver_id} WebSocket")

    if driver_id not in connections:
        connections[driver_id] = []

    connections[driver_id].append(websocket)

    try:
        while True:
            # Keep connection alive (ping-pong)
            await websocket.receive_text()
    except WebSocketDisconnect:
        print(f"🔌 Passenger disconnected from driver {driver_id}")
    except Exception as e:
        print(f"❌ Passenger error: {e}")
    finally:
        if websocket in connections.get(driver_id, []):
            connections[driver_id].remove(websocket)
        print(f"🧹 Cleaned up passenger connection for driver {driver_id}")


@router.get("/connections")
async def get_active_connections():
    """
    Debug endpoint to see active WebSocket connections.
    
    Returns:
    {
        "total_drivers": 2,
        "connections": {
            "1": 3,  # Driver 1 has 3 connected passengers
            "5": 1   # Driver 5 has 1 connected passenger
        },
        "admin_connections": 2
    }
    """
    connection_counts = {
        str(driver_id): len(conns)
        for driver_id, conns in connections.items()
        if len(conns) > 0
    }
    
    return {
        "total_drivers": len(connection_counts),
        "connections": connection_counts,
        "admin_connections": len(admin_connections)
    }


@router.websocket("/admin")
async def admin_websocket(websocket: WebSocket):
    """
    WebSocket endpoint for admin dashboard to receive real-time updates.
    
    Admin receives:
    - GPS updates from all drivers
    - Ride status changes
    - Payment updates
    
    Message format to admin:
    {
        "type": "gps_update",
        "driver_id": 1,
        "latitude": 14.5547,
        "longitude": 121.0244,
        "speed": 15.5,
        "timestamp": "2026-02-18T10:30:00"
    }
    """
    await websocket.accept()
    print(f"✅ Admin dashboard connected to WebSocket")
    
    admin_connections.append(websocket)
    
    # Send initial connection confirmation
    try:
        await websocket.send_json({
            "type": "connection_established",
            "message": "Admin dashboard connected",
            "active_drivers": len([d for d, conns in connections.items() if len(conns) > 0])
        })
    except Exception as e:
        print(f"❌ Failed to send confirmation to admin: {e}")
    
    try:
        while True:
            # Keep connection alive (ping-pong)
            await websocket.receive_text()
    except WebSocketDisconnect:
        print(f"🔌 Admin dashboard disconnected")
    except Exception as e:
        print(f"❌ Admin error: {e}")
    finally:
        if websocket in admin_connections:
            admin_connections.remove(websocket)
        print(f"🧹 Cleaned up admin connection")
