"""
Package Model - Data Access Object for packages and package_itinerary tables.
"""

from utils.database import execute_query

class PackageModel:
    @staticmethod
    def get_all(destination_id=None, min_price=None, max_price=None, duration_filter=None, search=None):
        sql = """
            SELECT p.*, d.name AS destination_name, d.location AS destination_location,
                   COALESCE(AVG(r.rating), 5.0) AS avg_rating,
                   COUNT(r.id) AS review_count
            FROM packages p
            JOIN destinations d ON p.destination_id = d.id
            LEFT JOIN reviews r ON p.id = r.package_id AND r.is_approved = TRUE
            WHERE 1=1
        """
        params = []

        if destination_id:
            sql += " AND p.destination_id = %s"
            params.append(destination_id)

        if min_price is not None and str(min_price).strip() != '':
            sql += " AND p.price >= %s"
            params.append(float(min_price))

        if max_price is not None and str(max_price).strip() != '':
            sql += " AND p.price <= %s"
            params.append(float(max_price))

        if duration_filter:
            if duration_filter == 'short':      # 1 to 4 days
                sql += " AND p.duration_days <= 4"
            elif duration_filter == 'medium':   # 5 to 7 days
                sql += " AND p.duration_days BETWEEN 5 AND 7"
            elif duration_filter == 'long':     # 8+ days
                sql += " AND p.duration_days >= 8"

        if search:
            sql += " AND (p.name LIKE %s OR d.name LIKE %s OR p.description LIKE %s)"
            term = f"%{search}%"
            params.extend([term, term, term])

        sql += " GROUP BY p.id ORDER BY p.is_featured DESC, p.created_at DESC"
        return execute_query(sql, tuple(params), fetchall=True)

    @staticmethod
    def get_featured(limit=6):
        sql = """
            SELECT p.*, d.name AS destination_name, d.location AS destination_location,
                   COALESCE(AVG(r.rating), 5.0) AS avg_rating,
                   COUNT(r.id) AS review_count
            FROM packages p
            JOIN destinations d ON p.destination_id = d.id
            LEFT JOIN reviews r ON p.id = r.package_id AND r.is_approved = TRUE
            WHERE p.is_featured = TRUE
            GROUP BY p.id
            ORDER BY p.id ASC
            LIMIT %s
        """
        return execute_query(sql, (limit,), fetchall=True)

    @staticmethod
    def get_by_id(package_id):
        sql = """
            SELECT p.*, d.name AS destination_name, d.location AS destination_location,
                   COALESCE(AVG(r.rating), 5.0) AS avg_rating,
                   COUNT(r.id) AS review_count
            FROM packages p
            JOIN destinations d ON p.destination_id = d.id
            LEFT JOIN reviews r ON p.id = r.package_id AND r.is_approved = TRUE
            WHERE p.id = %s
            GROUP BY p.id
        """
        return execute_query(sql, (package_id,), fetchone=True)

    @staticmethod
    def get_by_destination(destination_id):
        sql = """
            SELECT p.*, d.name AS destination_name
            FROM packages p
            JOIN destinations d ON p.destination_id = d.id
            WHERE p.destination_id = %s
            ORDER BY p.price ASC
        """
        return execute_query(sql, (destination_id,), fetchall=True)

    @staticmethod
    def get_itinerary(package_id):
        sql = """
            SELECT * FROM package_itinerary 
            WHERE package_id = %s 
            ORDER BY day_number ASC
        """
        return execute_query(sql, (package_id,), fetchall=True)

    @staticmethod
    def create(destination_id, name, duration, duration_days, price, hotel_info, transport_info, meals_info, description, inclusions, exclusions, available_dates, image_url, is_featured=False):
        sql = """
            INSERT INTO packages 
            (destination_id, name, duration, duration_days, price, hotel_info, transport_info, meals_info, description, inclusions, exclusions, available_dates, image_url, is_featured)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """
        return execute_query(sql, (destination_id, name, duration, duration_days, price, hotel_info, transport_info, meals_info, description, inclusions, exclusions, available_dates, image_url, is_featured), commit=True)

    @staticmethod
    def update(package_id, destination_id, name, duration, duration_days, price, hotel_info, transport_info, meals_info, description, inclusions, exclusions, available_dates, image_url, is_featured):
        sql = """
            UPDATE packages 
            SET destination_id = %s, name = %s, duration = %s, duration_days = %s, price = %s,
                hotel_info = %s, transport_info = %s, meals_info = %s, description = %s,
                inclusions = %s, exclusions = %s, available_dates = %s, image_url = %s, is_featured = %s
            WHERE id = %s
        """
        return execute_query(sql, (destination_id, name, duration, duration_days, price, hotel_info, transport_info, meals_info, description, inclusions, exclusions, available_dates, image_url, is_featured, package_id), commit=True)

    @staticmethod
    def delete(package_id):
        sql = "DELETE FROM packages WHERE id = %s"
        return execute_query(sql, (package_id,), commit=True)

    @staticmethod
    def count():
        sql = "SELECT COUNT(*) AS total FROM packages"
        res = execute_query(sql, fetchone=True)
        return res['total'] if res else 0

    @staticmethod
    def add_itinerary_day(package_id, day_number, title, description, activities):
        sql = """
            INSERT INTO package_itinerary (package_id, day_number, title, description, activities)
            VALUES (%s, %s, %s, %s, %s)
        """
        return execute_query(sql, (package_id, day_number, title, description, activities), commit=True)

    @staticmethod
    def delete_itinerary(package_id):
        sql = "DELETE FROM package_itinerary WHERE package_id = %s"
        return execute_query(sql, (package_id,), commit=True)
