# ✅ Deployment Readiness Checklist

**Last Updated:** March 10, 2026  
**Platform:** Render.com (Backend) + Netlify (Frontend)

---

## Backend Deployment (Render.com)

### Files ✅
- [x] `render.yaml` - Render deployment config
- [x] `requirements.txt` - Python dependencies with pinned versions
- [x] `.env.example` - Environment variables template
- [x] `.gitignore` - Ignores .env and build artifacts
- [x] `/health` endpoint in `app/main.py`
- [x] CORS configured for production domains

### Configuration ✅
- [x] Gunicorn installed for production server
- [x] Uvicorn worker configured
- [x] Port binds to `$PORT` environment variable
- [x] Health check path set to `/health`
- [x] Auto-deploy enabled from GitHub

### Required Before Deploy ⚠️
- [ ] **Supabase credentials ready:**
  - Get from: https://app.supabase.com/project/_/settings/api
  - `SUPABASE_URL`
  - `SUPABASE_KEY` (anon key)
  - `SUPABASE_SERVICE_KEY` (service role key)

### Deployment Steps
1. ✅ Code pushed to GitHub
2. [ ] Sign up at render.com
3. [ ] Create Web Service from GitHub repo
4. [ ] Add environment variables
5. [ ] Deploy and verify `/health` endpoint

---

## Frontend Deployment (Netlify)

### Files ✅
- [x] `netlify.toml` - Netlify config with SPA redirects
- [x] Production backend URL in `lib/services/network_config.dart`
- [x] Auto-detection for Netlify/Vercel domains

### Build ⚠️
- [ ] Run build command:
  ```powershell
  flutter build web --release
  ```
- [ ] Verify `build/web/` folder exists

### Deployment Steps
1. [ ] Build Flutter web (see above)
2. [ ] Sign up at netlify.com
3. [ ] Drag `build/web` folder to deploy
4. [ ] Get deployment URL
5. [ ] Update CORS in backend with Netlify URL
6. [ ] Push backend changes (auto-redeploy)

---

## Post-Deployment Verification

### Backend Tests
```powershell
# Health check
curl https://your-backend.onrender.com/health

# API root
curl https://your-backend.onrender.com/

# Auth endpoint
curl https://your-backend.onrender.com/auth/test
```

### Frontend Tests
- [ ] Open Netlify URL in browser
- [ ] Check browser console for errors
- [ ] Test login functionality
- [ ] Test GPS tracking
- [ ] Verify API calls work

### Expected Results
- ✅ Backend responds with `{"status":"healthy"}`
- ✅ Frontend loads without CORS errors
- ✅ Login/authentication works
- ✅ API calls successful

---

## Common Issues

### Backend doesn't respond
- Check Render logs for errors
- Verify environment variables are set
- Render free tier sleeps after 15 min (first request takes 30-60 sec)

### CORS errors in browser
- Add your Netlify URL to `app/main.py` CORS origins
- Push changes and wait for Render to redeploy (2-3 min)

### Build folder missing
- Run `flutter build web --release` first
- Check for build errors in terminal

---

## Upgrade Paths (When Free Tier Isn't Enough)

**Render:**
- Free: 750 hrs/month, sleeps after 15 min
- Starter ($7/mo): Always on, 10x faster cold starts
- Standard ($25/mo): More CPU/RAM

**Netlify:**
- Free: 100GB bandwidth, 300 build minutes
- Pro ($19/mo): 1TB bandwidth, unlimited builds

**When to upgrade:**
- Backend gets >1000 requests/day
- Users complain about slow loading
- Exceed free bandwidth/build limits

---

## Status

**Current Progress:**
- ✅ Backend ready to deploy (code complete)
- ✅ Frontend ready to deploy (config complete)
- ⚠️ Needs: Supabase credentials
- ⚠️ Needs: Execute deployment steps

**Next Action:** Follow [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) Quick Start section
