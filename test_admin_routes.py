import sys
sys.path.insert(0, 'c:/Users/User/Documents/peakmapv2/peak-map-backend')

try:
    import app.routes.admin
    print('✅ admin.py imports OK')
    print('Has admin_login:', hasattr(app.routes.admin, 'admin_login'))
    print('Router prefix:', app.routes.admin.router.prefix)
    print('Routes:', [r.path for r in app.routes.admin.router.routes][:15])
except Exception as e:
    print('❌ ERROR:', e)
    import traceback
    traceback.print_exc()
