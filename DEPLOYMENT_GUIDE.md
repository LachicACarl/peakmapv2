# 🚀 PEAK MAP - Complete Deployment Guide

**Last Updated:** March 9, 2026  
**Target Platforms:** Docker, Heroku, AWS, DigitalOcean, VPS

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Local Docker Setup](#2-local-docker-setup)
3. [Heroku Deployment](#3-heroku-deployment-easiest)
4. [DigitalOcean App Platform](#4-digitalocean-app-platform-recommended)
5. [AWS Deployment](#5-aws-deployment-advanced)
6. [Traditional VPS Deployment](#6-traditional-vps-deployment)
7. [Post-Deployment Steps](#7-post-deployment-steps)
8. [Troubleshooting](#8-troubleshooting)

---

## 1. Prerequisites

### Required Accounts & Tools

- ✅ **Supabase Account** (Already configured)
- ⬜ **Docker Desktop** (for local testing)
- ⬜ **Git** (version control)
- ⬜ **Cloud Platform Account** (choose one):
  - Heroku (easiest)
  - DigitalOcean (recommended)
  - AWS/GCP/Azure (advanced)

### Environment Setup

Before deploying, ensure you have:

```bash
# 1. Install production dependencies
cd peak-map-backend
pip install -r requirements.txt

# 2. Verify gunicorn is installed
gunicorn --version
# Should output: gunicorn (version 23.0.0)

# 3. Test production mode locally
gunicorn -w 2 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8001 app.main:app
```

---

## 2. Local Docker Setup

### Step 1: Install Docker

**Windows:**
```powershell
# Download Docker Desktop from: https://www.docker.com/products/docker-desktop/
# Or install via winget:
winget install Docker.DockerDesktop
```

**Linux:**
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

**Mac:**
```bash
brew install --cask docker
```

### Step 2: Test Docker Installation

```bash
docker --version
docker-compose --version
```

### Step 3: Build and Run with Docker

```bash
# Navigate to project root
cd C:\Users\User\Documents\peakmapv2

# Build Docker image
docker-compose build

# Start all services
docker-compose up -d

# Check logs
docker-compose logs -f backend

# Test backend
curl http://localhost:8001/

# Stop services
docker-compose down
```

### Step 4: Configure Environment

Create `.env` file (already exists, verify values):

```bash
# peak-map-backend/.env
DATABASE_URL=sqlite:////app/data/peakmap.db
SUPABASE_URL=https://grtesehqlvhfmlchibnv.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
FORCE_LOCAL_AUTH=false
GOOGLE_MAPS_API_KEY=your_key_here
SECRET_KEY=your-secret-key-change-in-production
CORS_ORIGINS=http://localhost:3000,http://localhost:8080
```

### Docker Commands Reference

```bash
# Build
docker-compose build --no-cache

# Start
docker-compose up -d

# Restart
docker-compose restart backend

# View logs
docker-compose logs -f backend

# Execute command in container
docker-compose exec backend python -c "print('Hello')"

# Stop
docker-compose down

# Stop and remove volumes
docker-compose down -v
```

---

## 3. Heroku Deployment (Easiest)

### Step 1: Install Heroku CLI

**Windows:**
```powershell
winget install Heroku.HerokuCLI
```

**Mac/Linux:**
```bash
curl https://cli-assets.heroku.com/install.sh | sh
```

### Step 2: Login and Create App

```bash
# Login to Heroku
heroku login

# Create new app
heroku create peakmap-backend

# Or with custom name
heroku create your-app-name
```

### Step 3: Configure Environment Variables

```bash
# Navigate to backend directory
cd peak-map-backend

# Set all environment variables
heroku config:set SUPABASE_URL="https://grtesehqlvhfmlchibnv.supabase.co"
heroku config:set SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
heroku config:set SUPABASE_SERVICE_ROLE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
heroku config:set FORCE_LOCAL_AUTH="false"
heroku config:set SECRET_KEY="$(openssl rand -hex 32)"
heroku config:set CORS_ORIGINS="https://your-frontend-domain.com"

# Optional: Add PostgreSQL database
heroku addons:create heroku-postgresql:mini

# Verify config
heroku config
```

### Step 4: Deploy

```bash
# Initialize git (if not already done)
git init
git add .
git commit -m "Initial deployment"

# Add Heroku remote
heroku git:remote -a peakmap-backend

# Deploy
git push heroku main

# Check logs
heroku logs --tail

# Open app
heroku open
```

### Step 5: Verify Deployment

```bash
# Check status
heroku ps

# Test API
curl https://peakmap-backend.herokuapp.com/

# Check admin endpoints
curl https://peakmap-backend.herokuapp.com/admin/dashboard_overview
```

### Heroku Maintenance Commands

```bash
# Restart dynos
heroku restart

# Scale dynos
heroku ps:scale web=2

# Run database migrations
heroku run python -c "from app.database import Base, engine; Base.metadata.create_all(bind=engine)"

# Access logs
heroku logs --tail

# Access shell
heroku run bash
```

---

## 4. DigitalOcean App Platform (Recommended)

### Step 1: Push Code to GitHub

```bash
# Create GitHub repository
gh repo create peakmap-backend --public --source=. --remote=origin

# Or manually:
git remote add origin https://github.com/yourusername/peakmap-backend.git
git branch -M main
git push -u origin main
```

### Step 2: Create App on DigitalOcean

1. Go to https://cloud.digitalocean.com/apps
2. Click "Create App"
3. Select "GitHub" as source
4. Choose your repository
5. Configure settings:

**App Settings:**
```yaml
Name: peakmap-backend
Region: New York (or closest to users)
Branch: main
Source Directory: /peak-map-backend
Build Command: (auto-detected)
Run Command: gunicorn -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8080 app.main:app
```

**Environment Variables:**
```
SUPABASE_URL=https://grtesehqlvhfmlchibnv.supabase.co
SUPABASE_ANON_KEY=eyJhbGci...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGci...
FORCE_LOCAL_AUTH=false
SECRET_KEY=your-generated-secret-key
CORS_ORIGINS=https://your-domain.com
```

### Step 3: Deploy

1. Click "Deploy"
2. Wait for build to complete (5-10 minutes)
3. Note your app URL: `https://peakmap-backend-xxxxx.ondigitalocean.app`

### Step 4: Configure Custom Domain (Optional)

1. Go to "Settings" → "Domains"
2. Add custom domain: `api.peakmap.com`
3. Update DNS records at your domain registrar:
   ```
   CNAME api peakmap-backend-xxxxx.ondigitalocean.app
   ```
4. SSL certificate provisioned automatically

### DigitalOcean Maintenance

```bash
# Install doctl (DigitalOcean CLI)
# https://docs.digitalocean.com/reference/doctl/how-to/install/

# Authenticate
doctl auth init

# List apps
doctl apps list

# View logs
doctl apps logs <app-id> --follow

# Restart app
doctl apps update <app-id>
```

---

## 5. AWS Deployment (Advanced)

### Option A: AWS ECS (Fargate) with Docker

**Prerequisites:**
- AWS Account
- AWS CLI installed
- Docker image pushed to ECR

**Steps:**

```bash
# 1. Install AWS CLI
# https://aws.amazon.com/cli/

# 2. Configure credentials
aws configure

# 3. Create ECR repository
aws ecr create-repository --repository-name peakmap-backend

# 4. Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

# 5. Build and push image
docker build -t peakmap-backend ./peak-map-backend
docker tag peakmap-backend:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/peakmap-backend:latest
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/peakmap-backend:latest

# 6. Create ECS task definition, service, and cluster via AWS Console
# or use AWS CLI / Terraform
```

### Option B: AWS Elastic Beanstalk

```bash
# 1. Install EB CLI
pip install awsebcli

# 2. Initialize
cd peak-map-backend
eb init -p python-3.11 peakmap-backend

# 3. Create environment
eb create peakmap-production

# 4. Set environment variables
eb setenv SUPABASE_URL=https://... SUPABASE_ANON_KEY=...

# 5. Deploy
eb deploy

# 6. Open app
eb open

# View logs
eb logs
```

---

## 6. Traditional VPS Deployment

### Supported Platforms:
- DigitalOcean Droplet
- AWS EC2
- Linode
- Vultr
- Any VPS with Ubuntu 20.04+

### Step 1: Provision VPS

Create a VPS with:
- **OS:** Ubuntu 22.04 LTS
- **RAM:** 1GB minimum (2GB recommended)
- **Storage:** 25GB minimum
- **Cost:** ~$5-12/month

### Step 2: Initial Server Setup

```bash
# SSH into server
ssh root@your-server-ip

# Update system
apt update && apt upgrade -y

# Create user
adduser peakmap
usermod -aG sudo peakmap

# Switch to user
su - peakmap
```

### Step 3: Install Dependencies

```bash
# Install Python
sudo apt install python3.11 python3.11-venv python3-pip -y

# Install PostgreSQL (optional)
sudo apt install postgresql postgresql-contrib -y

# Install Nginx
sudo apt install nginx -y

# Install Certbot (for SSL)
sudo apt install certbot python3-certbot-nginx -y
```

### Step 4: Deploy Application

```bash
# Clone repository
cd ~
git clone https://github.com/yourusername/peakmap-backend.git
cd peakmap-backend/peak-map-backend

# Create virtual environment
python3.11 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Create .env file
nano .env
# Paste your environment variables

# Test application
gunicorn -w 2 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000 app.main:app
```

### Step 5: Setup Systemd Service

```bash
# Create service file
sudo nano /etc/systemd/system/peakmap.service
```

**Paste this:**
```ini
[Unit]
Description=PEAK MAP Backend API
After=network.target

[Service]
Type=notify
User=peakmap
Group=peakmap
WorkingDirectory=/home/peakmap/peakmap-backend/peak-map-backend
Environment="PATH=/home/peakmap/peakmap-backend/peak-map-backend/venv/bin"
ExecStart=/home/peakmap/peakmap-backend/peak-map-backend/venv/bin/gunicorn -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000 app.main:app
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**Enable and start service:**
```bash
sudo systemctl daemon-reload
sudo systemctl enable peakmap
sudo systemctl start peakmap
sudo systemctl status peakmap
```

### Step 6: Configure Nginx Reverse Proxy

```bash
# Create Nginx config
sudo nano /etc/nginx/sites-available/peakmap
```

**Paste this:**
```nginx
server {
    listen 80;
    server_name api.peakmap.com;  # Replace with your domain

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

**Enable site:**
```bash
sudo ln -s /etc/nginx/sites-available/peakmap /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### Step 7: Setup SSL Certificate

```bash
# Get SSL certificate
sudo certbot --nginx -d api.peakmap.com

# Auto-renewal is configured automatically
# Test renewal
sudo certbot renew --dry-run
```

### VPS Maintenance Commands

```bash
# View logs
sudo journalctl -u peakmap -f

# Restart service
sudo systemctl restart peakmap

# Update code
cd ~/peakmap-backend
git pull
source peak-map-backend/venv/bin/activate
pip install -r peak-map-backend/requirements.txt
sudo systemctl restart peakmap

# Check service status
sudo systemctl status peakmap
sudo systemctl status nginx
```

---

## 7. Post-Deployment Steps

### 1. Update Admin Dashboard

Update `admin_dashboard.html` with production URL:

```javascript
// Change this:
const API_BASE = 'http://127.0.0.1:8001';

// To this:
const API_BASE = 'https://api.peakmap.com';  // Or your Heroku/DO URL
```

### 2. Deploy Admin Dashboard

**Option A: Netlify (Recommended)**
```bash
# Install Netlify CLI
npm install -g netlify-cli

# Deploy
netlify deploy --prod --dir=.
# Upload admin_dashboard.html when prompted
```

**Option B: Vercel**
```bash
npm install -g vercel
vercel
```

**Option C: GitHub Pages**
```bash
git add admin_dashboard.html
git commit -m "Add admin dashboard"
git push origin main
# Enable GitHub Pages in repo settings
```

### 3. Create Admin User in Production

```bash
# Option 1: Via API
curl -X POST https://api.peakmap.com/admin/register \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@peakmap.com","password":"SecurePassword123!","name":"Admin User"}'

# Option 2: Via Python script (on server)
cd peak-map-backend
python create_admin.py
```

### 4. Test All Endpoints

```bash
# Health check
curl https://api.peakmap.com/

# Admin login
curl -X POST https://api.peakmap.com/admin/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@peakmap.com","password":"SecurePassword123!"}'

# Dashboard overview
curl https://api.peakmap.com/admin/dashboard_overview

# RFID events
curl https://api.peakmap.com/admin/rfid_tap_events?limit=5
```

### 5. Configure CORS for Production

Update `peak-map-backend/app/main.py`:

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://your-admin-dashboard.netlify.app",
        "https://api.peakmap.com",
        "null"  # Keep for local file:// testing
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### 6. Setup Monitoring (Optional but Recommended)

**Sentry for Error Tracking:**
```bash
pip install sentry-sdk[fastapi]
```

Add to `app/main.py`:
```python
import sentry_sdk

sentry_sdk.init(
    dsn="your-sentry-dsn",
    traces_sample_rate=1.0,
)
```

**Health Check Monitoring:**
- Use UptimeRobot (free)
- Monitor: `https://api.peakmap.com/health`
- Get alerts if down

---

## 8. Troubleshooting

### Common Issues

#### 1. Port Already in Use
```bash
# Find process
netstat -ano | findstr :8000
# Kill process
taskkill /F /PID <pid>
```

#### 2. gunicorn Not Found
```bash
pip install gunicorn==23.0.0
gunicorn --version
```

#### 3. Database Connection Error
```bash
# Check connection string
echo $DATABASE_URL

# Test PostgreSQL connection
psql $DATABASE_URL
```

#### 4. CORS Errors in Production
- Update `allow_origins` in `app/main.py`
- Include your production domain
- Redeploy backend

#### 5. 502 Bad Gateway (Nginx)
```bash
# Check backend is running
sudo systemctl status peakmap

# Check backend logs
sudo journalctl -u peakmap -n 50

# Restart services
sudo systemctl restart peakmap nginx
```

#### 6. SSL Certificate Issues
```bash
# Renew certificate
sudo certbot renew

# Check certificate status
sudo certbot certificates
```

### Deployment Checklist

Before going live:

- [ ] Backend deployed and accessible
- [ ] Admin dashboard deployed
- [ ] Environment variables set correctly
- [ ] Admin user created
- [ ] CORS configured for production domain
- [ ] SSL certificate installed
- [ ] Database backed up
- [ ] Monitoring setup (optional)
- [ ] All endpoints tested
- [ ] Error tracking configured (optional)
- [ ] Documentation updated with production URLs

---

## Quick Reference

### Heroku Commands
```bash
heroku logs --tail                    # View logs
heroku restart                        # Restart app
heroku ps                            # Check status
heroku config                        # View env vars
heroku run bash                      # Access shell
```

### Docker Commands
```bash
docker-compose up -d                 # Start
docker-compose down                  # Stop
docker-compose logs -f backend       # View logs
docker-compose restart backend       # Restart
```

### VPS Commands
```bash
sudo systemctl status peakmap        # Check status
sudo journalctl -u peakmap -f        # View logs
sudo systemctl restart peakmap       # Restart
sudo nginx -t                        # Test Nginx config
```

---

## Support

**Documentation:**
- [DEPLOYMENT_READINESS_REPORT.md](DEPLOYMENT_READINESS_REPORT.md)
- [SYSTEM_ARCHITECTURE.md](SYSTEM_ARCHITECTURE.md)
- [HOW_TO_RUN.md](HOW_TO_RUN.md)

**Troubleshooting:**
- Check logs first
- Verify environment variables
- Test API endpoints manually
- Review CORS configuration

---

*Last Updated: March 9, 2026*  
*Version: 1.0*
