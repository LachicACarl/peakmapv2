# ✅ Vercel Deployment - Setup Complete!

## 🎉 Your Peak Map project is now ready for Vercel deployment!

---

## 📦 What Was Configured

### ✅ Vercel Configuration Files
- **`vercel.json`** - Tells Vercel how to build and route your app
- **`.vercelignore`** - Excludes unnecessary files from deployment
- **`.gitignore`** - Updated to protect sensitive data

### ✅ API Entry Point
- **`peak-map-backend/api/index.py`** - Serverless function adapter
  - Uses Mangum to make FastAPI work with Vercel
  - Configured CORS for production
  - All your existing routes work seamlessly

### ✅ Admin Dashboard
- **`admin_dashboard.html`** - Updated for smart environment detection
  - Auto-detects local vs production
  - Uses `localhost:8001` when local
  - Uses Vercel domain when deployed

### ✅ Dependencies
- **`requirements.txt`** - Updated with:
  - `mangum` (FastAPI → Vercel adapter)
  - `httpx` (async HTTP client)

### ✅ Documentation
- **`README.md`** - Project overview with quick deploy button
- **`VERCEL_DEPLOYMENT.md`** - Complete deployment guide
- **`VERCEL_QUICKSTART.md`** - Quick reference
- **`.env.vercel.example`** - Environment variables template

---

## 🚀 Next Steps to Deploy

### Step 1: Push to GitHub (5 minutes)

```powershell
cd c:\Users\lance\Documents\peakmap\peakmapv2

# Add all new files
git add .

# Commit changes
git commit -m "Add Vercel deployment configuration"

# Push to GitHub
git push origin main
```

### Step 2: Deploy on Vercel (5 minutes)

1. Go to **[vercel.com/new](https://vercel.com/new)**
2. Click **"Import Project"**
3. Select your GitHub repository: `LachicACarl/peakmapv2`
4. Configure:
   - Framework Preset: **Other**
   - Root Directory: **`./`** (default)
   - Leave build commands empty

5. **Add Environment Variables:** (Click "Environment Variables")
   ```
   SUPABASE_URL=https://grtesehqlvhfmlchibnv.supabase.co
   SUPABASE_ANON_KEY=<your_anon_key>
   SUPABASE_SERVICE_ROLE_KEY=<your_service_key>
   DATABASE_URL=postgresql://postgres:<password>@db.grtesehqlvhfmlchibnv.supabase.co:5432/postgres
   FORCE_LOCAL_AUTH=false
   ```
   
   **Get DATABASE_URL:** Supabase Dashboard → Settings → Database → Connection string

6. Click **"Deploy"**

### Step 3: Test Your Deployment (2 minutes)

Once deployed, Vercel gives you a URL like: `https://peakmapv2.vercel.app`

Test these endpoints:
- ✅ Health: `https://your-app.vercel.app/health`
- ✅ API Docs: `https://your-app.vercel.app/docs`
- ✅ Admin: `https://your-app.vercel.app/admin_dashboard.html`
- ✅ Stations: `https://your-app.vercel.app/stations`

---

## 🗄️ Database Migration (Important!)

Your local SQLite database (`peakmap.db`) won't work on Vercel.  
You need to use **Supabase PostgreSQL** (already configured!).

### Verify Supabase Setup

1. Log in to [supabase.com](https://supabase.com)
2. Open project: `grtesehqlvhfmlchibnv`
3. Check if tables exist: **Database → Tables**

### If Tables Don't Exist:

Run these SQL files in Supabase SQL Editor:

1. **`supabase_tables.sql`** - Creates all tables
2. **`create_admin_supabase.sql`** - Creates admin user

**How to run:**
- Supabase Dashboard → SQL Editor → New Query
- Copy-paste SQL content
- Click "Run"

### Migrate Test Data (Optional)

If you have data in `peakmap.db` you want to keep:

```powershell
# Export from SQLite (create a migration script)
# Then import to Supabase using SQL or Python

# Or create fresh test data directly in Supabase
```

---

## 📱 Update Flutter App

After deployment, update your Flutter mobile app:

**File to edit:** `peak_map_mobile/lib/services/api_service.dart` (or similar)

**Change from:**
```dart
static const String baseUrl = 'http://127.0.0.1:8001';
```

**Change to:**
```dart
static const String baseUrl = 'https://your-app.vercel.app';
```

---

## 🔍 How It Works

### Local Development
- Backend runs on `http://127.0.0.1:8001`
- Uses SQLite database (`peakmap.db`)
- Admin dashboard connects to `localhost:8001`

### Production (Vercel)
- Backend runs as serverless functions
- Uses Supabase PostgreSQL
- Admin dashboard connects to Vercel domain (no port)
- Everything auto-detects environment

---

## 🐛 Troubleshooting

### Deployment Failed?

**Check Vercel logs:**
- Vercel Dashboard → Deployments → [Latest] → Function Logs

**Common issues:**
1. **Missing environment variables** → Add in Vercel Settings
2. **Database connection error** → Verify DATABASE_URL
3. **Import errors** → Check `requirements.txt` has all dependencies

### Can't Connect to Database?

**Supabase connection string format:**
```
postgresql://postgres.[ref]:[password]@db.[ref].supabase.co:5432/postgres
```

**Get from:** Supabase → Settings → Database → Connection string

### CORS Errors?

Your domains are already configured in `peak-map-backend/api/index.py`.  
To add more:
1. Edit `peak-map-backend/api/index.py`
2. Add domain to `allow_origins` list
3. Git commit & push (auto-deploys)

---

## 📊 Monitoring Your App

### View Logs
- Vercel Dashboard → Your Project → Deployments → View Function Logs

### View Analytics
- Vercel Dashboard → Your Project → Analytics

### Monitor Database
- Supabase Dashboard → Logs
- Supabase Dashboard → Database → Tables

---

## 🔄 Continuous Deployment

Every time you push to GitHub, Vercel automatically deploys!

```powershell
# Make changes
git add .
git commit -m "Your changes"
git push origin main

# Vercel automatically builds and deploys 🚀
```

---

## 🎯 Deployment Checklist

Before going live:

- [ ] Code pushed to GitHub
- [ ] Supabase database tables created
- [ ] Admin user created in Supabase
- [ ] Test data added to Supabase (stations, fares, etc.)
- [ ] Environment variables configured in Vercel
- [ ] Deployment successful
- [ ] API endpoints responding
- [ ] Admin dashboard loads
- [ ] Database connections work
- [ ] Flutter app updated with production URL
- [ ] Tested on mobile device

---

## 📚 Documentation Reference

| File | Purpose |
|------|---------|
| `README.md` | Project overview & quick start |
| `VERCEL_DEPLOYMENT.md` | Detailed deployment guide |
| `VERCEL_QUICKSTART.md` | Quick reference guide |
| `.env.vercel.example` | Environment variables template |
| `vercel.json` | Vercel configuration |
| `peak-map-backend/api/index.py` | Serverless entry point |

---

## 💡 Pro Tips

1. **Use Environment Variables** - Never hardcode secrets
2. **Test Locally First** - Run tests before deploying
3. **Monitor Logs** - Check Vercel Function Logs regularly
4. **Use Staging** - Create a preview deployment for testing
5. **Database Backups** - Supabase has automatic backups

---

## 🎉 You're All Set!

Your Peak Map system is configured for professional deployment on Vercel.

**What you have:**
- ✅ Production-ready backend
- ✅ Auto-scaling serverless functions
- ✅ PostgreSQL database (Supabase)
- ✅ Admin dashboard
- ✅ Continuous deployment
- ✅ HTTPS by default
- ✅ Global CDN

**Next:** Push to GitHub and deploy on Vercel!

---

Questions? Check:
- [VERCEL_DEPLOYMENT.md](VERCEL_DEPLOYMENT.md) - Full guide
- Vercel Dashboard → Function Logs - For errors
- [Vercel Documentation](https://vercel.com/docs) - Platform docs
