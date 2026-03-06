import requests
import json

# Test auth endpoint with the test user we created
payload = {
    'email': 'testuser@peakmap.com',
    'password': 'test123',
    'user_type': 'passenger'
}

try:
    response = requests.post('http://127.0.0.1:8000/auth/login', json=payload, timeout=5)
    print(f'✓ Status Code: {response.status_code}\n')
    
    result = response.json()
    print('Response:')
    for key, value in result.items():
        print(f'  {key}: {value}')
    
    # Check for success indicators
    if response.status_code == 200 and result.get('success'):
        print('\n✓ LOGIN SUCCESSFUL - Auth fix is working!')
        print(f'  Auth Method: {result.get("auth_method")}')
    elif response.status_code == 200:
        print('\n✓ 200 Response - Auth endpoint accessible')
    else:
        print(f'\nExpected 200 but got {response.status_code}')
        
except Exception as e:
    print(f'Error: {e}')
