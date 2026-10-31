"""
Database Utility Module for Atlas Tourism
Provides safe connection management and parameterized query execution
supporting both Supabase (PostgreSQL) and local MySQL seamlessly.
"""

from config import Config

def get_db_connection():
    """
    Establishes and returns a database connection.
    If SUPABASE_DB_URL is set in environment, connects to Supabase PostgreSQL.
    Otherwise falls back to local MySQL.
    """
    if Config.SUPABASE_DB_URL:
        import psycopg2
        from psycopg2.extras import RealDictCursor
        return psycopg2.connect(Config.SUPABASE_DB_URL, cursor_factory=RealDictCursor)
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
        if conn:
            conn.close()
