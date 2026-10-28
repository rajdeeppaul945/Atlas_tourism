"""
Review Model - Data Access Object for package reviews.
"""

from utils.database import execute_query

class ReviewModel:
    @staticmethod
    def create(user_id, package_id, booking_id, rating, review_text, is_approved=True):
        sql = """
            INSERT INTO reviews (user_id, package_id, booking_id, rating, review_text, is_approved)
            VALUES (%s, %s, %s, %s, %s, %s)
        """
        return execute_query(sql, (user_id, package_id, booking_id, rating, review_text, is_approved), commit=True)

    @staticmethod
    def get_approved_for_package(package_id):
        sql = """
            SELECT r.*, u.full_name AS user_name, u.username
            FROM reviews r
            JOIN users u ON r.user_id = u.id
            WHERE r.package_id = %s AND r.is_approved = TRUE
            ORDER BY r.created_at DESC
        """
        return execute_query(sql, (package_id,), fetchall=True)

    @staticmethod
    def get_featured_reviews(limit=6):
        sql = """
            SELECT r.*, u.full_name AS user_name, p.name AS package_name, d.name AS destination_name
            FROM reviews r
            JOIN users u ON r.user_id = u.id
            JOIN packages p ON r.package_id = p.id
            JOIN destinations d ON p.destination_id = d.id
            WHERE r.is_approved = TRUE
            ORDER BY r.rating DESC, r.created_at DESC
            LIMIT %s
        """
        return execute_query(sql, (limit,), fetchall=True)

    @staticmethod
    def get_user_reviews(user_id):
        sql = """
            SELECT r.*, p.name AS package_name, p.image_url AS package_image
            FROM reviews r
            JOIN packages p ON r.package_id = p.id
            WHERE r.user_id = %s
            ORDER BY r.created_at DESC
        """
        return execute_query(sql, (user_id,), fetchall=True)

    @staticmethod
    def get_all_for_admin():
        sql = """
            SELECT r.*, u.full_name AS user_name, u.email AS user_email,
                   p.name AS package_name, b.booking_number
            FROM reviews r
            JOIN users u ON r.user_id = u.id
            JOIN packages p ON r.package_id = p.id
            LEFT JOIN bookings b ON r.booking_id = b.id
            ORDER BY r.created_at DESC
        """
        return execute_query(sql, fetchall=True)

    @staticmethod
    def approve(review_id):
        sql = "UPDATE reviews SET is_approved = TRUE WHERE id = %s"
        return execute_query(sql, (review_id,), commit=True)

    @staticmethod
    def delete(review_id):
        sql = "DELETE FROM reviews WHERE id = %s"
        return execute_query(sql, (review_id,), commit=True)

    @staticmethod
    def count():
        sql = "SELECT COUNT(*) AS total FROM reviews"
        res = execute_query(sql, fetchone=True)
        return res['total'] if res else 0
