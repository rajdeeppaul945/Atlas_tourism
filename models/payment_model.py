"""
Payment Model - Data Access Object for payments table.
Strictly ensures no raw card details or sensitive PAN data is saved.
"""

from utils.database import execute_query

class PaymentModel:
    @staticmethod
    def create_payment(booking_id, user_id, razorpay_order_id, razorpay_payment_id,
                       razorpay_signature, amount, currency='INR', payment_method='Razorpay',
                       payment_status='Success'):
        sql = """
            INSERT INTO payments 
            (booking_id, user_id, razorpay_order_id, razorpay_payment_id, razorpay_signature,
             amount, currency, payment_method, payment_status)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        """
        return execute_query(sql, (
            booking_id, user_id, razorpay_order_id, razorpay_payment_id,
            razorpay_signature, amount, currency, payment_method, payment_status
        ), commit=True)

    @staticmethod
    def get_by_booking_id(booking_id):
        sql = "SELECT * FROM payments WHERE booking_id = %s ORDER BY id DESC"
        return execute_query(sql, (booking_id,), fetchone=True)

    @staticmethod
    def get_all():
        sql = """
            SELECT py.*, b.booking_number, u.full_name AS user_name, u.email AS user_email,
                   p.name AS package_name
            FROM payments py
            JOIN bookings b ON py.booking_id = b.id
            JOIN users u ON py.user_id = u.id
            JOIN packages p ON b.package_id = p.id
            ORDER BY py.created_at DESC
        """
        return execute_query(sql, fetchall=True)

    @staticmethod
    def count():
        sql = "SELECT COUNT(*) AS total FROM payments"
        res = execute_query(sql, fetchone=True)
        return res['total'] if res else 0
