import urllib.parse
import psycopg2

password = "Itswas@21december2003_sunday"
encoded_pw = urllib.parse.quote_plus(password)
project_ref = "pyxieazgbwotnkqamawb"
region = "eu-west-1"

candidates = [
    # Direct connection
    f"postgresql://postgres:{encoded_pw}@db.{project_ref}.supabase.co:5432/postgres",
    # Pooler session mode
    f"postgresql://postgres.{project_ref}:{encoded_pw}@aws-0-{region}.pooler.supabase.com:5432/postgres",
    # Pooler transaction mode
    f"postgresql://postgres.{project_ref}:{encoded_pw}@aws-0-{region}.pooler.supabase.com:6543/postgres",
]

connected_url = None
for url in candidates:
    display_url = url.replace(encoded_pw, "********")
    print(f"Testing connection to: {display_url} ...")
    try:
        conn = psycopg2.connect(url, connect_timeout=10)
        cur = conn.cursor()
        cur.execute("SELECT version();")
        v = cur.fetchone()
        print(f"SUCCESS! Connected to PostgreSQL version: {v[0]}")
        cur.close()
        conn.close()
        connected_url = url
        break
    except Exception as e:
        print(f"Failed with error: {e}")

if connected_url:
    print(f"\nWinning connection string found!")
else:
    print("\nCould not connect with any candidate.")
