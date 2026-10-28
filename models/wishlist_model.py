"""
Wishlist Model - Data Access Object for user wishlist (Packages & Destinations).
"""

from utils.database import execute_query

class WishlistModel:
    # --- Package Wishlist Methods ---
    @staticmethod
    def add(user_id, package_id):
        # Prevent duplicates using INSERT IGNORE
        sql = "INSERT IGNORE INTO wishlist (user_id, package_id) VALUES (%s, %s)"
        return execute_query(sql, (user_id, package_id), commit=True)

    @staticmethod
    def remove(user_id, package_id):
        sql = "DELETE FROM wishlist WHERE user_id = %s AND package_id = %s"
        return execute_query(sql, (user_id, package_id), commit=True)

    @staticmethod
    def toggle(user_id, package_id):
        if WishlistModel.is_in_wishlist(user_id, package_id):
            WishlistModel.remove(user_id, package_id)
            return False  # Removed
        else:
            WishlistModel.add(user_id, package_id)
            return True   # Added

    @staticmethod
    def is_in_wishlist(user_id, package_id):
        sql = "SELECT id FROM wishlist WHERE user_id = %s AND package_id = %s"
        return execute_query(sql, (user_id, package_id), fetchone=True) is not None

    @staticmethod
    def get_by_user(user_id):
        sql = """
            SELECT w.id AS wishlist_id, w.created_at AS added_at,
                   p.*, d.name AS destination_name, d.location AS destination_location,
                   COALESCE(AVG(r.rating), 5.0) AS avg_rating
            FROM wishlist w
            JOIN packages p ON w.package_id = p.id
            JOIN destinations d ON p.destination_id = d.id
            LEFT JOIN reviews r ON p.id = r.package_id AND r.is_approved = TRUE
            WHERE w.user_id = %s
            GROUP BY w.id, p.id
            ORDER BY w.created_at DESC
        """
        return execute_query(sql, (user_id,), fetchall=True)

    @staticmethod
    def get_user_package_ids(user_id):
        sql = "SELECT package_id FROM wishlist WHERE user_id = %s"
        rows = execute_query(sql, (user_id,), fetchall=True)
        return {r['package_id'] for r in rows} if rows else set()

    # --- Destination Wishlist Methods ---
    @staticmethod
    def add_destination(user_id, destination_id):
        sql = "INSERT IGNORE INTO wishlist_destinations (user_id, destination_id) VALUES (%s, %s)"
        return execute_query(sql, (user_id, destination_id), commit=True)

    @staticmethod
    def remove_destination(user_id, destination_id):
        sql = "DELETE FROM wishlist_destinations WHERE user_id = %s AND destination_id = %s"
        return execute_query(sql, (user_id, destination_id), commit=True)

    @staticmethod
    def toggle_destination(user_id, destination_id):
        if WishlistModel.is_destination_in_wishlist(user_id, destination_id):
            WishlistModel.remove_destination(user_id, destination_id)
            return False  # Removed
        else:
            WishlistModel.add_destination(user_id, destination_id)
            return True   # Added

    @staticmethod
    def is_destination_in_wishlist(user_id, destination_id):
        sql = "SELECT id FROM wishlist_destinations WHERE user_id = %s AND destination_id = %s"
        return execute_query(sql, (user_id, destination_id), fetchone=True) is not None

    @staticmethod
    def get_user_destination_ids(user_id):
        sql = "SELECT destination_id FROM wishlist_destinations WHERE user_id = %s"
        rows = execute_query(sql, (user_id,), fetchall=True)
        return {r['destination_id'] for r in rows} if rows else set()

    @staticmethod
    def get_destinations_by_user(user_id):
        sql = """
            SELECT wd.id AS wishlist_id, wd.created_at AS added_at,
                   d.*,
                   COUNT(p.id) AS package_count
            FROM wishlist_destinations wd
            JOIN destinations d ON wd.destination_id = d.id
            LEFT JOIN packages p ON d.id = p.destination_id
            WHERE wd.user_id = %s
            GROUP BY wd.id, d.id
            ORDER BY wd.created_at DESC
        """
        return execute_query(sql, (user_id,), fetchall=True)

    # --- Combined Count ---
    @staticmethod
    def count(user_id):
        pkg_res = execute_query("SELECT COUNT(*) AS total FROM wishlist WHERE user_id = %s", (user_id,), fetchone=True)
        pkg_count = pkg_res['total'] if pkg_res else 0
        dest_res = execute_query("SELECT COUNT(*) AS total FROM wishlist_destinations WHERE user_id = %s", (user_id,), fetchone=True)
        dest_count = dest_res['total'] if dest_res else 0
        return pkg_count + dest_count
