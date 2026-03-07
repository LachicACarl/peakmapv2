import os
from typing import Any, Optional, TYPE_CHECKING

from dotenv import load_dotenv

if TYPE_CHECKING:
    from supabase import Client as SupabaseClient
else:
    SupabaseClient = Any

# Try to import supabase, but handle gracefully if not installed
try:
    from supabase import create_client
    SUPABASE_AVAILABLE = True
except ImportError:
    print("⚠️  Supabase module not installed. Running in demo mode.")
    SUPABASE_AVAILABLE = False
    create_client = None

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
SUPABASE_KEY = SUPABASE_SERVICE_ROLE_KEY or SUPABASE_ANON_KEY

_client: Optional[SupabaseClient] = None


class MockSupabaseClient:
    """Mock Supabase client for demo mode"""
    is_mock = True
    class Auth:
        def sign_up(self, credentials):
            class MockUser:
                email = credentials.get('email')
                id = hash(credentials.get('email')) % 10000
            class MockResult:
                user = MockUser()
            return MockResult()
        
        def sign_in_with_password(self, credentials):
            class MockUser:
                email = credentials.get('email')
                id = hash(credentials.get('email')) % 10000
            class MockSession:
                access_token = "demo_token"
            class MockResult:
                user = MockUser()
                session = MockSession()
            return MockResult()
    
    class Table:
        def __init__(self, name):
            self.name = name
        
        def insert(self, data):
            return self
        
        def execute(self):
            return {"data": [], "error": None}
    
    def __init__(self):
        self.auth = self.Auth()
    
    def table(self, name):
        return self.Table(name)


def get_supabase_client():
    global _client
    if _client is None:
        if not SUPABASE_AVAILABLE:
            print("ℹ️  Using mock Supabase client (demo mode)")
            _client = MockSupabaseClient()
        else:
            if not SUPABASE_URL or not SUPABASE_KEY:
                raise ValueError("SUPABASE_URL and a Supabase key are required")
            _client = create_client(SUPABASE_URL, SUPABASE_KEY)
    return _client


def is_supabase_available() -> bool:
    return SUPABASE_AVAILABLE and bool(SUPABASE_URL and SUPABASE_KEY)
