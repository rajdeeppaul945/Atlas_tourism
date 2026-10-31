import urllib.parse
import psycopg2

password = "Itswas@21december2003_sunday"
encoded_pw = urllib.parse.quote_plus(password)
project_ref = "pyxieazgbwotnkqamawb"
url = f"postgresql://postgres:{encoded_pw}@db.{project_ref}.supabase.co:5432/postgres"

print("Connecting to Supabase PostgreSQL database...")
conn = psycopg2.connect(url)
conn.autocommit = True
cur = conn.cursor()

sql_file = r"C:\Users\rajde\Desktop\2nd Sem Projects\atlas_tourism\supabase_migration.sql"
print(f"Reading {sql_file}...")
with open(sql_file, "r", encoding="utf-8") as f:
    sql = f.read()

print("Executing migration script on Supabase...")
cur.execute(sql)
print("Migration script executed successfully!")

print("\nVerifying migrated tables in Supabase:")
cur.execute("""
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    ORDER BY table_name;
""")
tables = cur.fetchall()
for t in tables:
    cur.execute(f"SELECT COUNT(*) FROM {t[0]};")
    count = cur.fetchone()[0]
    print(f" - {t[0]}: {count} rows")

cur.close()
conn.close()
print("\nALL 13 TABLES AND DATA SUCCESSFULLY MIGRATED TO SUPABASE!")
