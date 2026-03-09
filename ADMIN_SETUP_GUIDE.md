# Admin Authentication Setup Complete! 🎉

## What Was Added

### 1. Backend Admin Authentication (`/admin/login`, `/admin/register`)
- Added admin login endpoint at `/admin/login`
- Added admin registration endpoint at `/admin/register`
- Added session verification endpoint at `/admin/verify`
- Both Supabase and local authentication supported

### 2. Admin Dashboard Login Page
- Beautiful login page that appears before the dashboard
- Session management with localStorage
- Automatic dashboard unlock after successful login
- Logout button added to header

### 3. Admin User Creation Tools
- **create_admin.py** - Interactive Python script to create admin users
- **create_admin_supabase.sql** - SQL script for manual admin creation in Supabase

## How to Use

### Step 1: Restart the Backend Server

**IMPORTANT**: The backend needs to be restarted to load the new admin endpoints.

There are zombie processes on port 8000 that need to be killed first:

```powershell
# Method 1: Restart your computer (easiest)

# Method 2: Kill stubborn processes via Task Manager
# 1. Open Task Manager (Ctrl+Shift+Esc)
# 2. Go to Details tab
# 3. Find processes with PIDs: 12404, 8916, 25080
# 4. Right-click → End Process Tree

# Method 3: Use Windows Resource Monitor
# 1. Press Win+R, type: resmon
# 2. Go to Network tab
# 3. Expand "Listening Ports"
# 4. Find port 8000, right-click processes → End Process
```

After killing processes:

```powershell
cd c:\Users\User\Documents\peakmapv2\peak-map-backend
& "c:\Users\User\Documents\peakmapv2\.venv312\Scripts\python.exe" run_server.py
```

### Step 2: Create Your First Admin User

**Option A: Using Python Script**

```powershell
cd c:\Users\User\Documents\peakmapv2\peak-map-backend
& "c:\Users\User\Documents\peakmapv2\.venv312\Scripts\python.exe" create_admin.py
```

Follow the prompts to enter:
- Email (e.g., admin@peakmap.com)
- Name (e.g., Admin User)
- Password (minimum 6 characters)

**Option B: Using Direct API Call**

```powershell
$payload = @{
    email = 'admin@peakmap.com'
    password = 'admin123'
    name = 'Admin User'
} | ConvertTo-Json

Invoke-RestMethod -Uri 'http://127.0.0.1:8000/admin/register' `
    -Method Post `
    -ContentType 'application/json' `
    -Body $payload
```

**Option C: Using Supabase (if you want Supabase auth)**

1. Go to your Supabase Dashboard → SQL Editor
2. Run the SQL in `create_admin_supabase.sql`
3. Then go to Authentication → Users → Add User
4. Create user with same email and password
5. Mark "Auto Confirm User" as YES

### Step 3: Login to Admin Dashboard

1. Open the admin dashboard: http://127.0.0.1:8000/admin_dashboard.html
2. You'll see the login page
3. Enter your admin credentials
4. Click "Login to Dashboard"
5. The dashboard will appear after successful authentication

### Step 4: Using the Dashboard

- The dashboard is now protected by authentication
- Your session is saved in localStorage
- You'll stay logged in until you click "Logout"
- The logout button appears in the header next to your name

## Files Modified/Created

### Modified:
- `admin_dashboard.html` - Added login page and authentication
- `peak-map-backend/app/routes/admin.py` - Added admin auth endpoints

### Created:
- `peak-map-backend/create_admin.py` - Python script to create admin users
- `create_admin_supabase.sql` - SQL script for Supabase admin creation
- `ADMIN_SETUP_GUIDE.md` - This file

## Security Features

✅ Password hashing (SHA-256)
✅ Session tokens stored locally
✅ Admin-only access (checks user_type='admin')
✅ Both Supabase and local auth fallback
✅ Protected dashboard routes

## Default Admin Credentials (if you used the examples)

```
Email: admin@peakmap.com
Password: admin123
```

**IMPORTANT**: Change this password after first login!

## Troubleshooting

### "Invalid credentials" error
- Make sure you created the admin user first
- Check that the backend is running
- Verify email and password are correct

### "Not authorized. Admin access only."
- The user exists but user_type is not 'admin'
- Check the users table in your database
- Make sure user_type column is set to 'admin'

### "Connection error"
- Backend server is not running
- Check http://127.0.0.1:8000/docs to verify API is up

### Admin endpoints not found (404)
- Backend needs to be restarted with the new code
- Kill all processes on port 8000 first
- Start backend again

## Next Steps

1. Kill the zombie processes on port 8000
2. Restart the backend
3. Create your first admin user
4. Login to the dashboard
5. Change the default password!

Enjoy your secured admin dashboard! 🚀
