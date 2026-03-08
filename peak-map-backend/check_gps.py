import sqlite3

conn = sqlite3.connect('peakmap.db')
cursor = conn.cursor()

# Get latest GPS coordinates for each driver
query = '''
SELECT g.driver_id, g.latitude, g.longitude, g.speed, g.timestamp 
FROM gps_logs g 
INNER JOIN (
    SELECT driver_id, MAX(timestamp) as max_ts 
    FROM gps_logs 
    GROUP BY driver_id
) latest 
ON g.driver_id = latest.driver_id AND g.timestamp = latest.max_ts 
ORDER BY g.driver_id
'''

cursor.execute(query)
print('Driver ID | Latitude  | Longitude | Speed | Timestamp')
print('-' * 80)
for row in cursor.fetchall():
    print(f'{row[0]:9} | {row[1]:9.5f} | {row[2]:9.5f} | {row[3]:5.1f} | {row[4]}')

conn.close()
