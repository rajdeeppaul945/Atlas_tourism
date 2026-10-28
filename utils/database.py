"""
Database Utility Module for Atlas Tourism
Provides safe connection management and parameterized query execution
using PyMySQL and dictionary cursors.
"""

import pymysql
import pymysql.cursors
from config import Config

def get_db_connection():
    """
    Establishes and returns a connection to the MySQL database.
    """
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
    Executes a parameterized SQL query safely.
    
    :param sql: SQL query string with %s placeholders
    :param params: Tuple or list of parameters
    :param fetchone: If True, returns a single dictionary row
    :param fetchall: If True, returns a list of dictionary rows
    :param commit: If True, commits the transaction and returns lastrowid or affected rows
    :return: Row dict, list of row dicts, or lastrowid/affected rows
    """
    conn = None
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute(sql, params or ())
            
            if commit:
                conn.commit()
                # Return last inserted id if available, otherwise rows affected
                return cursor.lastrowid if cursor.lastrowid else cursor.rowcount
            
            if fetchone:
                return cursor.fetchone()
                
            if fetchall:
                return cursor.fetchall()
                
            return None
    except pymysql.MySQLError as e:
        if conn and commit:
            conn.rollback()
        print(f"[Database Error]: {e} | Query: {sql}")
        raise e
    finally:
        if conn:
            conn.close()
