"""
Offer Model - Data Access Object for promo codes and discounts.
"""

from utils.database import execute_query
from datetime import date

class OfferModel:
    @staticmethod
    def get_valid_offer(code):
        """Verifies if code is active and currently within valid dates."""
        today = date.today().strftime('%Y-%m-%d')
        sql = """
            SELECT * FROM offers 
            WHERE code = %s AND is_active = TRUE AND valid_from <= %s AND valid_until >= %s
        """
        return execute_query(sql, (code.strip().upper(), today, today), fetchone=True)

    @staticmethod
    def get_by_id(offer_id):
        sql = "SELECT * FROM offers WHERE id = %s"
        return execute_query(sql, (offer_id,), fetchone=True)

    @staticmethod
    def get_all():
        sql = "SELECT * FROM offers ORDER BY id DESC"
        return execute_query(sql, fetchall=True)

    @staticmethod
    def create(code, description, discount_percent, valid_from, valid_until, is_active=True):
        sql = """
            INSERT INTO offers (code, description, discount_percent, valid_from, valid_until, is_active)
            VALUES (%s, %s, %s, %s, %s, %s)
        """
        return execute_query(sql, (code.strip().upper(), description, discount_percent, valid_from, valid_until, is_active), commit=True)

    @staticmethod
    def update(offer_id, code, description, discount_percent, valid_from, valid_until, is_active):
        sql = """
            UPDATE offers 
            SET code = %s, description = %s, discount_percent = %s,
                valid_from = %s, valid_until = %s, is_active = %s
            WHERE id = %s
        """
        return execute_query(sql, (code.strip().upper(), description, discount_percent, valid_from, valid_until, is_active, offer_id), commit=True)

    @staticmethod
    def delete(offer_id):
        sql = "DELETE FROM offers WHERE id = %s"
        return execute_query(sql, (offer_id,), commit=True)

    @staticmethod
    def toggle_status(offer_id, is_active):
        sql = "UPDATE offers SET is_active = %s WHERE id = %s"
        return execute_query(sql, (is_active, offer_id), commit=True)
