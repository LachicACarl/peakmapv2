import sqlite3
conn = sqlite3.connect('peakmap.db')
cur = conn.cursor()
cur.execute('PRAGMA table_info(payments)')
cols = [r[1] for r in cur.fetchall()]
if 'user_id' not in cols:
    cur.execute('ALTER TABLE payments ADD COLUMN user_id VARCHAR')
    conn.commit()
    print('Added user_id')
else:
    print('user_id already exists')
conn.close()
