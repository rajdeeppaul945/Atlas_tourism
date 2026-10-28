"""
Destination Model - Data Access Object for destinations table.
"""

from utils.database import execute_query

class DestinationModel:
    @staticmethod
    def get_all():
        sql = """
            SELECT d.*, COUNT(p.id) AS package_count 
            FROM destinations d
            LEFT JOIN packages p ON d.id = p.destination_id
            GROUP BY d.id
            ORDER BY d.name ASC
        """
        return execute_query(sql, fetchall=True)

    @staticmethod
    def get_by_id(destination_id):
        sql = "SELECT * FROM destinations WHERE id = %s"
        return execute_query(sql, (destination_id,), fetchone=True)

    @staticmethod
    def search(query):
        sql = """
            SELECT d.*, COUNT(p.id) AS package_count 
            FROM destinations d
            LEFT JOIN packages p ON d.id = p.destination_id
            WHERE d.name LIKE %s OR d.location LIKE %s OR d.description LIKE %s
            GROUP BY d.id
            ORDER BY d.name ASC
        """
        term = f"%{query}%"
        return execute_query(sql, (term, term, term), fetchall=True)

    @staticmethod
    def create(name, location, description, starting_price, best_time, things_to_do, attractions, budget, image_url):
        sql = """
            INSERT INTO destinations 
            (name, location, description, starting_price, best_time, things_to_do, attractions, budget, image_url)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        """
        return execute_query(sql, (name, location, description, starting_price, best_time, things_to_do, attractions, budget, image_url), commit=True)

    @staticmethod
    def update(destination_id, name, location, description, starting_price, best_time, things_to_do, attractions, budget, image_url):
        sql = """
            UPDATE destinations 
            SET name = %s, location = %s, description = %s, starting_price = %s,
                best_time = %s, things_to_do = %s, attractions = %s, budget = %s, image_url = %s
            WHERE id = %s
        """
        return execute_query(sql, (name, location, description, starting_price, best_time, things_to_do, attractions, budget, image_url, destination_id), commit=True)

    @staticmethod
    def delete(destination_id):
        sql = "DELETE FROM destinations WHERE id = %s"
        return execute_query(sql, (destination_id,), commit=True)

    @staticmethod
    def count():
        sql = "SELECT COUNT(*) AS total FROM destinations"
        res = execute_query(sql, fetchone=True)
        return res['total'] if res else 0
