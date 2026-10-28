"""
Contact Model - Data Access Object for contact_messages table.
"""

from utils.database import execute_query

class ContactModel:
    @staticmethod
    def create(name, email, phone, subject, message):
        sql = """
            INSERT INTO contact_messages (name, email, phone, subject, message)
            VALUES (%s, %s, %s, %s, %s)
        """
        return execute_query(sql, (name, email, phone, subject, message), commit=True)

    @staticmethod
    def get_all():
        sql = "SELECT * FROM contact_messages ORDER BY created_at DESC"
        return execute_query(sql, fetchall=True)

    @staticmethod
    def mark_as_read(message_id):
        sql = "UPDATE contact_messages SET is_read = TRUE WHERE id = %s"
        return execute_query(sql, (message_id,), commit=True)

    @staticmethod
    def count_unread():
        sql = "SELECT COUNT(*) AS total FROM contact_messages WHERE is_read = FALSE"
        res = execute_query(sql, fetchone=True)
        return res['total'] if res else 0
