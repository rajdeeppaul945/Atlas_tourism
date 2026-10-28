"""
User Model - Data Access Object for users table.
"""

from utils.database import execute_query
from utils.auth import hash_password, verify_password

class UserModel:
    @staticmethod
    def create_user(full_name, username, email, phone, password, role='user', country='India'):
        hashed = hash_password(password)
        sql = """
            INSERT INTO users (full_name, username, email, phone, country, password_hash, role, is_active)
            VALUES (%s, %s, %s, %s, %s, %s, %s, TRUE)
        """
        return execute_query(sql, (full_name, username, email, phone, country, hashed, role), commit=True)

    @staticmethod
    def get_by_id(user_id):
        sql = "SELECT id, full_name, username, email, phone, country, role, is_active, created_at FROM users WHERE id = %s"
        return execute_query(sql, (user_id,), fetchone=True)

    @staticmethod
    def get_by_email(email):
        sql = "SELECT * FROM users WHERE email = %s"
        return execute_query(sql, (email,), fetchone=True)

    @staticmethod
    def get_by_username(username):
        sql = "SELECT * FROM users WHERE username = %s"
        return execute_query(sql, (username,), fetchone=True)

    @staticmethod
    def get_by_identifier(identifier):
        """Allows login via either email or username."""
        sql = "SELECT * FROM users WHERE email = %s OR username = %s"
        return execute_query(sql, (identifier, identifier), fetchone=True)

    @staticmethod
    def authenticate(identifier, password):
        user = UserModel.get_by_identifier(identifier)
        if not user:
            return None, "No account found with that email or username."
        if not user.get('is_active'):
            return None, "Your account has been deactivated. Please contact support."
        if not verify_password(password, user['password_hash']):
            return None, "Incorrect password. Please try again."
        return user, None

    @staticmethod
    def update_profile(user_id, full_name, email, phone, country="India"):
        """Updates safe profile fields; prevents altering role."""
        sql = """
            UPDATE users 
            SET full_name = %s, email = %s, phone = %s, country = %s 
            WHERE id = %s
        """
        return execute_query(sql, (full_name, email, phone, country, user_id), commit=True)

    @staticmethod
    def update_password(user_id, new_password):
        hashed = hash_password(new_password)
        sql = "UPDATE users SET password_hash = %s WHERE id = %s"
        return execute_query(sql, (hashed, user_id), commit=True)

    @staticmethod
    def get_all_users():
        sql = """
            SELECT id, full_name, username, email, phone, role, is_active, created_at 
            FROM users 
            ORDER BY created_at DESC
        """
        return execute_query(sql, fetchall=True)

    @staticmethod
    def toggle_status(user_id, is_active):
        sql = "UPDATE users SET is_active = %s WHERE id = %s"
        return execute_query(sql, (is_active, user_id), commit=True)

    @staticmethod
    def count_users():
        sql = "SELECT COUNT(*) AS total FROM users WHERE role = 'user'"
        res = execute_query(sql, fetchone=True)
        return res['total'] if res else 0
