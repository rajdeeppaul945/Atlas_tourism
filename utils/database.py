"""
Database Utility Module for Atlas Tourism
Provides safe connection management and parameterized query execution
supporting both Supabase (PostgreSQL) and local MySQL seamlessly.
Optimized with request-scoped connection reuse and connection pooling.
"""

from config import Config
from flask import g, has_app_context

def _create_raw_connection():
    """Establishes a raw connection to Supabase PostgreSQL or local MySQL."""
    if Config.SUPABASE_DB_URL:
        import re
        import psycopg2
        from psycopg2.extras import RealDictCursor

        db_url = Config.SUPABASE_DB_URL

        # Automatically translate direct Supabase URL to IPv4 connection pooler on Vercel/serverless
        m = re.search(r'db\.([a-z0-9]+)\.supabase\.co', db_url)
        if m:
            project_ref = m.group(1)
            pooler_url = re.sub(r'db\.[a-z0-9]+\.supabase\.co:\d+', 'aws-0-eu-west-1.pooler.supabase.com:6543', db_url)
            pooler_url = re.sub(r'://postgres:', f'://postgres.{project_ref}:', pooler_url)
            try:
                return psycopg2.connect(pooler_url, cursor_factory=RealDictCursor, connect_timeout=8)
            except Exception as pool_err:
                print(f"[Supabase Pooler Warning]: {pool_err}. Trying direct URL.")

        return psycopg2.connect(db_url, cursor_factory=RealDictCursor, connect_timeout=12)
    else:
        import pymysql
        import pymysql.cursors
        return pymysql.connect(
            host=Config.MYSQL_HOST,
            port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER,
            password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DB,
            charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor,
            autocommit=False
        )

def get_db_connection():
    """
    Establishes or reuses a database connection.
    When running within a Flask request context, reuses g._db_conn
    to avoid multiple expensive TCP+TLS handshakes per request.
    """
    if has_app_context():
        conn = getattr(g, '_db_conn', None)
        if conn is not None:
            # Check if PostgreSQL connection is alive
            if hasattr(conn, 'closed') and not conn.closed:
                return conn
            # Check if MySQL connection is alive
            if hasattr(conn, 'open') and conn.open:
                return conn

        conn = _create_raw_connection()
        g._db_conn = conn
        return conn

    return _create_raw_connection()

def execute_query(sql, params=None, fetchone=False, fetchall=False, commit=False):
    """
    Executes a parameterized SQL query safely across PostgreSQL (Supabase) and MySQL.
    
    :param sql: SQL query string with %s placeholders
    :param params: Tuple or list of parameters
    :param fetchone: If True, returns a single dictionary row
    :param fetchall: If True, returns a list of dictionary rows
    :param commit: If True, commits the transaction and returns lastrowid or affected rows
    :return: Row dict, list of row dicts, or lastrowid/affected rows
    """
    conn = None
    is_pg = bool(Config.SUPABASE_DB_URL)
    in_flask = has_app_context()
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            # PostgreSQL compatibility translation
            if is_pg and "INSERT IGNORE INTO" in sql.upper():
                import re
                sql = re.sub(r'(?i)INSERT\s+IGNORE\s+INTO', 'INSERT INTO', sql)
                if "ON CONFLICT" not in sql.upper():
                    sql = sql.rstrip("; ") + " ON CONFLICT DO NOTHING"

            cursor.execute(sql, params or ())
            
            if commit:
                last_id = None
                if is_pg and sql.strip().upper().startswith('INSERT'):
                    try:
                        cursor.execute("SELECT LASTVAL()")
                        row = cursor.fetchone()
                        last_id = row['lastval'] if isinstance(row, dict) else row[0]
                    except Exception:
                        last_id = None
                conn.commit()
                if is_pg:
                    return last_id if last_id else cursor.rowcount
                else:
                    return cursor.lastrowid if cursor.lastrowid else cursor.rowcount
            
            if fetchone:
                return cursor.fetchone()
                
            if fetchall:
                return cursor.fetchall()
                
            return None
    except Exception as e:
        if conn and commit:
            conn.rollback()
        print(f"[Database Error]: {e} | Query: {sql}")
        raise e
    finally:
        # If running outside a Flask request (standalone script), close immediately.
        # Inside Flask, the connection is preserved in g._db_conn and closed at request teardown.
        if not in_flask and conn:
            conn.close()
