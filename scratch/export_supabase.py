import sys
import datetime
from decimal import Decimal

# Add project root
sys.path.insert(0, r"C:\Users\rajde\Desktop\2nd Sem Projects\atlas_tourism")
from utils.database import execute_query

BOOL_COLS = {"is_active", "is_featured", "is_approved", "is_read"}

def format_val(col, val):
    if val is None:
        return "NULL"
    if col in BOOL_COLS:
        return "TRUE" if bool(val) else "FALSE"
    elif isinstance(val, bool):
        return "TRUE" if val else "FALSE"
    elif isinstance(val, (int, float, Decimal)):
        return str(val)
    elif isinstance(val, (datetime.date, datetime.datetime)):
        return f"'{val.strftime('%Y-%m-%d %H:%M:%S')}'"
    elif isinstance(val, str):
        # Escape single quotes
        escaped = val.replace("'", "''")
        return f"'{escaped}'"
    else:
        escaped = str(val).replace("'", "''")
        return f"'{escaped}'"

sql_out = []
sql_out.append("-- ============================================================")
sql_out.append("-- ATLAS TOURISM - SUPABASE (POSTGRESQL) MIGRATION SCRIPT")
sql_out.append("-- Generated automatically with all schema & existing data")
sql_out.append("-- ============================================================\n")

sql_out.append("-- 1. Enable UUID & Crypto extensions if needed")
sql_out.append("CREATE EXTENSION IF NOT EXISTS \"pgcrypto\";\n")

sql_out.append("-- 2. Helper MySQL Compatibility Functions in PostgreSQL")
sql_out.append("""
CREATE OR REPLACE FUNCTION YEAR(ts timestamp with time zone) RETURNS integer AS $$
BEGIN
    RETURN EXTRACT(YEAR FROM ts)::integer;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION YEAR(d date) RETURNS integer AS $$
BEGIN
    RETURN EXTRACT(YEAR FROM d)::integer;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION MONTH(ts timestamp with time zone) RETURNS integer AS $$
BEGIN
    RETURN EXTRACT(MONTH FROM ts)::integer;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION MONTHNAME(ts timestamp with time zone) RETURNS text AS $$
BEGIN
    RETURN TO_CHAR(ts, 'Month');
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION CURDATE() RETURNS date AS $$
BEGIN
    RETURN CURRENT_DATE;
END;
$$ LANGUAGE plpgsql STABLE;
""")

# Table definitions in dependency order
tables_schema = [
    """
    DROP TABLE IF EXISTS wishlist_destinations CASCADE;
    DROP TABLE IF EXISTS wishlist CASCADE;
    DROP TABLE IF EXISTS reviews CASCADE;
    DROP TABLE IF EXISTS payments CASCADE;
    DROP TABLE IF EXISTS booking_travellers CASCADE;
    DROP TABLE IF EXISTS bookings CASCADE;
    DROP TABLE IF EXISTS package_itinerary CASCADE;
    DROP TABLE IF EXISTS packages CASCADE;
    DROP TABLE IF EXISTS tour_packages CASCADE;
    DROP TABLE IF EXISTS offers CASCADE;
    DROP TABLE IF EXISTS destinations CASCADE;
    DROP TABLE IF EXISTS contact_messages CASCADE;
    DROP TABLE IF EXISTS users CASCADE;

    CREATE TABLE users (
        id SERIAL PRIMARY KEY,
        full_name VARCHAR(100) NOT NULL,
        username VARCHAR(50) NOT NULL UNIQUE,
        email VARCHAR(100) NOT NULL UNIQUE,
        phone VARCHAR(20) NOT NULL,
        country VARCHAR(100) DEFAULT 'India',
        password_hash VARCHAR(255) NOT NULL,
        role VARCHAR(20) NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
        is_active BOOLEAN NOT NULL DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    """,

    """
    CREATE TABLE destinations (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        location VARCHAR(150) NOT NULL,
        description TEXT NOT NULL,
        starting_price NUMERIC(10,2) NOT NULL DEFAULT 0.00,
        best_time VARCHAR(100) NOT NULL,
        things_to_do TEXT,
        attractions TEXT,
        budget VARCHAR(100),
        image_url VARCHAR(255) NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    """,

    """
    CREATE TABLE offers (
        id SERIAL PRIMARY KEY,
        code VARCHAR(50) NOT NULL UNIQUE,
        description VARCHAR(255),
        discount_percent INT NOT NULL,
        valid_from DATE NOT NULL,
        valid_until DATE NOT NULL,
        is_active BOOLEAN NOT NULL DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    """,

    """
    CREATE TABLE packages (
        id SERIAL PRIMARY KEY,
        destination_id INT NOT NULL REFERENCES destinations(id) ON DELETE CASCADE,
        name VARCHAR(150) NOT NULL,
        duration VARCHAR(50) NOT NULL,
        duration_days INT NOT NULL DEFAULT 1,
        price NUMERIC(10,2) NOT NULL,
        hotel_info VARCHAR(255) NOT NULL,
        transport_info VARCHAR(255) NOT NULL,
        meals_info VARCHAR(255) NOT NULL,
        description TEXT NOT NULL,
        inclusions TEXT,
        exclusions TEXT,
        available_dates VARCHAR(255) DEFAULT 'Every Weekend & Custom Dates',
        image_url VARCHAR(255) NOT NULL,
        is_featured BOOLEAN NOT NULL DEFAULT FALSE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    """,

    """
    CREATE TABLE package_itinerary (
        id SERIAL PRIMARY KEY,
        package_id INT NOT NULL REFERENCES packages(id) ON DELETE CASCADE,
        day_number INT NOT NULL,
        title VARCHAR(150) NOT NULL,
        description TEXT NOT NULL,
        activities TEXT
    );
    """,

    """
    CREATE TABLE bookings (
        id SERIAL PRIMARY KEY,
        booking_number VARCHAR(30) NOT NULL UNIQUE,
        user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        package_id INT NOT NULL REFERENCES packages(id) ON DELETE CASCADE,
        travel_date DATE NOT NULL,
        adults_count INT NOT NULL DEFAULT 1,
        children_count INT NOT NULL DEFAULT 0,
        base_amount NUMERIC(10,2) NOT NULL,
        discount_amount NUMERIC(10,2) NOT NULL DEFAULT 0.00,
        total_amount NUMERIC(10,2) NOT NULL,
        offer_id INT REFERENCES offers(id) ON DELETE SET NULL,
        contact_name VARCHAR(100) NOT NULL,
        contact_email VARCHAR(100) NOT NULL,
        contact_phone VARCHAR(20) NOT NULL,
        special_requests TEXT,
        booking_status VARCHAR(20) NOT NULL DEFAULT 'Pending' CHECK (booking_status IN ('Pending', 'Confirmed', 'Completed', 'Cancelled')),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    """,

    """
    CREATE TABLE booking_travellers (
        id SERIAL PRIMARY KEY,
        booking_id INT NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
        full_name VARCHAR(100) NOT NULL,
        age INT NOT NULL,
        gender VARCHAR(20) NOT NULL
    );
    """,

    """
    CREATE TABLE payments (
        id SERIAL PRIMARY KEY,
        booking_id INT NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
        user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        razorpay_order_id VARCHAR(100),
        razorpay_payment_id VARCHAR(100),
        razorpay_signature VARCHAR(255),
        amount NUMERIC(10,2) NOT NULL,
        currency VARCHAR(10) NOT NULL DEFAULT 'INR',
        payment_method VARCHAR(50) NOT NULL DEFAULT 'Razorpay',
        payment_status VARCHAR(20) NOT NULL DEFAULT 'Pending' CHECK (payment_status IN ('Success', 'Pending', 'Failed')),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    """,

    """
    CREATE TABLE reviews (
        id SERIAL PRIMARY KEY,
        user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        package_id INT NOT NULL REFERENCES packages(id) ON DELETE CASCADE,
        booking_id INT REFERENCES bookings(id) ON DELETE SET NULL,
        rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
        review_text TEXT NOT NULL,
        is_approved BOOLEAN NOT NULL DEFAULT FALSE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    """,

    """
    CREATE TABLE tour_packages (
        id SERIAL PRIMARY KEY,
        title VARCHAR(150) NOT NULL,
        description TEXT NOT NULL,
        location VARCHAR(100) NOT NULL,
        price NUMERIC(10,2) NOT NULL,
        duration_days INT NOT NULL,
        image_url VARCHAR(255),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    """,

    """
    CREATE TABLE contact_messages (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        email VARCHAR(100) NOT NULL,
        phone VARCHAR(20),
        subject VARCHAR(150) NOT NULL,
        message TEXT NOT NULL,
        is_read BOOLEAN NOT NULL DEFAULT FALSE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    """,

    """
    CREATE TABLE wishlist (
        id SERIAL PRIMARY KEY,
        user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        package_id INT NOT NULL REFERENCES packages(id) ON DELETE CASCADE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT unique_user_package_wishlist UNIQUE (user_id, package_id)
    );
    """,

    """
    CREATE TABLE wishlist_destinations (
        id SERIAL PRIMARY KEY,
        user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        destination_id INT NOT NULL REFERENCES destinations(id) ON DELETE CASCADE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT unique_user_dest UNIQUE (user_id, destination_id)
    );
    """
]

for stmt in tables_schema:
    sql_out.append(stmt.strip())
    sql_out.append("")

data_tables = [
    "users",
    "destinations",
    "offers",
    "packages",
    "package_itinerary",
    "bookings",
    "booking_travellers",
    "payments",
    "reviews",
    "tour_packages",
    "contact_messages",
    "wishlist",
    "wishlist_destinations"
]

sql_out.append("-- ============================================================")
sql_out.append("-- DATA INSERTION")
sql_out.append("-- ============================================================\n")

for tbl in data_tables:
    rows = execute_query(f"SELECT * FROM `{tbl}`", fetchall=True)
    if not rows:
        continue
    
    cols = list(rows[0].keys())
    col_names = ", ".join([f'"{c}"' for c in cols])
    
    sql_out.append(f"-- Data for {tbl} ({len(rows)} rows)")
    for r in rows:
        vals = [format_val(c, r[c]) for c in cols]
        val_str = ", ".join(vals)
        sql_out.append(f"INSERT INTO {tbl} ({col_names}) VALUES ({val_str});")
    
    sql_out.append(f"SELECT setval(pg_get_serial_sequence('{tbl}', 'id'), COALESCE(MAX(id), 1)) FROM {tbl};\n")

export_path = r"C:\Users\rajde\Desktop\2nd Sem Projects\atlas_tourism\supabase_migration.sql"
with open(export_path, "w", encoding="utf-8") as f:
    f.write("\n".join(sql_out))

print(f"Generated {export_path} successfully!")
