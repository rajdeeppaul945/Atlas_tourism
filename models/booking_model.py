"""
Booking Model - Data Access Object for bookings and booking_travellers tables.
"""

from utils.database import execute_query
from datetime import date

class BookingModel:
    @staticmethod
    def create_booking(booking_number, user_id, package_id, travel_date, adults_count, children_count,
                       base_amount, discount_amount, total_amount, offer_id,
                       contact_name, contact_email, contact_phone, special_requests):
        sql = """
            INSERT INTO bookings 
            (booking_number, user_id, package_id, travel_date, adults_count, children_count,
             base_amount, discount_amount, total_amount, offer_id, contact_name, contact_email,
             contact_phone, special_requests, booking_status)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, 'Pending')
        """
        return execute_query(sql, (
            booking_number, user_id, package_id, travel_date, adults_count, children_count,
            base_amount, discount_amount, total_amount, offer_id,
            contact_name, contact_email, contact_phone, special_requests
        ), commit=True)

    @staticmethod
    def add_traveller(booking_id, full_name, age, gender):
        sql = """
            INSERT INTO booking_travellers (booking_id, full_name, age, gender)
            VALUES (%s, %s, %s, %s)
        """
        return execute_query(sql, (booking_id, full_name, age, gender), commit=True)

    @staticmethod
    def get_by_id(booking_id):
        sql = """
            SELECT b.*, p.name AS package_name, p.duration AS package_duration, p.image_url AS package_image,
                   d.name AS destination_name, d.location AS destination_location,
                   u.full_name AS user_full_name, u.email AS user_email, u.phone AS user_phone,
                   o.code AS offer_code, o.discount_percent AS offer_discount_percent
            FROM bookings b
            JOIN packages p ON b.package_id = p.id
            JOIN destinations d ON p.destination_id = d.id
            JOIN users u ON b.user_id = u.id
            LEFT JOIN offers o ON b.offer_id = o.id
            WHERE b.id = %s
        """
        return execute_query(sql, (booking_id,), fetchone=True)

    @staticmethod
    def get_by_number(booking_number):
        sql = """
            SELECT b.*, p.name AS package_name, p.duration AS package_duration, p.image_url AS package_image,
                   d.name AS destination_name, d.location AS destination_location,
                   u.full_name AS user_full_name, u.email AS user_email,
                   o.code AS offer_code
            FROM bookings b
            JOIN packages p ON b.package_id = p.id
            JOIN destinations d ON p.destination_id = d.id
            JOIN users u ON b.user_id = u.id
            LEFT JOIN offers o ON b.offer_id = o.id
            WHERE b.booking_number = %s
        """
        return execute_query(sql, (booking_number,), fetchone=True)

    @staticmethod
    def get_travellers(booking_id):
        sql = "SELECT * FROM booking_travellers WHERE booking_id = %s ORDER BY id ASC"
        return execute_query(sql, (booking_id,), fetchall=True)

    @staticmethod
    def get_user_bookings(user_id, filter_type=None):
        sql = """
            SELECT b.*, p.name AS package_name, p.duration AS package_duration, p.image_url AS package_image,
                   d.name AS destination_name,
                   pay.payment_status, pay.razorpay_payment_id
            FROM bookings b
            JOIN packages p ON b.package_id = p.id
            JOIN destinations d ON p.destination_id = d.id
            LEFT JOIN payments pay ON b.id = pay.booking_id
            WHERE b.user_id = %s
        """
        params = [user_id]
        today = date.today().strftime('%Y-%m-%d')

        if filter_type == 'upcoming':
            sql += " AND b.travel_date >= %s AND b.booking_status != 'Cancelled'"
            params.append(today)
        elif filter_type == 'completed':
            sql += " AND (b.travel_date < %s OR b.booking_status = 'Completed')"
            params.append(today)

        sql += " ORDER BY b.created_at DESC"
        return execute_query(sql, tuple(params), fetchall=True)

    @staticmethod
    def update_status(booking_id, new_status):
        sql = "UPDATE bookings SET booking_status = %s WHERE id = %s"
        return execute_query(sql, (new_status, booking_id), commit=True)

    @staticmethod
    def get_all(status_filter=None, search=None):
        sql = """
            SELECT b.*, p.name AS package_name, d.name AS destination_name,
                   u.full_name AS user_full_name, u.email AS user_email,
                   pay.payment_status
            FROM bookings b
            JOIN packages p ON b.package_id = p.id
            JOIN destinations d ON p.destination_id = d.id
            JOIN users u ON b.user_id = u.id
            LEFT JOIN payments pay ON b.id = pay.booking_id
            WHERE 1=1
        """
        params = []
        if status_filter:
            sql += " AND b.booking_status = %s"
            params.append(status_filter)
        if search:
            sql += " AND (b.booking_number LIKE %s OR u.full_name LIKE %s OR u.email LIKE %s OR p.name LIKE %s)"
            term = f"%{search}%"
            params.extend([term, term, term, term])

        sql += " ORDER BY b.created_at DESC"
        return execute_query(sql, tuple(params), fetchall=True)

    @staticmethod
    def get_summary_stats():
        stats = {}
        # Total bookings
        res = execute_query("SELECT COUNT(*) AS total FROM bookings", fetchone=True)
        stats['total_bookings'] = res['total'] if res else 0

        # Pending bookings
        res = execute_query("SELECT COUNT(*) AS total FROM bookings WHERE booking_status = 'Pending'", fetchone=True)
        stats['pending_bookings'] = res['total'] if res else 0

        # Confirmed bookings
        res = execute_query("SELECT COUNT(*) AS total FROM bookings WHERE booking_status = 'Confirmed'", fetchone=True)
        stats['confirmed_bookings'] = res['total'] if res else 0

        # Completed bookings
        res = execute_query("SELECT COUNT(*) AS total FROM bookings WHERE booking_status = 'Completed'", fetchone=True)
        stats['completed_bookings'] = res['total'] if res else 0

        # Total revenue from successful payments
        res = execute_query("SELECT COALESCE(SUM(amount), 0) AS total FROM payments WHERE payment_status = 'Success'", fetchone=True)
        stats['total_revenue'] = float(res['total']) if res else 0.0

        return stats

    @staticmethod
    def get_user_dashboard_counts(user_id):
        today = date.today().strftime('%Y-%m-%d')
        # Total
        res_total = execute_query("SELECT COUNT(*) AS total FROM bookings WHERE user_id = %s", (user_id,), fetchone=True)
        # Upcoming
        res_up = execute_query("SELECT COUNT(*) AS total FROM bookings WHERE user_id = %s AND travel_date >= %s AND booking_status != 'Cancelled'", (user_id, today), fetchone=True)
        # Completed
        res_comp = execute_query("SELECT COUNT(*) AS total FROM bookings WHERE user_id = %s AND (travel_date < %s OR booking_status = 'Completed')", (user_id, today), fetchone=True)
        # Wishlist
        res_wish = execute_query("SELECT COUNT(*) AS total FROM wishlist WHERE user_id = %s", (user_id,), fetchone=True)

        return {
            'total_bookings': res_total['total'] if res_total else 0,
            'upcoming_trips': res_up['total'] if res_up else 0,
            'completed_trips': res_comp['total'] if res_comp else 0,
            'wishlist_count': res_wish['total'] if res_wish else 0
        }

    @staticmethod
    def get_monthly_bookings_chart():
        """Returns monthly bookings count for the current calendar year."""
        sql = """
            SELECT MONTHNAME(created_at) AS month_name, MONTH(created_at) AS month_num, COUNT(id) AS booking_count
            FROM bookings
            WHERE YEAR(created_at) = YEAR(CURDATE())
            GROUP BY MONTH(created_at), MONTHNAME(created_at)
            ORDER BY MONTH(created_at) ASC
        """
        return execute_query(sql, fetchall=True)

    @staticmethod
    def get_monthly_revenue_chart():
        """Returns monthly revenue for the current calendar year."""
        sql = """
            SELECT MONTHNAME(created_at) AS month_name, MONTH(created_at) AS month_num, COALESCE(SUM(amount), 0) AS total_revenue
            FROM payments
            WHERE payment_status = 'Success' AND YEAR(created_at) = YEAR(CURDATE())
            GROUP BY MONTH(created_at), MONTHNAME(created_at)
            ORDER BY MONTH(created_at) ASC
        """
        return execute_query(sql, fetchall=True)

    @staticmethod
    def get_popular_destinations_chart():
        """Returns top destinations by booking volume."""
        sql = """
            SELECT d.name AS destination_name, COUNT(b.id) AS total_bookings
            FROM destinations d
            JOIN packages p ON d.id = p.destination_id
            JOIN bookings b ON p.id = b.package_id
            GROUP BY d.id, d.name
            ORDER BY total_bookings DESC
            LIMIT 5
        """
        return execute_query(sql, fetchall=True)

    @staticmethod
    def update_booking_status(booking_id, new_status):
        sql = "UPDATE bookings SET booking_status = %s WHERE id = %s"
        return execute_query(sql, (new_status, booking_id), commit=True)

