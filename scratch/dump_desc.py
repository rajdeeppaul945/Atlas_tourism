import sys
sys.path.insert(0, r"C:\Users\rajde\Desktop\2nd Sem Projects\atlas_tourism")
from utils.database import execute_query

tables = [r['Tables_in_atlas_tourism'] for r in execute_query('SHOW TABLES', fetchall=True)]
for t in tables:
    cols = execute_query(f'DESCRIBE `{t}`', fetchall=True)
    print(f'-- {t} --')
    for c in cols:
        print(f"  {c['Field']}: {c['Type']}, Null={c['Null']}, Default={c['Default']}")
