import sqlite3

conn = sqlite3.connect('importflow.db')
cur = conn.cursor()

# Delete items first (child table)
cur.execute('DELETE FROM shipping_scenario_items')
items_deleted = cur.rowcount

# Delete sessions
cur.execute('DELETE FROM shipping_evaluation_sessions')
sessions_deleted = cur.rowcount

conn.commit()

# Verify
cur.execute('SELECT COUNT(*) FROM shipping_evaluation_sessions')
s = cur.fetchone()[0]
cur.execute('SELECT COUNT(*) FROM shipping_scenario_items')
i = cur.fetchone()[0]

conn.close()
print('Done!')
print(f'Sessions deleted: {sessions_deleted}')
print(f'Items deleted:    {items_deleted}')
print(f'Sessions left:    {s}')
print(f'Items left:       {i}')
