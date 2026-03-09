# 🚀 Vercel Deployment Quick Start

## ✅ Files Created for Vercel Deployment

1. **`vercel.json`** - Vercel configuration
2. **`peak-map-backend/api/index.py`** - Serverless function entry point
3. **`.vercelignore`** - Files to exclude from deployment
4. **`.env.vercel.example`** - Environment variables template
5. **`VERCEL_DEPLOYMENT.md`** - Detailed deployment guide

## 📝 Quick Deployment Steps

### 1. Ensure Code is on GitHub

```powershell
cd c:\Users\lance\Documents\peakmap\peakmapv2
git add .
git commit -m "Add Vercel deployment configuration"
git push origin main
```

### 2. Deploy to Vercel

Go to [vercel.com/new](https://vercel.com/new) and:
- Import your GitHub repo: `LachicACarl/peakmapv2`
- Add these environment variables:
  - `SUPABASE_URL`
  - `SUPABASE_ANON_KEY`
  - `SUPABASE_SERVICE_ROLE_KEY`
  - `DATABASE_URL` (PostgreSQL connection string from Supabase)
  - `FORCE_LOCAL_AUTH=false`

### 3. Test Your Deployment

Visit:
- `https://your-app.vercel.app/health` - Health check
- `https://your-app.vercel.app/docs` - API documentation
- `https://your-app.vercel.app/admin_dashboard.html` - Admin dashboard

## 🔑 Important Configuration Changes Made

### Backend API (`peak-map-backend/api/index.py`)
- ✅ Created Vercel-compatible entry point
- ✅ Added Mangum adapter for FastAPI
- ✅ Configured CORS for Vercel domains
- ✅ All routes accessible via serverless functions

### Admin Dashboard (`admin_dashboard.html`)
- ✅ Auto-detects local vs production environment
- ✅ Uses port 8001 locally, no port on Vercel
- ✅ Works with both HTTP and HTTPS

### Dependencies (`requirements.txt`)
- ✅ Added `mangum` (FastAPI to AWS Lambda/Vercel adapter)
- ✅ Added `httpx` (async HTTP client)

## 📊 What Gets Deployed

**Included:**
- ✅ Backend API (`peak-map-backend/`)
- ✅ Admin Dashboard (`admin_dashboard.html`)
- ✅ Card Tap Interface (`card_tap_interface.html`)
- ✅ Configuration files
- ✅ SQL setup files

**Excluded (via `.vercelignore`):**
- ❌ Flutter mobile app (deploy separately)
- ❌ Local database (`peakmap.db`)
- ❌ Virtual environment (`.venv312/`)
- ❌ Test files
- ❌ Batch files

## 🗄️ Database Configuration

**Local Development:**
```
DATABASE_URL=sqlite:///./peakmap.db
```

**Production (Vercel):**
```
DATABASE_URL=postgresql://postgres:[password]@db.grtesehqlvhfmlchibnv.supabase.co:5432/postgres
```

Get your PostgreSQL URL from:
Supabase Dashboard → Settings → Database → Connection string

## 🔧 Testing Locally Before Deployment

Test the new API entry point:

```powershell
cd c:\Users\lance\Documents\peakmap\peakmapv2\peak-map-backend
C:/Users/lance/Documents/peakmap/peakmapv2/.venv312/Scripts/python.exe -m uvicorn api.index:app --reload --port 8001
```

Visit: `http://127.0.0.1:8001/docs`

## 📱 Flutter App Configuration

After deployment, update your Flutter app's API URL:

**Before (Local):**
```dart
static const String baseUrl = 'http://127.0.0.1:8001';
```

**After (Production):**
```dart
static const String baseUrl = 'https://your-app.vercel.app';
```

## ⚡ Vercel Limitations to Know

1. **Serverless Functions:**
   - 30-second timeout (configured in `vercel.json`)
   - Cold starts may occur

2. **WebSockets:**
   - Limited support on Vercel
   - Consider Supabase Realtime for live updates

3. **File System:**
   - Read-only and ephemeral
   - Use Supabase for data persistence

## 🆘 Troubleshooting

### API Returns 404
- Check `vercel.json` routes configuration
- Verify `peak-map-backend/api/index.py` exists

### Database Connection Failed
- Verify `DATABASE_URL` environment variable
- Use Supabase PostgreSQL connection string (not SQLite)
- Check Supabase database password

### CORS Errors
- Verify domain in `peak-map-backend/api/index.py`
- Add your domain to `allow_origins` list

### Module Import Errors
- Check all dependencies in `requirements.txt`
- Ensure `mangum` and `httpx` are listed

## 📚 Full Documentation

See [VERCEL_DEPLOYMENT.md](VERCEL_DEPLOYMENT.md) for complete details.

---

**Ready to deploy! 🎉**

Questions? Check the logs in Vercel Dashboard → Deployments → Function Logs
