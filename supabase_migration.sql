-- ============================================================
-- ATLAS TOURISM - SUPABASE (POSTGRESQL) MIGRATION SCRIPT
-- Generated automatically with all schema & existing data
-- ============================================================

-- 1. Enable UUID & Crypto extensions if needed
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. Helper MySQL Compatibility Functions in PostgreSQL

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

CREATE TABLE package_itinerary (
        id SERIAL PRIMARY KEY,
        package_id INT NOT NULL REFERENCES packages(id) ON DELETE CASCADE,
        day_number INT NOT NULL,
        title VARCHAR(150) NOT NULL,
        description TEXT NOT NULL,
        activities TEXT
    );

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

CREATE TABLE booking_travellers (
        id SERIAL PRIMARY KEY,
        booking_id INT NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
        full_name VARCHAR(100) NOT NULL,
        age INT NOT NULL,
        gender VARCHAR(20) NOT NULL
    );

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

CREATE TABLE wishlist (
        id SERIAL PRIMARY KEY,
        user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        package_id INT NOT NULL REFERENCES packages(id) ON DELETE CASCADE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT unique_user_package_wishlist UNIQUE (user_id, package_id)
    );

CREATE TABLE wishlist_destinations (
        id SERIAL PRIMARY KEY,
        user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        destination_id INT NOT NULL REFERENCES destinations(id) ON DELETE CASCADE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT unique_user_dest UNIQUE (user_id, destination_id)
    );

-- ============================================================
-- DATA INSERTION
-- ============================================================

-- Data for users (16 rows)
INSERT INTO users ("id", "full_name", "username", "email", "phone", "country", "password_hash", "role", "is_active", "created_at") VALUES (1, 'System Administrator', 'admin', 'admin@atlastourism.com', '+91 9876543210', 'India', 'scrypt:32768:8:1$ocUWsRrTriOXtwm3$ac3e5e90aacb290af6ab0027968e08fdcf8ab14ad43f40e0e2a51dee3be2f8d81f553799ca53774fde7c0f79706b9bf638d7af0e52b62bad389c51bec9ede74f', 'admin', TRUE, '2026-09-21 19:53:30');
INSERT INTO users ("id", "full_name", "username", "email", "phone", "country", "password_hash", "role", "is_active", "created_at") VALUES (2, 'John Traveller', 'john_traveller', 'john@example.com', '+91 9811223344', 'India', 'scrypt:32768:8:1$UHtIzRpjW2oVGSiH$740a6dba172b9f7ded000ee70e0ffed58fc0b81e7951244d8b070c0a1f880658f98a2d20f5328a666b1290f58691e7ef031c2d6c6053e31ca3c09e047ebe4e39', 'user', TRUE, '2026-09-21 19:53:30');
INSERT INTO users ("id", "full_name", "username", "email", "phone", "country", "password_hash", "role", "is_active", "created_at") VALUES (3, 'Priya Sharma', 'priya_sharma', 'priya@example.com', '+91 9877665544', 'India', 'scrypt:32768:8:1$UHtIzRpjW2oVGSiH$740a6dba172b9f7ded000ee70e0ffed58fc0b81e7951244d8b070c0a1f880658f98a2d20f5328a666b1290f58691e7ef031c2d6c6053e31ca3c09e047ebe4e39', 'user', TRUE, '2026-09-21 19:53:30');
INSERT INTO users ("id", "full_name", "username", "email", "phone", "country", "password_hash", "role", "is_active", "created_at") VALUES (4, 'RAJDEEP PAUL', 'rajdeeppaul850@gmail.com', 'rajdeeppaul945@gmail.com', '+916901850476', 'India', 'scrypt:32768:8:1$WfJod2p1cLMCOeDa$5375ae4f0002666b52d39c4d668fb126c3c13e20151467c885fd966853fba2399541888f5118aa5e78237a71206dfa7de236d9ae116a991e17a129a9c448fe50', 'user', TRUE, '2026-09-21 20:06:32');
INSERT INTO users ("id", "full_name", "username", "email", "phone", "country", "password_hash", "role", "is_active", "created_at") VALUES (5, 'Neymar', 'Neymar@123', 'neymarjr112@gmail.com', '9822364790', 'India', 'scrypt:32768:8:1$gCXf7S8HrAoGFWrA$93b6825cad6671ed24189a2988de725af6c56739389c1334804d306a0998bf8e4f0c4e33cd30ebdf883e22b9f0ba27d8d22d54031aae418a57257f09ddbe4f49', 'user', TRUE, '2026-09-22 01:21:29');
INSERT INTO users ("id", "full_name", "username", "email", "phone", "country", "password_hash", "role", "is_active", "created_at") VALUES (6, 'Sam', 'sam@20', 'sam@gmail.com', '1234567890', 'India', 'scrypt:32768:8:1$onbsuN6hBCk8umpF$e07a43164b8b41cc5f9a27d7dc9964e435fd7e0155a1e214d4fc52ed7d948516698ff49f2eddf985088bb6e0536cd8fd8568c980b025f60dc606aa9ddcf4f7dd', 'user', TRUE, '2026-09-22 09:46:01');
INSERT INTO users ("id", "full_name", "username", "email", "phone", "country", "password_hash", "role", "is_active", "created_at") VALUES (7, 'navi manus', 'manus2004', 'manus@gmail.com', '+91 89567 42534', 'India', 'scrypt:32768:8:1$h38Rqy9bwbs7Ysx7$8c88a810d7872c8275de2f9b6a4059185960f984f88fc6230f7dcc8ea903455a8d36a73a6d7a5a969b4894d9b5ab909ec11541980afe990925e5440119507fc1', 'user', TRUE, '2026-09-22 11:05:21');
INSERT INTO users ("id", "full_name", "username", "email", "phone", "country", "password_hash", "role", "is_active", "created_at") VALUES (8, 'mukesh', 'mukesh123', 'mukesh@123.com', '773966455222', 'India', 'scrypt:32768:8:1$fMgPOVKoo9C0TbeK$ed8b4d80e2736088db7b35df6c7ca74656b6ae233c5f3b55f753f90814aee18c3e403d8d85f610cdac99121d32d888486094ec3b8b8ed24bcffd2cad4d720667', 'user', TRUE, '2026-10-13 10:47:20');
INSERT INTO users ("id", "full_name", "username", "email", "phone", "country", "password_hash", "role", "is_active", "created_at") VALUES (9, 'Abhishek', 'abhi', 'abhishek223@gmail.com', '8957641255', 'India', 'scrypt:32768:8:1$4OPgYbO0JTIexAjs$9c7061ab20cfa82eef87172531bdf1a6ac7a7df0e19615fbc36b4ccfee4d1e77fd6390fe9b99b38339753684073ae8b828db0ee6b62cc69ac0f10fcf05c0425a', 'user', TRUE, '2026-10-18 22:40:11');
INSERT INTO users ("id", "full_name", "username", "email", "phone", "country", "password_hash", "role", "is_active", "created_at") VALUES (10, 'test_case', 'qwerty1234', 'qwerty@as.zxc', '32540652', 'India', 'scrypt:32768:8:1$RnG2qLq5J2NSzMKX$42a16ee05a6c1c34020ad8413215b8758b733b238efe0bebee87823b7fb1ae89ad011a132ac749805a28465f7edc715ad785cbe00696f9488e867b03148a2f4f', 'user', TRUE, '2026-10-28 03:29:16');
INSERT INTO users ("id", "full_name", "username", "email", "phone", "country", "password_hash", "role", "is_active", "created_at") VALUES (11, 'Ram', 'ram26', 'ram@gmail.com', '+91 98653 27415', 'India', 'scrypt:32768:8:1$7KB1zMBmtABIfRQu$48d6990416d8b739bad1447c1e80d99473cac3f3ea2e6abbd57c70af164d7b35cc7bd9fdd27d1aa557b7261ae7838d2b55c5c7c0475bb2f2c0f28c52d7b3783e', 'user', TRUE, '2026-10-28 10:03:11');
INSERT INTO users ("id", "full_name", "username", "email", "phone", "country", "password_hash", "role", "is_active", "created_at") VALUES (12, 'Rohit', 'rohitkumud', 'rohit@yahoo.com', '+91 99005 29390', 'India', 'scrypt:32768:8:1$AUPNXCv72im5qeLt$05367fcc2065498b27eca0683e9cbb9764d0765fdbc64dd2f5081cbe610a23561d745b88b829bf53a1cad022649250ea411df908ae72783895ab9e5cb69c7a21', 'user', TRUE, '2026-10-28 10:25:25');
INSERT INTO users ("id", "full_name", "username", "email", "phone", "country", "password_hash", "role", "is_active", "created_at") VALUES (14, 'RAJDEEP PAUL', 'raj945', 'rajdeeppaul850@gmail.com', '+91 69018 50476', 'India', 'scrypt:32768:8:1$CH4N4rPUO6NpvnZw$b9965a30a22a231b5682fa46b5b0f0a7d502a3e866c957df584ce49c6f5fc0a24710f602290b2df4c31fc5dea8c51a954cdee70ceb70ebb4aae9e7916222a9c5', 'user', TRUE, '2026-10-28 13:04:58');
INSERT INTO users ("id", "full_name", "username", "email", "phone", "country", "password_hash", "role", "is_active", "created_at") VALUES (15, '12345', '123qq', '12345@gmail.com', '+91 89745 78542', 'India', 'scrypt:32768:8:1$1GDdPeQtE6CugZIA$d5fb94b9c1f0b7fb3529f383601b2d5d222f5b464b7717b7b8b6a35e61fcf79fc98021a7bfcce83541687d342a1638fed63ecf3b2bda9ca68bafe73eec051f1f', 'user', TRUE, '2026-10-30 12:15:51');
INSERT INTO users ("id", "full_name", "username", "email", "phone", "country", "password_hash", "role", "is_active", "created_at") VALUES (16, 'RR', 'rrr', 'rajdeeppaul11@gmail.com', '+91 69018 50476', 'India', 'scrypt:32768:8:1$Djy6XHeBew2zahug$a8edd43ea46be23c5521a1b28e59ebd932a37f294101faeea326ef22a6600bb0ac26ebc9eeec14b90508cdec48e29db4293fe163c1bbdb8473c229b028f1a6e1', 'user', TRUE, '2026-10-31 16:28:49');
INSERT INTO users ("id", "full_name", "username", "email", "phone", "country", "password_hash", "role", "is_active", "created_at") VALUES (17, 'Abhishek', 'abhishek2024', 'abhishek2024@gmail.com', '+91 98658 54725', 'India', 'scrypt:32768:8:1$Icad6pWezVevi6CU$5b5a089876f722c0a635e8aa3d0ff975862cf013c771d2bae20be79d75a848b911db90e286fc8843b65a0a8ff41aaf56935c4f2d1de49590e45d855450ff17a2', 'user', TRUE, '2026-10-31 16:31:34');
SELECT setval(pg_get_serial_sequence('users', 'id'), COALESCE(MAX(id), 1)) FROM users;

-- Data for destinations (5 rows)
INSERT INTO destinations ("id", "name", "location", "description", "starting_price", "best_time", "things_to_do", "attractions", "budget", "image_url", "created_at") VALUES (1, 'Nepal & Himalayas', 'Nepal', 'Experience the rooftop of the world. Nestled against the mighty Himalayan peaks, Nepal offers ancient UNESCO heritage temples in Kathmandu, serene lakeside retreats in Pokhara, and world-renowned alpine trekking routes.', 24999.00, 'September to May', 'Mountain trekking, White-water rafting, Paragliding in Pokhara, Temple heritage walks, Jungle safari in Chitwan', 'Pashupatinath Temple, Phewa Lake, Annapurna Sanctuary, Swayambhunath Stupa, Bhaktapur Durbar Square', '₹25,000 - ₹55,000 per person', 'https://images.unsplash.com/photo-1544735716-392fe2489ffa?auto=format&fit=crop&w=1200&q=80', '2026-09-21 19:53:30');
INSERT INTO destinations ("id", "name", "location", "description", "starting_price", "best_time", "things_to_do", "attractions", "budget", "image_url", "created_at") VALUES (2, 'Darjeeling', 'West Bengal, India', 'Known as the "Queen of the Hills", Darjeeling charms travellers with rolling emerald tea gardens, the heritage Himalayan Toy Train, breathtaking sunrise vistas over Mount Kanchenjunga, and rich colonial legacy.', 14999.00, 'October to March', 'Tiger Hill sunrise photography, Toy train heritage ride, Tea tasting at Happy Valley, Batasia Loop walk, Peace Pagoda visit', 'Tiger Hill, Batasia Loop, Himalayan Mountaineering Institute, Ghoom Monastery, Nightingale Park', '₹15,000 - ₹30,000 per person', 'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?auto=format&fit=crop&w=1200&q=80', '2026-09-21 19:53:30');
INSERT INTO destinations ("id", "name", "location", "description", "starting_price", "best_time", "things_to_do", "attractions", "budget", "image_url", "created_at") VALUES (3, 'Varanasi', 'Uttar Pradesh, India', 'One of the oldest continuously inhabited cities on earth, Varanasi is the spiritual heart of India. Revered ghats along the sacred Ganges River, hypnotic evening Ganga Aarti, and profound spiritual tranquility await.', 11999.00, 'October to March', 'Sunrise boat cruise on the Ganga, Witnessing Dashashwamedh Ganga Aarti, Exploring ancient silk lanes, Sarnath Buddhist tour', 'Kashi Vishwanath Temple, Dashashwamedh Ghat, Assi Ghat, Sarnath Deer Park, Manikarnika Ghat', '₹12,000 - ₹25,000 per person', 'https://images.unsplash.com/photo-1627894483216-2138af692e32?q=80&w=687&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D', '2026-09-21 19:53:30');
INSERT INTO destinations ("id", "name", "location", "description", "starting_price", "best_time", "things_to_do", "attractions", "budget", "image_url", "created_at") VALUES (4, 'Shillong & Meghalaya', 'Meghalaya, India', 'Dubbed the "Scotland of the East", Shillong captivates with mist-covered pine hills, roaring waterfalls, crystal-clear Umngot river in Dawki, and wonderous UNESCO-nominated living root bridges in Cherrapunji.', 18999.00, 'October to April', 'Boating on glassy Dawki River, Trekking double decker root bridges, Exploring Mawsmai Caves, Visiting Elephant Falls', 'Elephant Falls, Umiam Lake, Nohkalikai Falls, Living Root Bridges, Dawki Umngot River', '₹18,000 - ₹40,000 per person', 'https://images.unsplash.com/photo-1593813738953-fb3c93e0769d?q=80&w=1254&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D', '2026-09-21 19:53:30');
INSERT INTO destinations ("id", "name", "location", "description", "starting_price", "best_time", "things_to_do", "attractions", "budget", "image_url", "created_at") VALUES (5, 'Andaman & Nicobar', 'Union Territory, India', 'An exotic tropical paradise blessed with turquoise waters, pristine white sandy beaches, lush coastal rainforests, historical colonial landmarks, and vibrant coral reef marine ecosystems.', 28999.00, 'November to May', 'Scuba diving and sea-walking at Havelock, Snorkeling at Elephant Beach, Cellular Jail Light & Sound show, Radhanagar sunset', 'Radhanagar Beach, Cellular Jail, Elephant Beach, Ross Island, Neil Island (Shaheed Dweep)', '₹30,000 - ₹65,000 per person', 'https://images.unsplash.com/photo-1640618792277-b91f3199f6a8?q=80&w=1074&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D', '2026-09-21 19:53:30');
SELECT setval(pg_get_serial_sequence('destinations', 'id'), COALESCE(MAX(id), 1)) FROM destinations;

-- Data for offers (3 rows)
INSERT INTO offers ("id", "code", "description", "discount_percent", "valid_from", "valid_until", "is_active", "created_at") VALUES (1, 'EXPLORE15', 'Flat 15% discount on all tour packages', 15, '2026-01-01 00:00:00', '2026-12-31 00:00:00', TRUE, '2026-09-21 19:53:30');
INSERT INTO offers ("id", "code", "description", "discount_percent", "valid_from", "valid_until", "is_active", "created_at") VALUES (2, 'SUMMER20', 'Special Summer Holiday 20% Discount', 20, '2026-03-01 00:00:00', '2026-08-31 00:00:00', TRUE, '2026-09-21 19:53:30');
INSERT INTO offers ("id", "code", "description", "discount_percent", "valid_from", "valid_until", "is_active", "created_at") VALUES (3, 'ATLASNEW', 'Welcome Offer: 10% discount for new travellers', 10, '2026-01-01 00:00:00', '2026-12-31 00:00:00', TRUE, '2026-09-21 19:53:30');
SELECT setval(pg_get_serial_sequence('offers', 'id'), COALESCE(MAX(id), 1)) FROM offers;

-- Data for packages (8 rows)
INSERT INTO packages ("id", "destination_id", "name", "duration", "duration_days", "price", "hotel_info", "transport_info", "meals_info", "description", "inclusions", "exclusions", "available_dates", "image_url", "is_featured", "created_at") VALUES (1, 1, 'Mystical Nepal: Kathmandu & Pokhara Odyssey', '6 Days / 5 Nights', 6, 26999.00, '4-Star Boutique Resort & Lakeside Hotel', 'Private AC Sedan / SUV for all transfers and sightseeing', 'Daily Buffet Breakfast & 2 Traditional Dinners included', 'Explore the cultural soul of Kathmandu followed by the tranquil serenity of Pokhara with panoramic views of the Annapurna mountain range.', 'Hotel accommodation, Airport transfers, Private sightseeing cab, English speaking guide, Entry permits', 'International flights, Personal expenses, Paragliding charges, Travel insurance', 'Weekly Departures every Saturday', 'https://images.unsplash.com/photo-1544735716-392fe2489ffa?auto=format&fit=crop&w=1000&q=80', TRUE, '2026-09-21 19:53:30');
INSERT INTO packages ("id", "destination_id", "name", "duration", "duration_days", "price", "hotel_info", "transport_info", "meals_info", "description", "inclusions", "exclusions", "available_dates", "image_url", "is_featured", "created_at") VALUES (2, 1, 'Everest View & Annapurna Panorama Trek', '8 Days / 7 Nights', 8, 38999.00, 'Premium Himalayan Lodges & Heritage Hotels', 'Tourist coach & Private mountain transfers', 'Full board: Breakfast, Lunch, and Dinner on trek days', 'An exhilarating trek designed for adventure lovers offering close-up vistas of Everest, Annapurna, and Machapuchare peaks with expert Sherpa guides.', 'Trek permits, Sherpa guide, Porter service, All meals during trek, First aid support', 'Personal trekking gear, Emergency evacuation insurance, Tips for porters', '1st & 15th of every month', 'https://images.unsplash.com/photo-1486911278844-a81c5267e227?auto=format&fit=crop&w=1000&q=80', TRUE, '2026-09-21 19:53:30');
INSERT INTO packages ("id", "destination_id", "name", "duration", "duration_days", "price", "hotel_info", "transport_info", "meals_info", "description", "inclusions", "exclusions", "available_dates", "image_url", "is_featured", "created_at") VALUES (3, 2, 'Darjeeling Enchantment & Kanchenjunga Sunrise', '4 Days / 3 Nights', 4, 15999.00, 'Heritage Colonial Hotel with Mountain View', 'Private AC Cab from Bagdogra / NJP', 'Daily Breakfast and Dinner included', 'Wake up to the golden rays hitting Mount Kanchenjunga, ride the iconic Toy Train through misty mountain loops, and stroll along lush tea estates.', 'Pick and drop from Bagdogra/NJP, 3-star hotel stay, All local sightseeing, Toy train ticket assistance', 'Lunch, Any entry fee at monuments, Tips, Personal laundry', 'Every Friday & Monday', 'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?auto=format&fit=crop&w=1000&q=80', TRUE, '2026-09-21 19:53:30');
INSERT INTO packages ("id", "destination_id", "name", "duration", "duration_days", "price", "hotel_info", "transport_info", "meals_info", "description", "inclusions", "exclusions", "available_dates", "image_url", "is_featured", "created_at") VALUES (4, 2, 'Tea Garden Bliss & Mirik Lake Escape', '5 Days / 4 Nights', 5, 18999.00, 'Tea Estate Bungalow & Resort', 'Private AC Vehicle for duration', 'Buffet Breakfast & Authentic Bengali/Nepali Dinner', 'Escape into the aroma of fresh tea leaves with exclusive tea garden stays and a leisure day trip to the calm waters of Mirik Lake.', 'Tea estate bungalow stay, Factory tea tasting, Boating charges at Mirik, Dedicated chauffeur', 'Personal beverages, Horse riding at Mirik, Flight/train tickets', 'Daily departures available', 'https://images.unsplash.com/photo-1564890369478-c89ca6d9cde9?auto=format&fit=crop&w=1000&q=80', FALSE, '2026-09-21 19:53:30');
INSERT INTO packages ("id", "destination_id", "name", "duration", "duration_days", "price", "hotel_info", "transport_info", "meals_info", "description", "inclusions", "exclusions", "available_dates", "image_url", "is_featured", "created_at") VALUES (5, 3, 'Spiritual Kashi & Ancient Sarnath Immersion', '3 Days / 2 Nights', 3, 12999.00, 'Riverside Heritage Haveli Hotel', 'Private AC Car for all transfers', 'Breakfast & Special Banarasi Thali Dinner', 'Immerse your soul in the timeless rituals of Varanasi. Witness sacred morning boat rituals, evening Ganga Aarti from reserved VIP boats, and visit holy Sarnath.', 'VIP boat for Ganga Aarti, Temple darshan assistance, Sarnath museum & stupa entry, Station pickup/drop', 'Camera fees, Pooja offerings, Personal shopping', 'Every Tuesday & Friday', 'https://images.unsplash.com/photo-1627894483216-2138af692e32?q=80&w=687&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D', TRUE, '2026-09-21 19:53:30');
INSERT INTO packages ("id", "destination_id", "name", "duration", "duration_days", "price", "hotel_info", "transport_info", "meals_info", "description", "inclusions", "exclusions", "available_dates", "image_url", "is_featured", "created_at") VALUES (6, 4, 'Meghalaya Wonderland: Cherrapunji & Dawki', '5 Days / 4 Nights', 5, 21999.00, 'Eco Luxury Resort & Riverside Camps', 'Private SUV for tough hill terrain', 'All Breakfasts & Campfire Dinners', 'Discover the wettest place on earth, trek across ancient living root bridges, cruise on the crystal clear waters of Dawki, and explore mystical limestone caves.', 'SUV transportation, Guided root bridge trek, Dawki boating ride, Clean stay with campfire', 'Zip-lining fees, Lunch, Alcoholic beverages', 'Every Thursday departure', 'https://images.unsplash.com/photo-1593813738953-fb3c93e0769d?q=80&w=1254&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D', TRUE, '2026-09-21 19:53:30');
INSERT INTO packages ("id", "destination_id", "name", "duration", "duration_days", "price", "hotel_info", "transport_info", "meals_info", "description", "inclusions", "exclusions", "available_dates", "image_url", "is_featured", "created_at") VALUES (7, 5, 'Andaman Island Dream: Port Blair & Havelock', '5 Days / 4 Nights', 5, 29999.00, 'Beachfront 4-Star Resort at Havelock', 'Makruzz / Green Ocean Luxury Cruise + AC Cab', 'Daily Breakfast & 2 Candlelight Dinners', 'Experience pure island magic at Asia’s best beach (Radhanagar Beach), delve into history at Cellular Jail, and snorkel among dazzling coral reefs.', 'Inter-island ferry tickets (Makruzz AC), Hotel stay with breakfast, Cellular jail light & sound entry, Snorkeling session', 'Water sports outside itinerary, Scuba certification, Airfare', 'Departures every Wednesday & Saturday', 'https://images.unsplash.com/photo-1640618792277-b91f3199f6a8?q=80&w=1074&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D', TRUE, '2026-09-21 19:53:30');
INSERT INTO packages ("id", "destination_id", "name", "duration", "duration_days", "price", "hotel_info", "transport_info", "meals_info", "description", "inclusions", "exclusions", "available_dates", "image_url", "is_featured", "created_at") VALUES (8, 5, 'Exotic Andaman Explorer: Havelock & Neil Island', '6 Days / 5 Nights', 6, 36999.00, 'Premium Beach Villas at Neil & Havelock', 'Private Speedboat transfers & AC cabs', 'Complimentary Breakfast & Seafood Dinners', 'The ultimate tropical honeymoon and leisure escape covering Port Blair, Havelock Island, and the natural rock formations of serene Neil Island.', 'Beach villa stays, Private cruise transfers, Scuba intro dive with instructor, Dedicated tour guide', 'Personal purchases, Lunch, Flight charges', 'Flexible private dates', 'https://images.unsplash.com/photo-1640618792277-b91f3199f6a8?q=80&w=1074&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D', FALSE, '2026-09-21 19:53:30');
SELECT setval(pg_get_serial_sequence('packages', 'id'), COALESCE(MAX(id), 1)) FROM packages;

-- Data for package_itinerary (23 rows)
INSERT INTO package_itinerary ("id", "package_id", "day_number", "title", "description", "activities") VALUES (1, 1, 1, 'Arrival in Kathmandu & Thamel Exploration', 'Arrive at Tribhuvan International Airport where our representative welcomes you with a traditional garland. Check into your hotel and stroll through Thamel night market.', 'Airport reception, Hotel check-in, Evening stroll in vibrant Thamel');
INSERT INTO package_itinerary ("id", "package_id", "day_number", "title", "description", "activities") VALUES (2, 1, 2, 'Kathmandu Cultural Heritage Tour', 'Visit the sacred Pashupatinath Hindu temple, the giant Boudhanath Stupa, and the historic Swayambhunath Monkey Temple overlooking Kathmandu valley.', 'Guided spiritual walking tour, Photography at Boudhanath Stupa');
INSERT INTO package_itinerary ("id", "package_id", "day_number", "title", "description", "activities") VALUES (3, 1, 3, 'Scenic Drive to Pokhara Lakeside', 'Take a picturesque drive along the Trishuli River passing terraced hills. Arrive in Pokhara, the adventure capital, and relax by Phewa Lake.', 'Drive through river valleys, Sunset boating on Phewa Lake');
INSERT INTO package_itinerary ("id", "package_id", "day_number", "title", "description", "activities") VALUES (4, 1, 4, 'Sarangkot Sunrise & Pokhara Sightseeing', 'Early morning drive to Sarangkot hill for sunrise over Annapurna & Dhaulagiri. Later visit Davis Falls, Gupteshwor Mahadev Cave, and Peace Pagoda.', 'Sunrise photo shoot, Exploring limestone caves, World Peace Pagoda visit');
INSERT INTO package_itinerary ("id", "package_id", "day_number", "title", "description", "activities") VALUES (5, 1, 5, 'Return to Kathmandu & Bhaktapur Visit', 'Fly or drive back to Kathmandu. Spend the afternoon exploring Bhaktapur Durbar Square with its magnificent 55-window palace and pottery square.', 'Bhaktapur architectural exploration, Souvenir shopping');
INSERT INTO package_itinerary ("id", "package_id", "day_number", "title", "description", "activities") VALUES (6, 1, 6, 'Departure with Himalayan Memories', 'Enjoy your breakfast at leisure. Our driver will escort you to the airport for your onward flight home.', 'Hotel checkout, Airport transfer');
INSERT INTO package_itinerary ("id", "package_id", "day_number", "title", "description", "activities") VALUES (7, 3, 1, 'Bagdogra to Darjeeling Hill Drive', 'Pickup from Bagdogra Airport / NJP Station. Enjoy a winding scenic drive through misty valleys and cedar forests. Check-in and relax.', 'Scenic hill drive, Mall Road walking, Glenary’s bakery visit');
INSERT INTO package_itinerary ("id", "package_id", "day_number", "title", "description", "activities") VALUES (8, 3, 2, 'Tiger Hill Sunrise & Monastery Tour', 'Wake at 4:00 AM for the world-famous sunrise over Mt. Kanchenjunga from Tiger Hill. Visit Ghoom Monastery and Batasia Loop war memorial.', 'Tiger Hill sunrise spectacle, Batasia Loop garden stroll, Monastery blessing');
INSERT INTO package_itinerary ("id", "package_id", "day_number", "title", "description", "activities") VALUES (9, 3, 3, 'Himalayan Mountaineering Institute & Tea Tasting', 'Tour the Himalayan Mountaineering Institute, Padmaja Naidu Zoo (Red Pandas), and spend the afternoon at Happy Valley Tea Estate.', 'HMI museum visit, Red panda sighting, Premium Darjeeling tea tasting');
INSERT INTO package_itinerary ("id", "package_id", "day_number", "title", "description", "activities") VALUES (10, 3, 4, 'Toy Train Ride & Departure', 'Morning ride on the UNESCO World Heritage Toy Train before heading back to Bagdogra Airport / NJP with warm hill memories.', 'Heritage toy train ride, Drop-off transfer');
INSERT INTO package_itinerary ("id", "package_id", "day_number", "title", "description", "activities") VALUES (11, 5, 1, 'Arrival & Ganga Aarti at Dashashwamedh', 'Arrival pickup and transfer to the heritage haveli. In the evening, witness the grand Ganga Aarti from a reserved boat with floating lamps.', 'Check-in, Evening boat cruise, Witnessing grand musical Ganga Aarti');
INSERT INTO package_itinerary ("id", "package_id", "day_number", "title", "description", "activities") VALUES (12, 5, 2, 'Sunrise Boat Cruise, Kashi Vishwanath & Sarnath', 'Early morning subah-e-banaras boat ride along the ghats. Darshan at Kashi Vishwanath corridor. Afternoon tour of Sarnath Buddhist monument.', 'Sunrise rowing boat, Temple darshan, Sarnath Dhamek Stupa tour');
INSERT INTO package_itinerary ("id", "package_id", "day_number", "title", "description", "activities") VALUES (13, 5, 3, 'Heritage Street Food Walk & Departure', 'Savor authentic Banarasi kachori-jalebi and creamy lassi. Visit famous silk weavers before departing for the airport or railway station.', 'Food tasting walk, Silk weaving demonstration, Departure transfer');
INSERT INTO package_itinerary ("id", "package_id", "day_number", "title", "description", "activities") VALUES (14, 6, 1, 'Guwahati to Shillong via Umiam Lake', 'Arrive at Guwahati and drive to Shillong. Stop at scenic Umiam Lake (Barapani) for watersports and photography.', 'Airport pickup, Water sports at Umiam Lake, Check-in at Shillong');
INSERT INTO package_itinerary ("id", "package_id", "day_number", "title", "description", "activities") VALUES (15, 6, 2, 'Cherrapunji Waterfalls & Caves', 'Drive to Cherrapunji. Visit roaring Nohkalikai Falls, Wei Sawdong three-tiered falls, and walk inside ancient Mawsmai limestone caves.', 'Waterfall viewpoints, Limestone cave exploration, Cafe hopping');
INSERT INTO package_itinerary ("id", "package_id", "day_number", "title", "description", "activities") VALUES (16, 6, 3, 'Double Decker Living Root Bridge Trek', 'Trek into the lush rainforest of Tyrna down to the world-famous Nongriat Double Decker Living Root Bridge and turquoise natural pools.', 'Rainforest trekking, Swimming in crystal natural pools, Bio-engineering marvels');
INSERT INTO package_itinerary ("id", "package_id", "day_number", "title", "description", "activities") VALUES (17, 6, 4, 'Dawki Umngot River & Mawlynnong Cleanest Village', 'Visit Mawlynnong, cleanest village in Asia. Boating on the surreal transparent waters of Umngot River along the Indo-Bangladesh border.', 'Boating on glassy river, Walking around Mawlynnong flower paths, Campfire night');
INSERT INTO package_itinerary ("id", "package_id", "day_number", "title", "description", "activities") VALUES (18, 6, 5, 'Elephant Falls & Departure to Guwahati', 'Visit picturesque Elephant Falls and Shillong Peak before returning to Guwahati airport for your onward journey.', 'Elephant falls photo stop, Airport drop-off');
INSERT INTO package_itinerary ("id", "package_id", "day_number", "title", "description", "activities") VALUES (19, 7, 1, 'Arrival at Port Blair & Cellular Jail', 'Meet and greet at Veer Savarkar Airport. Check-in to hotel. In the afternoon, visit historical Cellular Jail and attend the patriotic Light & Sound show.', 'Airport transfer, Cellular jail tour, Sound and light show');
INSERT INTO package_itinerary ("id", "package_id", "day_number", "title", "description", "activities") VALUES (20, 7, 2, 'Luxury Cruise to Havelock & Radhanagar Sunset', 'Board premium AC catamaran cruise to Havelock Island (Swaraj Dweep). Spend a magical evening watching the sunset at Radhanagar Beach (Beach No. 7).', 'High-speed catamaran cruise, Beach relaxation, Spectacular sunset views');
INSERT INTO package_itinerary ("id", "package_id", "day_number", "title", "description", "activities") VALUES (21, 7, 3, 'Elephant Beach Snorkeling & Coral Reef Adventure', 'Speedboat ride to Elephant Beach. Indulge in complimentary snorkeling amidst colorful coral reefs and exotic tropical fish.', 'Speedboat adventure, Guided snorkeling, Optional jet-skiing and banana boat');
INSERT INTO package_itinerary ("id", "package_id", "day_number", "title", "description", "activities") VALUES (22, 7, 4, 'Kalapathar Beach & Return to Port Blair', 'Morning visit to picturesque Kalapathar Beach with turquoise waters and black rocks. Afternoon cruise back to Port Blair.', 'Beach photography, Return cruise to Port Blair, Local handicraft shopping');
INSERT INTO package_itinerary ("id", "package_id", "day_number", "title", "description", "activities") VALUES (23, 7, 5, 'Departure from Port Blair', 'Enjoy breakfast overlooking the ocean. Transfer to airport with unforgettable tropical island memories.', 'Check-out, Airport drop');
SELECT setval(pg_get_serial_sequence('package_itinerary', 'id'), COALESCE(MAX(id), 1)) FROM package_itinerary;

-- Data for bookings (26 rows)
INSERT INTO bookings ("id", "booking_number", "user_id", "package_id", "travel_date", "adults_count", "children_count", "base_amount", "discount_amount", "total_amount", "offer_id", "contact_name", "contact_email", "contact_phone", "special_requests", "booking_status", "created_at") VALUES (1, 'ATL-2026-1001', 2, 1, '2026-10-15 00:00:00', 2, 0, 53998.00, 8099.70, 45898.30, 1, 'John Traveller', 'john@example.com', '+91 9811223344', 'Vegetarian meals preferred and high floor hotel room please.', 'Confirmed', '2026-09-01 10:30:00');
INSERT INTO bookings ("id", "booking_number", "user_id", "package_id", "travel_date", "adults_count", "children_count", "base_amount", "discount_amount", "total_amount", "offer_id", "contact_name", "contact_email", "contact_phone", "special_requests", "booking_status", "created_at") VALUES (2, 'ATL-2026-1002', 2, 3, '2026-08-10 00:00:00', 1, 0, 15999.00, 0.00, 15999.00, NULL, 'John Traveller', 'john@example.com', '+91 9811223344', 'Window seat for the scenic drive.', 'Completed', '2026-08-01 14:20:00');
INSERT INTO bookings ("id", "booking_number", "user_id", "package_id", "travel_date", "adults_count", "children_count", "base_amount", "discount_amount", "total_amount", "offer_id", "contact_name", "contact_email", "contact_phone", "special_requests", "booking_status", "created_at") VALUES (3, 'ATL-2026-1003', 3, 7, '2026-11-20 00:00:00', 2, 1, 71997.00, 10799.55, 61197.45, 1, 'Priya Sharma', 'priya@example.com', '+91 9877665544', 'Celebrating wedding anniversary. Need candlelight dinner setup.', 'Confirmed', '2026-09-10 16:45:00');
INSERT INTO bookings ("id", "booking_number", "user_id", "package_id", "travel_date", "adults_count", "children_count", "base_amount", "discount_amount", "total_amount", "offer_id", "contact_name", "contact_email", "contact_phone", "special_requests", "booking_status", "created_at") VALUES (4, 'ATL-2026-1004', 3, 5, '2026-09-28 00:00:00', 1, 0, 12999.00, 1299.90, 11699.10, 3, 'Priya Sharma', 'priya@example.com', '+91 9877665544', 'Pickup from Varanasi Junction Railway Station.', 'Pending', '2026-09-20 11:15:00');
INSERT INTO bookings ("id", "booking_number", "user_id", "package_id", "travel_date", "adults_count", "children_count", "base_amount", "discount_amount", "total_amount", "offer_id", "contact_name", "contact_email", "contact_phone", "special_requests", "booking_status", "created_at") VALUES (5, 'ATL-2026-2951', 2, 1, '2026-11-20 00:00:00', 2, 1, 70197.40, 10529.61, 59667.79, 1, 'John Traveller', 'john@example.com', '+91 9811223344', 'Airport pickup required and vegetarian meals please.', 'Confirmed', '2026-09-21 20:02:18');
INSERT INTO bookings ("id", "booking_number", "user_id", "package_id", "travel_date", "adults_count", "children_count", "base_amount", "discount_amount", "total_amount", "offer_id", "contact_name", "contact_email", "contact_phone", "special_requests", "booking_status", "created_at") VALUES (6, 'ATL-2026-2240', 4, 1, '2026-12-25 00:00:00', 1, 0, 26999.00, 0.00, 26999.00, NULL, 'Test User', 'test@test.com', '+919999999999', '', 'Cancelled', '2026-09-21 23:30:13');
INSERT INTO bookings ("id", "booking_number", "user_id", "package_id", "travel_date", "adults_count", "children_count", "base_amount", "discount_amount", "total_amount", "offer_id", "contact_name", "contact_email", "contact_phone", "special_requests", "booking_status", "created_at") VALUES (7, 'ATL-2026-2916', 4, 1, '2026-09-23 00:00:00', 1, 0, 26999.00, 0.00, 26999.00, NULL, 'RAJDEEP PAUL', 'rajdeeppaul945@gmail.com', '+916901850476', '', 'Cancelled', '2026-09-21 23:31:30');
INSERT INTO bookings ("id", "booking_number", "user_id", "package_id", "travel_date", "adults_count", "children_count", "base_amount", "discount_amount", "total_amount", "offer_id", "contact_name", "contact_email", "contact_phone", "special_requests", "booking_status", "created_at") VALUES (8, 'ATL-2026-8986', 5, 7, '2026-10-01 00:00:00', 2, 0, 59998.00, 8999.70, 50998.30, 1, 'Neymar', 'neymarjr112@gmail.com', '9822364790', '', 'Cancelled', '2026-09-22 01:23:32');
INSERT INTO bookings ("id", "booking_number", "user_id", "package_id", "travel_date", "adults_count", "children_count", "base_amount", "discount_amount", "total_amount", "offer_id", "contact_name", "contact_email", "contact_phone", "special_requests", "booking_status", "created_at") VALUES (9, 'ATL-2026-3441', 4, 5, '2026-09-24 00:00:00', 2, 0, 25998.00, 3899.70, 22098.30, 1, 'RAJDEEP PAUL', 'rajdeeppaul945@gmail.com', '+916901850476', '', 'Confirmed', '2026-09-22 01:54:51');
INSERT INTO bookings ("id", "booking_number", "user_id", "package_id", "travel_date", "adults_count", "children_count", "base_amount", "discount_amount", "total_amount", "offer_id", "contact_name", "contact_email", "contact_phone", "special_requests", "booking_status", "created_at") VALUES (10, 'ATL-2026-4380', 4, 1, '2026-09-24 00:00:00', 1, 0, 26999.00, 4049.85, 22949.15, 1, 'RAJDEEP PAUL', 'rajdeeppaul945@gmail.com', '+916901850476', '', 'Confirmed', '2026-09-22 02:15:05');
INSERT INTO bookings ("id", "booking_number", "user_id", "package_id", "travel_date", "adults_count", "children_count", "base_amount", "discount_amount", "total_amount", "offer_id", "contact_name", "contact_email", "contact_phone", "special_requests", "booking_status", "created_at") VALUES (11, 'ATL-2026-2790', 6, 1, '2026-09-30 00:00:00', 2, 0, 53998.00, 8099.70, 45898.30, 1, 'Sam', 'sam@gmail.com', '1234567890', '', 'Cancelled', '2026-09-22 09:47:55');
INSERT INTO bookings ("id", "booking_number", "user_id", "package_id", "travel_date", "adults_count", "children_count", "base_amount", "discount_amount", "total_amount", "offer_id", "contact_name", "contact_email", "contact_phone", "special_requests", "booking_status", "created_at") VALUES (12, 'ATL-2026-1587', 7, 5, '2026-09-24 00:00:00', 1, 0, 12999.00, 1949.85, 11049.15, 1, 'navi manus', 'manus@gphaad.com', '0000000001', 'full non veg', 'Cancelled', '2026-09-22 11:07:37');
INSERT INTO bookings ("id", "booking_number", "user_id", "package_id", "travel_date", "adults_count", "children_count", "base_amount", "discount_amount", "total_amount", "offer_id", "contact_name", "contact_email", "contact_phone", "special_requests", "booking_status", "created_at") VALUES (13, 'ATL-2026-2798', 7, 2, '2026-10-21 00:00:00', 5, 0, 194995.00, 29249.25, 165745.75, 1, 'navi manus', 'manus@gphaad.com', '0000000001', '', 'Confirmed', '2026-09-30 13:17:34');
INSERT INTO bookings ("id", "booking_number", "user_id", "package_id", "travel_date", "adults_count", "children_count", "base_amount", "discount_amount", "total_amount", "offer_id", "contact_name", "contact_email", "contact_phone", "special_requests", "booking_status", "created_at") VALUES (14, 'ATL-2026-7958', 7, 1, '2026-10-01 00:00:00', 1, 0, 26999.00, 4049.85, 22949.15, 1, 'navi manus', 'manus@gphaad.com', '0000000001', '', 'Confirmed', '2026-09-30 14:51:47');
INSERT INTO bookings ("id", "booking_number", "user_id", "package_id", "travel_date", "adults_count", "children_count", "base_amount", "discount_amount", "total_amount", "offer_id", "contact_name", "contact_email", "contact_phone", "special_requests", "booking_status", "created_at") VALUES (15, 'ATL-2026-4533', 7, 1, '2026-10-14 00:00:00', 2, 0, 53998.00, 8099.70, 45898.30, 1, 'navi manus', 'manus@gphaad.com', '0000000001', '', 'Confirmed', '2026-10-13 10:52:41');
INSERT INTO bookings ("id", "booking_number", "user_id", "package_id", "travel_date", "adults_count", "children_count", "base_amount", "discount_amount", "total_amount", "offer_id", "contact_name", "contact_email", "contact_phone", "special_requests", "booking_status", "created_at") VALUES (16, 'ATL-2026-2188', 9, 3, '2026-10-19 00:00:00', 1, 0, 15999.00, 2399.85, 13599.15, 1, 'Abhishek', 'abhishek223@gmail.com', '8957641255', 'Non-VEG', 'Confirmed', '2026-10-18 22:42:28');
INSERT INTO bookings ("id", "booking_number", "user_id", "package_id", "travel_date", "adults_count", "children_count", "base_amount", "discount_amount", "total_amount", "offer_id", "contact_name", "contact_email", "contact_phone", "special_requests", "booking_status", "created_at") VALUES (17, 'ATL-2026-6343', 10, 7, '2026-10-30 00:00:00', 2, 1, 77997.40, 11699.61, 66297.79, 1, 'test_case', 'qwerty@as.zxc', '32540652', '', 'Cancelled', '2026-10-28 03:58:55');
INSERT INTO bookings ("id", "booking_number", "user_id", "package_id", "travel_date", "adults_count", "children_count", "base_amount", "discount_amount", "total_amount", "offer_id", "contact_name", "contact_email", "contact_phone", "special_requests", "booking_status", "created_at") VALUES (18, 'ATL-2026-7863', 7, 1, '2026-10-29 00:00:00', 2, 0, 53998.00, 8099.70, 45898.30, 1, 'navi manus', 'manus@gmail.com', '+91 89567 42534', '', 'Pending', '2026-10-28 10:18:11');
INSERT INTO bookings ("id", "booking_number", "user_id", "package_id", "travel_date", "adults_count", "children_count", "base_amount", "discount_amount", "total_amount", "offer_id", "contact_name", "contact_email", "contact_phone", "special_requests", "booking_status", "created_at") VALUES (19, 'ATL-2026-6040', 12, 3, '2026-10-29 00:00:00', 1, 0, 15999.00, 1599.90, 14399.10, 3, 'Rohit', 'rohit@yahoo.com', '+91 99005 29390', '', 'Confirmed', '2026-10-28 10:30:47');
INSERT INTO bookings ("id", "booking_number", "user_id", "package_id", "travel_date", "adults_count", "children_count", "base_amount", "discount_amount", "total_amount", "offer_id", "contact_name", "contact_email", "contact_phone", "special_requests", "booking_status", "created_at") VALUES (20, 'ATL-2026-2888', 12, 1, '2026-10-29 00:00:00', 1, 0, 26999.00, 4049.85, 22949.15, 1, 'Rohit', 'rohit@yahoo.com', '+91 99005 29390', '', 'Confirmed', '2026-10-28 10:43:14');
INSERT INTO bookings ("id", "booking_number", "user_id", "package_id", "travel_date", "adults_count", "children_count", "base_amount", "discount_amount", "total_amount", "offer_id", "contact_name", "contact_email", "contact_phone", "special_requests", "booking_status", "created_at") VALUES (21, 'ATL-2026-3680', 12, 2, '2026-10-29 00:00:00', 1, 0, 38999.00, 0.00, 38999.00, NULL, 'Rohit', 'rohit@yahoo.com', '+91 99005 29390', '', 'Confirmed', '2026-10-28 10:47:52');
INSERT INTO bookings ("id", "booking_number", "user_id", "package_id", "travel_date", "adults_count", "children_count", "base_amount", "discount_amount", "total_amount", "offer_id", "contact_name", "contact_email", "contact_phone", "special_requests", "booking_status", "created_at") VALUES (22, 'ATL-2026-2646', 12, 2, '2026-10-29 00:00:00', 1, 0, 38999.00, 5849.85, 33149.15, 1, 'Rohit', 'rohit@yahoo.com', '+91 99005 29390', '', 'Cancelled', '2026-10-28 11:43:23');
INSERT INTO bookings ("id", "booking_number", "user_id", "package_id", "travel_date", "adults_count", "children_count", "base_amount", "discount_amount", "total_amount", "offer_id", "contact_name", "contact_email", "contact_phone", "special_requests", "booking_status", "created_at") VALUES (23, 'ATL-2026-6325', 12, 1, '2026-10-29 00:00:00', 1, 0, 26999.00, 4049.85, 22949.15, 1, 'Rohit', 'rohit@yahoo.com', '+91 99005 29390', '', 'Cancelled', '2026-10-28 11:47:01');
INSERT INTO bookings ("id", "booking_number", "user_id", "package_id", "travel_date", "adults_count", "children_count", "base_amount", "discount_amount", "total_amount", "offer_id", "contact_name", "contact_email", "contact_phone", "special_requests", "booking_status", "created_at") VALUES (24, 'ATL-2026-5262', 14, 1, '2026-10-29 00:00:00', 1, 0, 26999.00, 2699.90, 24299.10, 3, 'RAJDEEP PAUL', 'rajdeeppaul850@gmail.com', '+91 69018 50476', '', 'Cancelled', '2026-10-28 13:05:46');
INSERT INTO bookings ("id", "booking_number", "user_id", "package_id", "travel_date", "adults_count", "children_count", "base_amount", "discount_amount", "total_amount", "offer_id", "contact_name", "contact_email", "contact_phone", "special_requests", "booking_status", "created_at") VALUES (25, 'ATL-2026-3339', 17, 1, '2027-02-18 00:00:00', 2, 0, 53998.00, 0.00, 53998.00, NULL, 'Abhishek', 'abhishek2024@gmail.com', '+91 98658 54725', '', 'Confirmed', '2026-10-31 16:33:00');
INSERT INTO bookings ("id", "booking_number", "user_id", "package_id", "travel_date", "adults_count", "children_count", "base_amount", "discount_amount", "total_amount", "offer_id", "contact_name", "contact_email", "contact_phone", "special_requests", "booking_status", "created_at") VALUES (26, 'ATL-2026-1151', 17, 3, '2026-11-27 00:00:00', 1, 0, 15999.00, 1599.90, 14399.10, 3, 'Abhishek', 'abhishek2024@gmail.com', '+91 98658 54725', 'Non-Veg', 'Confirmed', '2026-10-31 16:35:03');
SELECT setval(pg_get_serial_sequence('bookings', 'id'), COALESCE(MAX(id), 1)) FROM bookings;

-- Data for booking_travellers (42 rows)
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (1, 1, 'John Traveller', 29, 'Male');
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (2, 1, 'Sarah Traveller', 27, 'Female');
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (3, 2, 'John Traveller', 29, 'Male');
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (4, 3, 'Priya Sharma', 31, 'Female');
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (5, 3, 'Rohit Sharma', 34, 'Male');
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (6, 3, 'Aarav Sharma', 6, 'Male');
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (7, 4, 'Priya Sharma', 31, 'Female');
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (8, 5, 'John Traveller', 29, 'Male');
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (9, 5, 'Sarah Traveller', 27, 'Female');
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (10, 5, 'Leo Traveller', 5, 'Male');
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (11, 7, 'Rajdeep Paul', 23, 'Male');
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (12, 8, 'Neymar', 30, 'Male');
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (13, 8, 'Kylie Jenner', 28, 'Female');
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (14, 9, 'Raj', 23, 'Male');
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (15, 9, 'Adi', 22, 'Male');
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (16, 10, 'sfs', 28, 'Male');
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (17, 11, 'Sam', 24, 'Female');
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (18, 11, 'NEHA', 26, 'Female');
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (19, 12, 'navi manus', 22, 'Male');
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (20, 13, 'Raj', 23, 'Male');
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (21, 13, 'Akshh', 22, 'Female');
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (22, 13, 'Arka', 25, 'Male');
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (23, 13, 'Blush', 22, 'Male');
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (24, 13, 'Abhi', 23, 'Male');
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (25, 14, 'aada', 28, 'Male');
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (26, 15, 'abc', 28, 'Male');
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (27, 15, 'zxc', 25, 'Female');
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (28, 16, 'Abhishek', 25, 'Male');
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (29, 17, 'asdf', 28, 'Male');
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (30, 17, 'sdfg', 28, 'Male');
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (31, 17, 'dfgh', 8, 'Male');
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (32, 18, 'rere', 28, 'Male');
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (33, 18, 'rereree', 28, 'Male');
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (34, 19, 'ROHIT', 28, 'Male');
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (35, 20, 'GG', 28, 'Male');
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (36, 21, 'pp', 28, 'Male');
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (37, 22, 'ok', 28, 'Male');
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (38, 23, 'RAJ', 28, 'Male');
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (39, 24, 'RAJ', 28, 'Male');
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (40, 25, 'Abhishek', 25, 'Male');
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (41, 25, 'Mukesh', 24, 'Male');
INSERT INTO booking_travellers ("id", "booking_id", "full_name", "age", "gender") VALUES (42, 26, 'Abhishek', 28, 'Male');
SELECT setval(pg_get_serial_sequence('booking_travellers', 'id'), COALESCE(MAX(id), 1)) FROM booking_travellers;

-- Data for payments (23 rows)
INSERT INTO payments ("id", "booking_id", "user_id", "razorpay_order_id", "razorpay_payment_id", "razorpay_signature", "amount", "currency", "payment_method", "payment_status", "created_at") VALUES (1, 1, 2, 'order_mock_001_nepal', 'pay_rzp_mock_987123', 'sig_valid_mock_signature_1', 45898.30, 'INR', 'Razorpay UPI', 'Success', '2026-09-01 10:35:00');
INSERT INTO payments ("id", "booking_id", "user_id", "razorpay_order_id", "razorpay_payment_id", "razorpay_signature", "amount", "currency", "payment_method", "payment_status", "created_at") VALUES (2, 2, 2, 'order_mock_002_darj', 'pay_rzp_mock_456789', 'sig_valid_mock_signature_2', 15999.00, 'INR', 'Razorpay NetBanking', 'Success', '2026-08-01 14:25:00');
INSERT INTO payments ("id", "booking_id", "user_id", "razorpay_order_id", "razorpay_payment_id", "razorpay_signature", "amount", "currency", "payment_method", "payment_status", "created_at") VALUES (3, 3, 3, 'order_mock_003_andaman', 'pay_rzp_mock_112233', 'sig_valid_mock_signature_3', 61197.45, 'INR', 'Razorpay Card', 'Success', '2026-09-10 16:50:00');
INSERT INTO payments ("id", "booking_id", "user_id", "razorpay_order_id", "razorpay_payment_id", "razorpay_signature", "amount", "currency", "payment_method", "payment_status", "created_at") VALUES (4, 5, 2, 'order_demo_1790001138', 'pay_demo_1790001138_1622', 'sig_verified_demo_sandbox', 59667.79, 'INR', 'Razorpay Test UPI', 'Success', '2026-09-21 20:02:18');
INSERT INTO payments ("id", "booking_id", "user_id", "razorpay_order_id", "razorpay_payment_id", "razorpay_signature", "amount", "currency", "payment_method", "payment_status", "created_at") VALUES (5, 7, 4, 'order_demo_1790013694', 'pay_demo_1790013694_5375', 'sig_verified_demo_sandbox', 26999.00, 'INR', 'Razorpay Test UPI (GooglePay/PhonePe)', 'Success', '2026-09-21 23:31:34');
INSERT INTO payments ("id", "booking_id", "user_id", "razorpay_order_id", "razorpay_payment_id", "razorpay_signature", "amount", "currency", "payment_method", "payment_status", "created_at") VALUES (6, 8, 5, 'order_demo_1790020418', 'pay_demo_1790020418_3554', 'sig_verified_demo_sandbox', 50998.30, 'INR', 'Razorpay Test UPI (GooglePay/PhonePe)', 'Success', '2026-09-22 01:23:38');
INSERT INTO payments ("id", "booking_id", "user_id", "razorpay_order_id", "razorpay_payment_id", "razorpay_signature", "amount", "currency", "payment_method", "payment_status", "created_at") VALUES (7, 9, 4, 'order_demo_1790022302', 'pay_demo_1790022302_6597', 'sig_verified_demo_sandbox', 22098.30, 'INR', 'Razorpay Test UPI (GooglePay/PhonePe)', 'Success', '2026-09-22 01:55:02');
INSERT INTO payments ("id", "booking_id", "user_id", "razorpay_order_id", "razorpay_payment_id", "razorpay_signature", "amount", "currency", "payment_method", "payment_status", "created_at") VALUES (8, 10, 4, 'order_demo_1790023511', 'pay_demo_1790023511_5864', 'sig_verified_demo_sandbox', 22949.15, 'INR', 'Razorpay Test UPI (GooglePay/PhonePe)', 'Success', '2026-09-22 02:15:11');
INSERT INTO payments ("id", "booking_id", "user_id", "razorpay_order_id", "razorpay_payment_id", "razorpay_signature", "amount", "currency", "payment_method", "payment_status", "created_at") VALUES (9, 11, 6, 'order_demo_1790050681', 'pay_demo_1790050681_6174', 'sig_verified_demo_sandbox', 45898.30, 'INR', 'Razorpay Test UPI (GooglePay/PhonePe)', 'Success', '2026-09-22 09:48:01');
INSERT INTO payments ("id", "booking_id", "user_id", "razorpay_order_id", "razorpay_payment_id", "razorpay_signature", "amount", "currency", "payment_method", "payment_status", "created_at") VALUES (10, 12, 7, 'order_demo_1790055460', 'pay_demo_1790055460_4445', 'sig_verified_demo_sandbox', 11049.15, 'INR', 'Razorpay Test UPI (GooglePay/PhonePe)', 'Success', '2026-09-22 11:07:40');
INSERT INTO payments ("id", "booking_id", "user_id", "razorpay_order_id", "razorpay_payment_id", "razorpay_signature", "amount", "currency", "payment_method", "payment_status", "created_at") VALUES (11, 13, 7, 'order_demo_1790754458', 'pay_demo_1790754458_9607', 'sig_verified_demo_sandbox', 165745.75, 'INR', 'Razorpay Test UPI (GooglePay/PhonePe)', 'Success', '2026-09-30 13:17:38');
INSERT INTO payments ("id", "booking_id", "user_id", "razorpay_order_id", "razorpay_payment_id", "razorpay_signature", "amount", "currency", "payment_method", "payment_status", "created_at") VALUES (12, 14, 7, 'order_demo_1790760113', 'pay_demo_1790760113_1996', 'sig_verified_demo_sandbox', 22949.15, 'INR', 'Razorpay Test UPI (GooglePay/PhonePe)', 'Success', '2026-09-30 14:51:53');
INSERT INTO payments ("id", "booking_id", "user_id", "razorpay_order_id", "razorpay_payment_id", "razorpay_signature", "amount", "currency", "payment_method", "payment_status", "created_at") VALUES (13, 15, 7, 'order_demo_1791868965', 'pay_demo_1791868965_2293', 'sig_verified_demo_sandbox', 45898.30, 'INR', 'Razorpay Test UPI (GooglePay/PhonePe)', 'Success', '2026-10-13 10:52:45');
INSERT INTO payments ("id", "booking_id", "user_id", "razorpay_order_id", "razorpay_payment_id", "razorpay_signature", "amount", "currency", "payment_method", "payment_status", "created_at") VALUES (14, 16, 9, 'order_demo_1792343626', 'pay_demo_1792343626_7014', 'sig_verified_demo_sandbox', 13599.15, 'INR', 'Razorpay Test UPI (GooglePay/PhonePe)', 'Success', '2026-10-18 22:43:46');
INSERT INTO payments ("id", "booking_id", "user_id", "razorpay_order_id", "razorpay_payment_id", "razorpay_signature", "amount", "currency", "payment_method", "payment_status", "created_at") VALUES (15, 17, 10, 'order_demo_1793140230', 'pay_demo_1793140230_9078', 'sig_verified_demo_sandbox', 66297.79, 'INR', 'Razorpay Test UPI (GooglePay/PhonePe)', 'Success', '2026-10-28 04:00:30');
INSERT INTO payments ("id", "booking_id", "user_id", "razorpay_order_id", "razorpay_payment_id", "razorpay_signature", "amount", "currency", "payment_method", "payment_status", "created_at") VALUES (16, 19, 12, 'order_demo_1793163698', 'pay_demo_1793163698_7994', 'sig_verified_demo_sandbox', 14399.10, 'INR', 'UPI (GooglePay / PhonePe / Paytm)', 'Success', '2026-10-28 10:31:38');
INSERT INTO payments ("id", "booking_id", "user_id", "razorpay_order_id", "razorpay_payment_id", "razorpay_signature", "amount", "currency", "payment_method", "payment_status", "created_at") VALUES (17, 20, 12, 'order_demo_1793164411', 'pay_demo_1793164411_4833', 'sig_verified_demo_sandbox', 22949.15, 'INR', 'Credit / Debit Card (Visa / MasterCard / RuPay)', 'Success', '2026-10-28 10:43:31');
INSERT INTO payments ("id", "booking_id", "user_id", "razorpay_order_id", "razorpay_payment_id", "razorpay_signature", "amount", "currency", "payment_method", "payment_status", "created_at") VALUES (18, 21, 12, 'order_demo_1793164687', 'pay_demo_1793164687_2063', 'sig_verified_demo_sandbox', 38999.00, 'INR', 'UPI (GooglePay / PhonePe / Paytm)', 'Success', '2026-10-28 10:48:07');
INSERT INTO payments ("id", "booking_id", "user_id", "razorpay_order_id", "razorpay_payment_id", "razorpay_signature", "amount", "currency", "payment_method", "payment_status", "created_at") VALUES (19, 22, 12, 'order_demo_1793168053', 'pay_demo_1793168053_4839', 'sig_verified_demo_sandbox', 33149.15, 'INR', 'UPI (GooglePay / PhonePe / Paytm)', 'Success', '2026-10-28 11:44:13');
INSERT INTO payments ("id", "booking_id", "user_id", "razorpay_order_id", "razorpay_payment_id", "razorpay_signature", "amount", "currency", "payment_method", "payment_status", "created_at") VALUES (20, 23, 12, 'order_demo_1793168231', 'pay_demo_1793168231_9386', 'sig_verified_demo_sandbox', 22949.15, 'INR', 'UPI (GooglePay / PhonePe / Paytm)', 'Success', '2026-10-28 11:47:11');
INSERT INTO payments ("id", "booking_id", "user_id", "razorpay_order_id", "razorpay_payment_id", "razorpay_signature", "amount", "currency", "payment_method", "payment_status", "created_at") VALUES (21, 24, 14, 'order_demo_1793172950', 'pay_demo_1793172950_1565', 'sig_verified_demo_sandbox', 24299.10, 'INR', 'UPI (GooglePay / PhonePe / Paytm)', 'Success', '2026-10-28 13:05:50');
INSERT INTO payments ("id", "booking_id", "user_id", "razorpay_order_id", "razorpay_payment_id", "razorpay_signature", "amount", "currency", "payment_method", "payment_status", "created_at") VALUES (22, 25, 17, 'order_demo_1793444592', 'pay_demo_1793444592_7465', 'sig_verified_demo_sandbox', 53998.00, 'INR', 'UPI (GooglePay / PhonePe / Paytm)', 'Success', '2026-10-31 16:33:12');
INSERT INTO payments ("id", "booking_id", "user_id", "razorpay_order_id", "razorpay_payment_id", "razorpay_signature", "amount", "currency", "payment_method", "payment_status", "created_at") VALUES (23, 26, 17, 'order_demo_1793444714', 'pay_demo_1793444714_4014', 'sig_verified_demo_sandbox', 14399.10, 'INR', 'UPI (GooglePay / PhonePe / Paytm)', 'Success', '2026-10-31 16:35:14');
SELECT setval(pg_get_serial_sequence('payments', 'id'), COALESCE(MAX(id), 1)) FROM payments;

-- Data for reviews (5 rows)
INSERT INTO reviews ("id", "user_id", "package_id", "booking_id", "rating", "review_text", "is_approved", "created_at") VALUES (1, 2, 3, 2, 5, 'The Darjeeling trip was absolutely breathtaking! Tiger Hill sunrise over Mount Kanchenjunga was a once-in-a-lifetime sight. Our driver and guide from Atlas Tourism were punctual, polite, and very knowledgeable.', TRUE, '2026-08-16 09:12:00');
INSERT INTO reviews ("id", "user_id", "package_id", "booking_id", "rating", "review_text", "is_approved", "created_at") VALUES (2, 3, 7, NULL, 5, 'Unbelievable experience in the Andaman Islands! Radhanagar Beach really lives up to the reputation of being among the finest beaches in the world. Seamless arrangements and top-class hotels.', TRUE, '2026-07-20 18:40:00');
INSERT INTO reviews ("id", "user_id", "package_id", "booking_id", "rating", "review_text", "is_approved", "created_at") VALUES (3, 2, 1, 1, 5, 'Nepal was mesmerizing. Walking through Kathmandu heritage squares and waking up next to Pokhara lake was so peaceful. Everything was managed with utmost professionalism.', TRUE, '2026-09-15 14:22:00');
INSERT INTO reviews ("id", "user_id", "package_id", "booking_id", "rating", "review_text", "is_approved", "created_at") VALUES (4, 3, 5, NULL, 4, 'The Ganga Aarti boat experience in Varanasi was divine. Highly recommend Atlas Tourism for family trips.', TRUE, '2026-09-18 12:00:00');
INSERT INTO reviews ("id", "user_id", "package_id", "booking_id", "rating", "review_text", "is_approved", "created_at") VALUES (5, 2, 1, 5, 5, '★ Remarkable Experience with Atlas Tourism!

Highlights: 🏨 Clean & Luxury Hotel • 🚗 Punctual & Friendly Driver • 🌄 Scenic Views & Photography

Every detail was perfectly coordinated. The hotel rooms were immaculate with breathtaking mountain views, and our driver was courteous and knowledgeable throughout!', TRUE, '2026-10-28 11:58:17');
SELECT setval(pg_get_serial_sequence('reviews', 'id'), COALESCE(MAX(id), 1)) FROM reviews;

-- Data for tour_packages (6 rows)
INSERT INTO tour_packages ("id", "title", "description", "location", "price", "duration_days", "image_url", "created_at") VALUES (1, 'Andaman Island Escape', 'Explore the pristine beaches and water activities in Andaman.', 'Andaman & Nicobar', 24999.00, 5, 'images/andaman-day1.jpg', '2026-09-21 12:14:03');
INSERT INTO tour_packages ("id", "title", "description", "location", "price", "duration_days", "image_url", "created_at") VALUES (2, 'Goa Beach & Heritage', 'Relax on golden sands and enjoy Goa heritage & nightlife.', 'Goa', 14999.00, 4, 'images/goa.jpg', '2026-09-21 12:14:03');
INSERT INTO tour_packages ("id", "title", "description", "location", "price", "duration_days", "image_url", "created_at") VALUES (3, 'Himalayan Trekking Tour', 'Experience scenic mountain views and trekking adventures.', 'Manali', 18999.00, 6, 'images/manali.jpg', '2026-09-21 12:14:03');
INSERT INTO tour_packages ("id", "title", "description", "location", "price", "duration_days", "image_url", "created_at") VALUES (4, 'Andaman Island Escape', 'Explore the pristine beaches and water activities in Andaman.', 'Andaman & Nicobar', 24999.00, 5, 'images/andaman-day1.jpg', '2026-09-21 13:25:28');
INSERT INTO tour_packages ("id", "title", "description", "location", "price", "duration_days", "image_url", "created_at") VALUES (5, 'Goa Beach & Heritage', 'Relax on golden sands and enjoy Goa heritage & nightlife.', 'Goa', 14999.00, 4, 'images/goa.jpg', '2026-09-21 13:25:28');
INSERT INTO tour_packages ("id", "title", "description", "location", "price", "duration_days", "image_url", "created_at") VALUES (6, 'Himalayan Trekking Tour', 'Experience scenic mountain views and trekking adventures.', 'Manali', 18999.00, 6, 'images/manali.jpg', '2026-09-21 13:25:28');
SELECT setval(pg_get_serial_sequence('tour_packages', 'id'), COALESCE(MAX(id), 1)) FROM tour_packages;

-- Data for contact_messages (6 rows)
INSERT INTO contact_messages ("id", "name", "email", "phone", "subject", "message", "is_read", "created_at") VALUES (1, 'Rahul Verma', 'rahul.v@gmail.com', '+91 9845123456', 'Custom Honeymoon Package to Andaman', 'Hi, we are planning our honeymoon in December for 7 days. Can you customize the Andaman package with water villa and private cruise?', TRUE, '2026-09-18 15:30:00');
INSERT INTO contact_messages ("id", "name", "email", "phone", "subject", "message", "is_read", "created_at") VALUES (2, 'Sunita Roy', 'sunita.roy@yahoo.com', '+91 9733445566', 'Group booking for Darjeeling & Sikkim', 'We are a college group of 14 students looking for an affordable 5-day tour to Darjeeling. Do you offer student discounts?', TRUE, '2026-09-21 09:15:00');
INSERT INTO contact_messages ("id", "name", "email", "phone", "subject", "message", "is_read", "created_at") VALUES (3, 'RAJDEEP PAUL', 'rajdeeppaul945@gmail.com', '06901850476', 'Darjeeling Trip', 'PRice for 10 people', TRUE, '2026-09-22 01:42:32');
INSERT INTO contact_messages ("id", "name", "email", "phone", "subject", "message", "is_read", "created_at") VALUES (4, 'RAJDEEP PAUL', 'rajdeeppaul945@gmail.com', '06901850476', 'Darjeeling TRIp', 'hello', TRUE, '2026-09-22 01:45:23');
INSERT INTO contact_messages ("id", "name", "email", "phone", "subject", "message", "is_read", "created_at") VALUES (5, 'RAJDEEP PAUL', 'rajdeeppaul945@gmail.com', '06901850476', 'ada', 'adada', TRUE, '2026-09-22 01:48:58');
INSERT INTO contact_messages ("id", "name", "email", "phone", "subject", "message", "is_read", "created_at") VALUES (6, 'TT', 'GG@GMAIL.COM', '+5166848181', 'FWFSF', 'FAWEAF', TRUE, '2026-09-22 09:50:52');
SELECT setval(pg_get_serial_sequence('contact_messages', 'id'), COALESCE(MAX(id), 1)) FROM contact_messages;

-- Data for wishlist (16 rows)
INSERT INTO wishlist ("id", "user_id", "package_id", "created_at") VALUES (1, 2, 6, '2026-09-21 19:53:30');
INSERT INTO wishlist ("id", "user_id", "package_id", "created_at") VALUES (2, 2, 7, '2026-09-21 19:53:30');
INSERT INTO wishlist ("id", "user_id", "package_id", "created_at") VALUES (3, 3, 1, '2026-09-21 19:53:30');
INSERT INTO wishlist ("id", "user_id", "package_id", "created_at") VALUES (4, 2, 2, '2026-09-21 20:01:57');
INSERT INTO wishlist ("id", "user_id", "package_id", "created_at") VALUES (9, 6, 1, '2026-09-22 09:54:49');
INSERT INTO wishlist ("id", "user_id", "package_id", "created_at") VALUES (10, 6, 2, '2026-09-22 09:54:53');
INSERT INTO wishlist ("id", "user_id", "package_id", "created_at") VALUES (11, 6, 5, '2026-09-22 09:54:55');
INSERT INTO wishlist ("id", "user_id", "package_id", "created_at") VALUES (12, 6, 3, '2026-09-22 09:54:58');
INSERT INTO wishlist ("id", "user_id", "package_id", "created_at") VALUES (14, 10, 7, '2026-10-28 03:51:29');
INSERT INTO wishlist ("id", "user_id", "package_id", "created_at") VALUES (16, 7, 1, '2026-10-28 10:21:52');
INSERT INTO wishlist ("id", "user_id", "package_id", "created_at") VALUES (17, 7, 2, '2026-10-28 10:21:54');
INSERT INTO wishlist ("id", "user_id", "package_id", "created_at") VALUES (19, 12, 2, '2026-10-28 10:38:54');
INSERT INTO wishlist ("id", "user_id", "package_id", "created_at") VALUES (20, 2, 1, '2026-10-28 12:46:51');
INSERT INTO wishlist ("id", "user_id", "package_id", "created_at") VALUES (21, 14, 1, '2026-10-28 13:24:02');
INSERT INTO wishlist ("id", "user_id", "package_id", "created_at") VALUES (22, 14, 2, '2026-10-28 13:24:04');
INSERT INTO wishlist ("id", "user_id", "package_id", "created_at") VALUES (23, 14, 7, '2026-10-28 13:24:10');
SELECT setval(pg_get_serial_sequence('wishlist', 'id'), COALESCE(MAX(id), 1)) FROM wishlist;

-- Data for wishlist_destinations (2 rows)
INSERT INTO wishlist_destinations ("id", "user_id", "destination_id", "created_at") VALUES (2, 2, 5, '2026-10-28 13:36:13');
INSERT INTO wishlist_destinations ("id", "user_id", "destination_id", "created_at") VALUES (3, 14, 5, '2026-10-28 13:38:10');
SELECT setval(pg_get_serial_sequence('wishlist_destinations', 'id'), COALESCE(MAX(id), 1)) FROM wishlist_destinations;
