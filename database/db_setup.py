"""
Atlas Tourism - Database Setup Script
Executes tourism_database.sql against local MySQL server to initialize
all tables, constraints, foreign keys, and seed records.
"""

import os
import sys
import pymysql
from dotenv import load_dotenv

# Add parent directory to path so config can be loaded
current_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.dirname(current_dir)
sys.path.append(parent_dir)

load_dotenv(os.path.join(parent_dir, '.env'))

MYSQL_HOST = os.getenv('MYSQL_HOST', 'localhost')
MYSQL_PORT = int(os.getenv('MYSQL_PORT', 3306))
MYSQL_USER = os.getenv('MYSQL_USER', 'root')
MYSQL_PASSWORD = os.getenv('MYSQL_PASSWORD', 'root@123')
MYSQL_DB = os.getenv('MYSQL_DB', 'atlas_tourism')

def run_db_setup():
    print("=" * 60)
    print("  ATLAS TOURISM - DATABASE INITIALIZATION UTILITY")
    print("=" * 60)
    print(f"Connecting to MySQL server at {MYSQL_HOST}:{MYSQL_PORT} as '{MYSQL_USER}'...")
    
    try:
        # First connect without specifying database to ensure DB can be created
        conn = pymysql.connect(
            host=MYSQL_HOST,
            port=MYSQL_PORT,
            user=MYSQL_USER,
            password=MYSQL_PASSWORD,
            autocommit=True,
            charset='utf8mb4'
        )
        cursor = conn.cursor()
        print("[OK] Connected to MySQL Server successfully.")
        
        # Read the SQL file
        sql_file_path = os.path.join(current_dir, 'tourism_database.sql')
        if not os.path.exists(sql_file_path):
            print(f"[ERROR] SQL file not found at: {sql_file_path}")
            return False
            
        print(f"Reading SQL script from: {sql_file_path}...")
        with open(sql_file_path, 'r', encoding='utf-8') as f:
            sql_script = f.read()

        # Execute statements
        # Remove comments and split by semicolon
        print("Executing schema definition and seed insertions...")
        statements = []
        current_stmt = []
        
        for line in sql_script.splitlines():
            clean_line = line.strip()
            if not clean_line or clean_line.startswith('--') or clean_line.startswith('/*'):
                continue
            current_stmt.append(line)
            if clean_line.endswith(';'):
                statement_str = "\n".join(current_stmt).strip()
                if statement_str:
                    statements.append(statement_str)
                current_stmt = []
                
        success_count = 0
        for stmt in statements:
            try:
                cursor.execute(stmt)
                success_count += 1
            except Exception as e:
                print(f"[WARN] Statement failed: {stmt[:60]}... Error: {e}")
                
        cursor.close()
        conn.close()
        
        print("-" * 60)
        print(f"[SUCCESS] Database '{MYSQL_DB}' set up successfully!")
        print(f"Total SQL statements executed: {success_count}/{len(statements)}")
        print("Default Logins:")
        print("  Admin: admin@atlastourism.com / admin123")
        print("  User:  john@example.com       / user123")
        print("=" * 60)
        return True

    except pymysql.MySQLError as e:
        print(f"[FATAL ERROR] Could not connect to MySQL: {e}")
        print("\nPlease check your credentials in .env file:")
        print(f"  MYSQL_HOST={MYSQL_HOST}")
        print(f"  MYSQL_USER={MYSQL_USER}")
        print(f"  MYSQL_PASSWORD={'*' * len(MYSQL_PASSWORD)}")
        print(f"  MYSQL_DB={MYSQL_DB}")
        return False

if __name__ == '__main__':
    success = run_db_setup()
    sys.exit(0 if success else 1)
