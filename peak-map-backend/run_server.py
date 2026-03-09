"""
Simple script to run the FastAPI server
"""
import uvicorn

if __name__ == "__main__":
    print("=" * 50)
    print("🚀 PEAK MAP Backend Server")
    print("=" * 50)
    print(f"📡 API URL: http://127.0.0.1:8001")
    print(f"📚 API Docs: http://127.0.0.1:8001/docs")
    print(f"🔧 Admin Dashboard: http://127.0.0.1:8001/admin_dashboard.html")
    print("=" * 50)
    print("Press Ctrl+C to stop the server\n")
    
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8001,
        reload=True,
        log_level="info"
    )
