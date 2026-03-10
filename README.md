# 🏔️ Peak Map - Smart Public Transit System

A comprehensive transit management system with real-time GPS tracking, RFID fare collection, and admin dashboard.

## 🚀 Quick Deploy to Vercel

**Ready to deploy in 5 minutes!**

1. **Push to GitHub:**
   ```bash
   git add .
   git commit -m "Ready for deployment"
   git push origin main
   ```

2. **Deploy to Vercel:**
   - Visit [vercel.com/new](https://vercel.com/new)
   - Import this repository
   - Add environment variables (see `.env.vercel.example`)
   - Click Deploy!

3. **Access Your App:**
   - API: `https://your-app.vercel.app`
   - Docs: `https://your-app.vercel.app/docs`
   - Admin: `https://your-app.vercel.app/admin_dashboard.html`

📖 **Full Guide:** See [VERCEL_DEPLOYMENT.md](VERCEL_DEPLOYMENT.md) or [VERCEL_QUICKSTART.md](VERCEL_QUICKSTART.md)

---

## 📦 Project Structure

```
peakmapv2/
├── peak-map-backend/          # FastAPI Backend
│   ├── api/
│   │   └── index.py          # Vercel entry point
│   ├── app/
│   │   ├── routes/           # API endpoints
│   │   ├── models/           # Database models
│   │   └── services/         # Business logic
│   └── requirements.txt      # Python dependencies
├── peak_map_mobile/          # Flutter Mobile App
├── admin_dashboard.html      # Web Admin Dashboard
├── vercel.json              # Vercel configuration
└── VERCEL_DEPLOYMENT.md     # Deployment guide
```

## 🛠️ Local Development

### Prerequisites
- Python 3.13+
- Flutter 3.0+ (for mobile app)
- Supabase account

### Setup Backend

```powershell
# Activate virtual environment
.\.venv312\Scripts\Activate.ps1

# Start backend server
.\start_backend_8001.bat
```

Backend runs on: `http://127.0.0.1:8001`

### Setup Mobile App

```powershell
cd peak_map_mobile
flutter pub get
flutter run
```

## 🌐 Features

### Backend API (FastAPI)
- ✅ Real-time GPS tracking
- ✅ RFID fare collection
- ✅ Driver management
- ✅ Ride tracking & ETA calculation
- ✅ Payment processing
- ✅ Admin dashboard API
- ✅ WebSocket support

### Mobile App (Flutter)
- ✅ Driver & passenger interfaces
- ✅ Live map with bus tracking
- ✅ QR code pairing
- ✅ Real-time updates
- ✅ Alerts & notifications

### Admin Dashboard (HTML/JavaScript)
- ✅ Live driver tracking map
- ✅ RFID card management
- ✅ Payment monitoring
- ✅ Real-time analytics
- ✅ User management

## 🗄️ Database

**Local:** SQLite (`peakmap.db`)  
**Production:** Supabase PostgreSQL

All database tables are auto-created on startup. See `supabase_tables.sql` for schema.

## 📊 API Documentation

When running, visit:
- **Local:** `http://127.0.0.1:8001/docs`
- **Production:** `https://your-app.vercel.app/docs`

## 🔐 Environment Variables

Required for deployment:
```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
DATABASE_URL=your_postgresql_connection_string
FORCE_LOCAL_AUTH=false
```

See `.env.vercel.example` for template.

## 📱 Mobile App Deployment

After deploying the backend:

1. Update API URL in Flutter app:
   ```dart
   static const String baseUrl = 'https://your-app.vercel.app';
   ```

2. Build for Android/iOS:
   ```bash
   flutter build apk       # Android
   flutter build ios       # iOS
   ```

## 🧪 Testing

### Test Backend Health
```bash
curl https://your-app.vercel.app/health
```

### Run System Health Check
```powershell
C:/Users/lance/Documents/peakmap/peakmapv2/.venv312/Scripts/python.exe system_health_check.py
```

## 📚 Documentation

- [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md) - Project overview
- [SYSTEM_ARCHITECTURE.md](SYSTEM_ARCHITECTURE.md) - Architecture details
- [HOW_TO_RUN.md](HOW_TO_RUN.md) - Local development guide
- [VERCEL_DEPLOYMENT.md](VERCEL_DEPLOYMENT.md) - Vercel deployment (detailed)
- [VERCEL_QUICKSTART.md](VERCEL_QUICKSTART.md) - Quick deployment guide
- [SYSTEM_STATUS.md](SYSTEM_STATUS.md) - Current system status

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally
5. Submit a pull request

## 📄 License

MIT License - See LICENSE file for details

## 🆘 Support

- **Issues:** Create an issue in GitHub
- **Logs:** Check Vercel Dashboard → Function Logs
- **Database:** Supabase Dashboard → Logs

---

**Built with ❤️ using FastAPI, Flutter, and Supabase**

**Deploy Status:** [![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https://github.com/LachicACarl/peakmapv2)
