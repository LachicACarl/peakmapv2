"""
Add order column to stations table and create route_segments table
"""
import sqlite3

conn = sqlite3.connect('peakmap.db')
cursor = conn.cursor()

try:
    # Add order column to stations table
    print("Adding 'order' column to stations table...")
    cursor.execute("ALTER TABLE stations ADD COLUMN 'order' INTEGER")
    print("✓ Column added successfully")
except sqlite3.OperationalError as e:
    if "duplicate column name" in str(e):
        print("✓ Column already exists")
    else:
        print(f"✗ Error: {e}")

try:
    # Create route_segments table
    print("\nCreating route_segments table...")
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS route_segments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            from_station_id INTEGER NOT NULL,
            to_station_id INTEGER NOT NULL,
            distance_km REAL NOT NULL,
            avg_time_minutes REAL NOT NULL,
            stop_delay_seconds INTEGER DEFAULT 30,
            FOREIGN KEY (from_station_id) REFERENCES stations(id),
            FOREIGN KEY (to_station_id) REFERENCES stations(id)
        )
    ''')
    print("✓ Table created successfully")
except Exception as e:
    print(f"✗ Error: {e}")

conn.commit()
conn.close()

print("\n✅ Database schema updated successfully!")
print("You can now run seed_data.py with ENABLE_SEEDING=true")
