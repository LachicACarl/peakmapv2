# 🚀 Deploying Peak Map to Vercel

This guide will help you deploy the Peak Map backend and admin dashboard to Vercel.

## 📋 Prerequisites

1. **GitHub Account** - Your code needs to be in a GitHub repository
2. **Vercel Account** - Sign up at [vercel.com](https://vercel.com)
3. **Supabase Database** - You already have this configured! ✅

## 🗄️ Database Setup (Supabase)

You're already using Supabase, which is perfect for Vercel! Your current setup:
- **Supabase URL:** https://grtesehqlvhfmlchibnv.supabase.co
- **Tables:** Already created (see `supabase_tables.sql`)

### Verify Supabase Database

1. Go to [supabase.com](https://supabase.com) and log in
2. Open your project: `grtesehqlvhfmlchibnv`
3. Go to **Database** → **Tables** and verify your tables exist
4. If tables don't exist, run the SQL files:
   - `supabase_tables.sql`
   - `create_admin_supabase.sql` (for admin user)

## 📦 Step 1: Push Code to GitHub

If you haven't already:

```powershell
cd c:\Users\lance\Documents\peakmap\peakmapv2

# Initialize git (if not already done)
git init

# Add all files
git add .

# Commit
git commit -m "Ready for Vercel deployment"

# Create a new repository on GitHub, then:
git remote add origin https://github.com/LachicACarl/peakmapv2.git
git branch -M main
git push -u origin main
```

## 🚀 Step 2: Deploy to Vercel

### Option A: Using Vercel Dashboard (Recommended)

1. Go to [vercel.com/new](https://vercel.com/new)
2. Import your GitHub repository: `LachicACarl/peakmapv2`
3. Configure the project:
   - **Framework Preset:** Other
   - **Root Directory:** `./` (leave as default)
   - **Build Command:** Leave empty
   - **Output Directory:** Leave empty

4. **Add Environment Variables** (CRITICAL!):
   Click "Environment Variables" and add:

   ```
   SUPABASE_URL=https://grtesehqlvhfmlchibnv.supabase.co
   SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdydGVzZWhxbHZoZm1sY2hpYm52Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc0MjMzNzksImV4cCI6MjA4Mjk5OTM3OX0.XCd0oWlypyPgr0pDT9Z-xieXeyQq3C1THpdX7nHrKLo
   SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdydGVzZWhxbHZoZm1sY2hpYm52Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NzQyMzM3OSwiZXhwIjoyMDgyOTk5Mzc5fQ.caLNyP9GQdVDvCARXI0RUjGtiuz4L_NXbpuGir5Fznk
   DATABASE_URL=postgresql://postgres:[YOUR_PASSWORD]@db.grtesehqlvhfmlchibnv.supabase.co:5432/postgres
   FORCE_LOCAL_AUTH=false
   ```

   **To get your PostgreSQL DATABASE_URL:**
   - Go to Supabase Dashboard → Project Settings → Database
   - Copy the "Connection string" and replace `[YOUR_PASSWORD]` with your database password

5. Click **Deploy**

### Option B: Using Vercel CLI

```powershell
# Install Vercel CLI
npm install -g vercel

# Login to Vercel
vercel login

# Deploy
cd c:\Users\lance\Documents\peakmap\peakmapv2
vercel

# Follow the prompts:
# - Set up and deploy? Yes
# - Which scope? Your account
# - Link to existing project? No
# - Project name? peakmap-api
# - Directory? ./ (current)
# - Override settings? No
```

Then add environment variables:
```powershell
vercel env add SUPABASE_URL
vercel env add SUPABASE_ANON_KEY
vercel env add SUPABASE_SERVICE_ROLE_KEY
vercel env add DATABASE_URL
vercel env add FORCE_LOCAL_AUTH
```

## 🔗 Step 3: Access Your Deployed API

After deployment, Vercel will give you a URL like:
```
https://peakmap-api.vercel.app
```

### Test Your API:

1. **API Health Check:**
   ```
   https://your-app.vercel.app/health
   ```

2. **API Documentation:**
   ```
   https://your-app.vercel.app/docs
   ```

3. **Admin Dashboard:**
   ```
   https://your-app.vercel.app/admin_dashboard.html
   ```

4. **Get Stations:**
   ```
   https://your-app.vercel.app/stations
   ```

## 📱 Step 4: Update Flutter App

After deployment, update your Flutter app to use the Vercel URL:

1. Open `peak_map_mobile/lib/services/api_service.dart` (or wherever API URL is configured)
2. Change the base URL from:
   ```dart
   static const String baseUrl = 'http://127.0.0.1:8001';
   ```
   To:
   ```dart
   static const String baseUrl = 'https://your-app.vercel.app';
   ```

## 🔧 Troubleshooting

### Issue: 500 Internal Server Error

**Solution:** Check environment variables are set correctly in Vercel:
- Go to Vercel Dashboard → Your Project → Settings → Environment Variables
- Verify all variables are present and correct

### Issue: Database Connection Errors

**Solution:** Verify your DATABASE_URL:
1. Go to Supabase Dashboard
2. Settings → Database → Connection string
3. Use the "Session pooler" connection string for better performance:
   ```
   postgresql://postgres.[project-ref]:[password]@aws-0-[region].pooler.supabase.com:6543/postgres
   ```

### Issue: CORS Errors

**Solution:** The `peak-map-backend/api/index.py` already includes CORS configuration.
If you need to add more domains:
1. Edit `peak-map-backend/api/index.py`
2. Add your domain to `allow_origins` list
3. Commit and push to GitHub (Vercel will auto-deploy)

## 📊 Monitoring

### View Logs:
1. Go to Vercel Dashboard → Your Project → Deployments
2. Click on latest deployment → View Function Logs

### View Analytics:
- Vercel Dashboard → Your Project → Analytics

## 🔄 Continuous Deployment

Every time you push to GitHub, Vercel will automatically:
1. Pull the latest code
2. Build the project
3. Deploy to production

To deploy:
```powershell
git add .
git commit -m "Your changes"
git push origin main
```

## 🌐 Custom Domain (Optional)

1. Go to Vercel Dashboard → Your Project → Settings → Domains
2. Add your custom domain
3. Follow DNS configuration instructions
4. Update Flutter app with new domain

## 📝 Important Notes

### Database:
- **Local Development:** Uses SQLite (`peakmap.db`)
- **Production (Vercel):** Uses Supabase PostgreSQL
- Make sure all data is in Supabase before going live

### Migrate Local Data to Supabase:
If you have data in `peakmap.db` that you want to migrate:

1. Export data from SQLite
2. Import to Supabase using SQL or Python script
3. Or manually create test data in Supabase

### WebSockets:
Note: Vercel's serverless functions have limitations with WebSockets.
For real-time GPS updates, consider:
- Using Supabase Realtime instead
- Or using Vercel's Edge Functions
- Or deploying WebSocket server separately (e.g., Railway, Render)

## ✅ Checklist

Before going live:

- [ ] Supabase database tables created
- [ ] Admin user created in Supabase
- [ ] Test data added (stations, fares, etc.)
- [ ] Environment variables set in Vercel
- [ ] API deployed and accessible
- [ ] Admin dashboard loads
- [ ] Flutter app updated with production URL
- [ ] CORS configured for your domains
- [ ] Test all API endpoints

## 🆘 Need Help?

Check deployment logs:
```powershell
vercel logs
```

Or view in dashboard:
Vercel Dashboard → Your Project → Deployments → [Latest] → Function Logs

---

**Your deployment is now ready! 🎉**

Access your API at: `https://your-app.vercel.app`
