-- =========================================================
-- ATLAS TOURISM - DATABASE INITIALIZATION & SCHEMA SCRIPT
-- MCA 2nd Semester Project
-- Database: atlas_tourism
-- Tool Compatibility: MySQL Workbench 8.0 / MySQL Server 8.0+
-- =========================================================

CREATE DATABASE IF NOT EXISTS `atlas_tourism` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `atlas_tourism`;

-- Disable Foreign Key checks temporarily for clean setup
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS `booking_travellers`;
DROP TABLE IF EXISTS `payments`;
DROP TABLE IF EXISTS `reviews`;
DROP TABLE IF EXISTS `wishlist`;
DROP TABLE IF EXISTS `bookings`;
DROP TABLE IF EXISTS `package_itinerary`;
DROP TABLE IF EXISTS `packages`;
DROP TABLE IF EXISTS `destinations`;
DROP TABLE IF EXISTS `offers`;
DROP TABLE IF EXISTS `contact_messages`;
DROP TABLE IF EXISTS `users`;

SET FOREIGN_KEY_CHECKS = 1;

-- ---------------------------------------------------------
-- 1. USERS TABLE
-- ---------------------------------------------------------
CREATE TABLE `users` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `full_name` VARCHAR(100) NOT NULL,
    `username` VARCHAR(50) NOT NULL UNIQUE,
    `email` VARCHAR(100) NOT NULL UNIQUE,
    `phone` VARCHAR(20) NOT NULL,
    `password_hash` VARCHAR(255) NOT NULL,
    `role` ENUM('user', 'admin') NOT NULL DEFAULT 'user',
    `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------
-- 2. DESTINATIONS TABLE
-- ---------------------------------------------------------
CREATE TABLE `destinations` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL,
    `location` VARCHAR(150) NOT NULL,
    `description` TEXT NOT NULL,
    `starting_price` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    `best_time` VARCHAR(100) NOT NULL,
    `things_to_do` TEXT,
    `attractions` TEXT,
    `budget` VARCHAR(100),
    `image_url` VARCHAR(255) NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------
-- 3. PACKAGES TABLE
-- ---------------------------------------------------------
CREATE TABLE `packages` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `destination_id` INT NOT NULL,
    `name` VARCHAR(150) NOT NULL,
    `duration` VARCHAR(50) NOT NULL,
    `duration_days` INT NOT NULL DEFAULT 1,
    `price` DECIMAL(10, 2) NOT NULL,
    `hotel_info` VARCHAR(255) NOT NULL,
    `transport_info` VARCHAR(255) NOT NULL,
    `meals_info` VARCHAR(255) NOT NULL,
    `description` TEXT NOT NULL,
    `inclusions` TEXT,
    `exclusions` TEXT,
    `available_dates` VARCHAR(255) DEFAULT 'Every Weekend & Custom Dates',
    `image_url` VARCHAR(255) NOT NULL,
    `is_featured` BOOLEAN NOT NULL DEFAULT FALSE,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_packages_destination` FOREIGN KEY (`destination_id`) 
        REFERENCES `destinations`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------
-- 4. PACKAGE ITINERARY TABLE
-- ---------------------------------------------------------
CREATE TABLE `package_itinerary` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `package_id` INT NOT NULL,
    `day_number` INT NOT NULL,
    `title` VARCHAR(150) NOT NULL,
    `description` TEXT NOT NULL,
    `activities` TEXT,
    CONSTRAINT `fk_itinerary_package` FOREIGN KEY (`package_id`) 
        REFERENCES `packages`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------
-- 5. OFFERS / DISCOUNT COUPONS TABLE
-- ---------------------------------------------------------
CREATE TABLE `offers` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(50) NOT NULL UNIQUE,
    `description` VARCHAR(255),
    `discount_percent` INT NOT NULL,
    `valid_from` DATE NOT NULL,
    `valid_until` DATE NOT NULL,
    `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------
-- 6. BOOKINGS TABLE
-- ---------------------------------------------------------
CREATE TABLE `bookings` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `booking_number` VARCHAR(30) NOT NULL UNIQUE,
    `user_id` INT NOT NULL,
    `package_id` INT NOT NULL,
    `travel_date` DATE NOT NULL,
    `adults_count` INT NOT NULL DEFAULT 1,
    `children_count` INT NOT NULL DEFAULT 0,
    `base_amount` DECIMAL(10, 2) NOT NULL,
    `discount_amount` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    `total_amount` DECIMAL(10, 2) NOT NULL,
    `offer_id` INT NULL,
    `contact_name` VARCHAR(100) NOT NULL,
    `contact_email` VARCHAR(100) NOT NULL,
    `contact_phone` VARCHAR(20) NOT NULL,
    `special_requests` TEXT,
    `booking_status` ENUM('Pending', 'Confirmed', 'Completed', 'Cancelled') NOT NULL DEFAULT 'Pending',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_bookings_user` FOREIGN KEY (`user_id`) 
        REFERENCES `users`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_bookings_package` FOREIGN KEY (`package_id`) 
        REFERENCES `packages`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_bookings_offer` FOREIGN KEY (`offer_id`) 
        REFERENCES `offers`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------
-- 7. BOOKING TRAVELLERS TABLE
-- ---------------------------------------------------------
CREATE TABLE `booking_travellers` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `booking_id` INT NOT NULL,
    `full_name` VARCHAR(100) NOT NULL,
    `age` INT NOT NULL,
    `gender` VARCHAR(20) NOT NULL,
    CONSTRAINT `fk_travellers_booking` FOREIGN KEY (`booking_id`) 
        REFERENCES `bookings`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------
-- 8. PAYMENTS TABLE
-- ---------------------------------------------------------
CREATE TABLE `payments` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `booking_id` INT NOT NULL,
    `user_id` INT NOT NULL,
    `razorpay_order_id` VARCHAR(100),
    `razorpay_payment_id` VARCHAR(100),
    `razorpay_signature` VARCHAR(255),
    `amount` DECIMAL(10, 2) NOT NULL,
    `currency` VARCHAR(10) NOT NULL DEFAULT 'INR',
    `payment_method` VARCHAR(50) NOT NULL DEFAULT 'Razorpay',
    `payment_status` ENUM('Success', 'Pending', 'Failed') NOT NULL DEFAULT 'Pending',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_payments_booking` FOREIGN KEY (`booking_id`) 
        REFERENCES `bookings`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_payments_user` FOREIGN KEY (`user_id`) 
        REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------
-- 9. WISHLIST TABLE
-- ---------------------------------------------------------
CREATE TABLE `wishlist` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `package_id` INT NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `unique_user_package_wishlist` (`user_id`, `package_id`),
    CONSTRAINT `fk_wishlist_user` FOREIGN KEY (`user_id`) 
        REFERENCES `users`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_wishlist_package` FOREIGN KEY (`package_id`) 
        REFERENCES `packages`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------
-- 10. REVIEWS TABLE
-- ---------------------------------------------------------
CREATE TABLE `reviews` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `package_id` INT NOT NULL,
    `booking_id` INT NULL,
    `rating` INT NOT NULL,
    `review_text` TEXT NOT NULL,
    `is_approved` BOOLEAN NOT NULL DEFAULT FALSE,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `chk_rating_range` CHECK (`rating` >= 1 AND `rating` <= 5),
    CONSTRAINT `fk_reviews_user` FOREIGN KEY (`user_id`) 
        REFERENCES `users`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_reviews_package` FOREIGN KEY (`package_id`) 
        REFERENCES `packages`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_reviews_booking` FOREIGN KEY (`booking_id`) 
        REFERENCES `bookings`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------
-- 11. CONTACT MESSAGES TABLE
-- ---------------------------------------------------------
CREATE TABLE `contact_messages` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL,
    `email` VARCHAR(100) NOT NULL,
    `phone` VARCHAR(20),
    `subject` VARCHAR(150) NOT NULL,
    `message` TEXT NOT NULL,
    `is_read` BOOLEAN NOT NULL DEFAULT FALSE,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- SEED DATA (REALISTIC SAMPLE RECORDS)
-- =========================================================

-- 1. SEED USERS
-- Admin Password: 'admin123'
-- User Passwords: 'user123'
INSERT INTO `users` (`id`, `full_name`, `username`, `email`, `phone`, `password_hash`, `role`, `is_active`) VALUES
(1, 'System Administrator', 'admin', 'admin@atlastourism.com', '+91 9876543210', 'scrypt:32768:8:1$ocUWsRrTriOXtwm3$ac3e5e90aacb290af6ab0027968e08fdcf8ab14ad43f40e0e2a51dee3be2f8d81f553799ca53774fde7c0f79706b9bf638d7af0e52b62bad389c51bec9ede74f', 'admin', 1),
(2, 'John Traveller', 'john_traveller', 'john@example.com', '+91 9811223344', 'scrypt:32768:8:1$UHtIzRpjW2oVGSiH$740a6dba172b9f7ded000ee70e0ffed58fc0b81e7951244d8b070c0a1f880658f98a2d20f5328a666b1290f58691e7ef031c2d6c6053e31ca3c09e047ebe4e39', 'user', 1),
(3, 'Priya Sharma', 'priya_sharma', 'priya@example.com', '+91 9877665544', 'scrypt:32768:8:1$UHtIzRpjW2oVGSiH$740a6dba172b9f7ded000ee70e0ffed58fc0b81e7951244d8b070c0a1f880658f98a2d20f5328a666b1290f58691e7ef031c2d6c6053e31ca3c09e047ebe4e39', 'user', 1);

-- 2. SEED DESTINATIONS
INSERT INTO `destinations` (`id`, `name`, `location`, `description`, `starting_price`, `best_time`, `things_to_do`, `attractions`, `budget`, `image_url`) VALUES
(1, 'Nepal & Himalayas', 'Nepal', 'Experience the rooftop of the world. Nestled against the mighty Himalayan peaks, Nepal offers ancient UNESCO heritage temples in Kathmandu, serene lakeside retreats in Pokhara, and world-renowned alpine trekking routes.', 24999.00, 'September to May', 'Mountain trekking, White-water rafting, Paragliding in Pokhara, Temple heritage walks, Jungle safari in Chitwan', 'Pashupatinath Temple, Phewa Lake, Annapurna Sanctuary, Swayambhunath Stupa, Bhaktapur Durbar Square', '₹25,000 - ₹55,000 per person', 'https://images.unsplash.com/photo-1544735716-392fe2489ffa?auto=format&fit=crop&w=1200&q=80'),
(2, 'Darjeeling', 'West Bengal, India', 'Known as the "Queen of the Hills", Darjeeling charms travellers with rolling emerald tea gardens, the heritage Himalayan Toy Train, breathtaking sunrise vistas over Mount Kanchenjunga, and rich colonial legacy.', 14999.00, 'October to March', 'Tiger Hill sunrise photography, Toy train heritage ride, Tea tasting at Happy Valley, Batasia Loop walk, Peace Pagoda visit', 'Tiger Hill, Batasia Loop, Himalayan Mountaineering Institute, Ghoom Monastery, Nightingale Park', '₹15,000 - ₹30,000 per person', 'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?auto=format&fit=crop&w=1200&q=80'),
(3, 'Varanasi', 'Uttar Pradesh, India', 'One of the oldest continuously inhabited cities on earth, Varanasi is the spiritual heart of India. Revered ghats along the sacred Ganges River, hypnotic evening Ganga Aarti, and profound spiritual tranquility await.', 11999.00, 'October to March', 'Sunrise boat cruise on the Ganga, Witnessing Dashashwamedh Ganga Aarti, Exploring ancient silk lanes, Sarnath Buddhist tour', 'Kashi Vishwanath Temple, Dashashwamedh Ghat, Assi Ghat, Sarnath Deer Park, Manikarnika Ghat', '₹12,000 - ₹25,000 per person', 'https://images.unsplash.com/photo-1627894483216-2138af692e32?q=80&w=687&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D'),
(4, 'Shillong & Meghalaya', 'Meghalaya, India', 'Dubbed the "Scotland of the East", Shillong captivates with mist-covered pine hills, roaring waterfalls, crystal-clear Umngot river in Dawki, and wonderous UNESCO-nominated living root bridges in Cherrapunji.', 18999.00, 'October to April', 'Boating on glassy Dawki River, Trekking double decker root bridges, Exploring Mawsmai Caves, Visiting Elephant Falls', 'Elephant Falls, Umiam Lake, Nohkalikai Falls, Living Root Bridges, Dawki Umngot River', '₹18,000 - ₹40,000 per person', 'https://images.unsplash.com/photo-1593813738953-fb3c93e0769d?q=80&w=1254&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D'),
(5, 'Andaman & Nicobar', 'Union Territory, India', 'An exotic tropical paradise blessed with turquoise waters, pristine white sandy beaches, lush coastal rainforests, historical colonial landmarks, and vibrant coral reef marine ecosystems.', 28999.00, 'November to May', 'Scuba diving and sea-walking at Havelock, Snorkeling at Elephant Beach, Cellular Jail Light & Sound show, Radhanagar sunset', 'Radhanagar Beach, Cellular Jail, Elephant Beach, Ross Island, Neil Island (Shaheed Dweep)', '₹30,000 - ₹65,000 per person', 'https://images.unsplash.com/photo-1640618792277-b91f3199f6a8?q=80&w=1074&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D');

-- 3. SEED PACKAGES (8 Packages across Destinations)
INSERT INTO `packages` (`id`, `destination_id`, `name`, `duration`, `duration_days`, `price`, `hotel_info`, `transport_info`, `meals_info`, `description`, `inclusions`, `exclusions`, `available_dates`, `image_url`, `is_featured`) VALUES
(1, 1, 'Mystical Nepal: Kathmandu & Pokhara Odyssey', '6 Days / 5 Nights', 6, 26999.00, '4-Star Boutique Resort & Lakeside Hotel', 'Private AC Sedan / SUV for all transfers and sightseeing', 'Daily Buffet Breakfast & 2 Traditional Dinners included', 'Explore the cultural soul of Kathmandu followed by the tranquil serenity of Pokhara with panoramic views of the Annapurna mountain range.', 'Hotel accommodation, Airport transfers, Private sightseeing cab, English speaking guide, Entry permits', 'International flights, Personal expenses, Paragliding charges, Travel insurance', 'Weekly Departures every Saturday', 'https://images.unsplash.com/photo-1544735716-392fe2489ffa?auto=format&fit=crop&w=1000&q=80', 1),
(2, 1, 'Everest View & Annapurna Panorama Trek', '8 Days / 7 Nights', 8, 38999.00, 'Premium Himalayan Lodges & Heritage Hotels', 'Tourist coach & Private mountain transfers', 'Full board: Breakfast, Lunch, and Dinner on trek days', 'An exhilarating trek designed for adventure lovers offering close-up vistas of Everest, Annapurna, and Machapuchare peaks with expert Sherpa guides.', 'Trek permits, Sherpa guide, Porter service, All meals during trek, First aid support', 'Personal trekking gear, Emergency evacuation insurance, Tips for porters', '1st & 15th of every month', 'https://images.unsplash.com/photo-1486911278844-a81c5267e227?auto=format&fit=crop&w=1000&q=80', 0),
(3, 2, 'Darjeeling Enchantment & Kanchenjunga Sunrise', '4 Days / 3 Nights', 4, 15999.00, 'Heritage Colonial Hotel with Mountain View', 'Private AC Cab from Bagdogra / NJP', 'Daily Breakfast and Dinner included', 'Wake up to the golden rays hitting Mount Kanchenjunga, ride the iconic Toy Train through misty mountain loops, and stroll along lush tea estates.', 'Pick and drop from Bagdogra/NJP, 3-star hotel stay, All local sightseeing, Toy train ticket assistance', 'Lunch, Any entry fee at monuments, Tips, Personal laundry', 'Every Friday & Monday', 'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?auto=format&fit=crop&w=1000&q=80', 1),
(4, 2, 'Tea Garden Bliss & Mirik Lake Escape', '5 Days / 4 Nights', 5, 18999.00, 'Tea Estate Bungalow & Resort', 'Private AC Vehicle for duration', 'Buffet Breakfast & Authentic Bengali/Nepali Dinner', 'Escape into the aroma of fresh tea leaves with exclusive tea garden stays and a leisure day trip to the calm waters of Mirik Lake.', 'Tea estate bungalow stay, Factory tea tasting, Boating charges at Mirik, Dedicated chauffeur', 'Personal beverages, Horse riding at Mirik, Flight/train tickets', 'Daily departures available', 'https://images.unsplash.com/photo-1564890369478-c89ca6d9cde9?auto=format&fit=crop&w=1000&q=80', 0),
(5, 3, 'Spiritual Kashi & Ancient Sarnath Immersion', '3 Days / 2 Nights', 3, 12999.00, 'Riverside Heritage Haveli Hotel', 'Private AC Car for all transfers', 'Breakfast & Special Banarasi Thali Dinner', 'Immerse your soul in the timeless rituals of Varanasi. Witness sacred morning boat rituals, evening Ganga Aarti from reserved VIP boats, and visit holy Sarnath.', 'VIP boat for Ganga Aarti, Temple darshan assistance, Sarnath museum & stupa entry, Station pickup/drop', 'Camera fees, Pooja offerings, Personal shopping', 'Every Tuesday & Friday', 'https://images.unsplash.com/photo-1627894483216-2138af692e32?q=80&w=687&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D', 1),
(6, 4, 'Meghalaya Wonderland: Cherrapunji & Dawki', '5 Days / 4 Nights', 5, 21999.00, 'Eco Luxury Resort & Riverside Camps', 'Private SUV for tough hill terrain', 'All Breakfasts & Campfire Dinners', 'Discover the wettest place on earth, trek across ancient living root bridges, cruise on the crystal clear waters of Dawki, and explore mystical limestone caves.', 'SUV transportation, Guided root bridge trek, Dawki boating ride, Clean stay with campfire', 'Zip-lining fees, Lunch, Alcoholic beverages', 'Every Thursday departure', 'https://images.unsplash.com/photo-1593813738953-fb3c93e0769d?q=80&w=1254&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D', 1),
(7, 5, 'Andaman Island Dream: Port Blair & Havelock', '5 Days / 4 Nights', 5, 29999.00, 'Beachfront 4-Star Resort at Havelock', 'Makruzz / Green Ocean Luxury Cruise + AC Cab', 'Daily Breakfast & 2 Candlelight Dinners', 'Experience pure island magic at Asia’s best beach (Radhanagar Beach), delve into history at Cellular Jail, and snorkel among dazzling coral reefs.', 'Inter-island ferry tickets (Makruzz AC), Hotel stay with breakfast, Cellular jail light & sound entry, Snorkeling session', 'Water sports outside itinerary, Scuba certification, Airfare', 'Departures every Wednesday & Saturday', 'https://images.unsplash.com/photo-1640618792277-b91f3199f6a8?q=80&w=1074&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D', 1),
(8, 5, 'Exotic Andaman Explorer: Havelock & Neil Island', '6 Days / 5 Nights', 6, 36999.00, 'Premium Beach Villas at Neil & Havelock', 'Private Speedboat transfers & AC cabs', 'Complimentary Breakfast & Seafood Dinners', 'The ultimate tropical honeymoon and leisure escape covering Port Blair, Havelock Island, and the natural rock formations of serene Neil Island.', 'Beach villa stays, Private cruise transfers, Scuba intro dive with instructor, Dedicated tour guide', 'Personal purchases, Lunch, Flight charges', 'Flexible private dates', 'https://images.unsplash.com/photo-1640618792277-b91f3199f6a8?q=80&w=1074&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D', 0);

-- 4. SEED PACKAGE ITINERARIES
INSERT INTO `package_itinerary` (`package_id`, `day_number`, `title`, `description`, `activities`) VALUES
-- Package 1 (Nepal 6 Days)
(1, 1, 'Arrival in Kathmandu & Thamel Exploration', 'Arrive at Tribhuvan International Airport where our representative welcomes you with a traditional garland. Check into your hotel and stroll through Thamel night market.', 'Airport reception, Hotel check-in, Evening stroll in vibrant Thamel'),
(1, 2, 'Kathmandu Cultural Heritage Tour', 'Visit the sacred Pashupatinath Hindu temple, the giant Boudhanath Stupa, and the historic Swayambhunath Monkey Temple overlooking Kathmandu valley.', 'Guided spiritual walking tour, Photography at Boudhanath Stupa'),
(1, 3, 'Scenic Drive to Pokhara Lakeside', 'Take a picturesque drive along the Trishuli River passing terraced hills. Arrive in Pokhara, the adventure capital, and relax by Phewa Lake.', 'Drive through river valleys, Sunset boating on Phewa Lake'),
(1, 4, 'Sarangkot Sunrise & Pokhara Sightseeing', 'Early morning drive to Sarangkot hill for sunrise over Annapurna & Dhaulagiri. Later visit Davis Falls, Gupteshwor Mahadev Cave, and Peace Pagoda.', 'Sunrise photo shoot, Exploring limestone caves, World Peace Pagoda visit'),
(1, 5, 'Return to Kathmandu & Bhaktapur Visit', 'Fly or drive back to Kathmandu. Spend the afternoon exploring Bhaktapur Durbar Square with its magnificent 55-window palace and pottery square.', 'Bhaktapur architectural exploration, Souvenir shopping'),
(1, 6, 'Departure with Himalayan Memories', 'Enjoy your breakfast at leisure. Our driver will escort you to the airport for your onward flight home.', 'Hotel checkout, Airport transfer');

-- Package 3 (Darjeeling 4 Days)
INSERT INTO `package_itinerary` (`package_id`, `day_number`, `title`, `description`, `activities`) VALUES
(3, 1, 'Bagdogra to Darjeeling Hill Drive', 'Pickup from Bagdogra Airport / NJP Station. Enjoy a winding scenic drive through misty valleys and cedar forests. Check-in and relax.', 'Scenic hill drive, Mall Road walking, Glenary’s bakery visit'),
(3, 2, 'Tiger Hill Sunrise & Monastery Tour', 'Wake at 4:00 AM for the world-famous sunrise over Mt. Kanchenjunga from Tiger Hill. Visit Ghoom Monastery and Batasia Loop war memorial.', 'Tiger Hill sunrise spectacle, Batasia Loop garden stroll, Monastery blessing'),
(3, 3, 'Himalayan Mountaineering Institute & Tea Tasting', 'Tour the Himalayan Mountaineering Institute, Padmaja Naidu Zoo (Red Pandas), and spend the afternoon at Happy Valley Tea Estate.', 'HMI museum visit, Red panda sighting, Premium Darjeeling tea tasting'),
(3, 4, 'Toy Train Ride & Departure', 'Morning ride on the UNESCO World Heritage Toy Train before heading back to Bagdogra Airport / NJP with warm hill memories.', 'Heritage toy train ride, Drop-off transfer');

-- Package 5 (Varanasi 3 Days)
INSERT INTO `package_itinerary` (`package_id`, `day_number`, `title`, `description`, `activities`) VALUES
(5, 1, 'Arrival & Ganga Aarti at Dashashwamedh', 'Arrival pickup and transfer to the heritage haveli. In the evening, witness the grand Ganga Aarti from a reserved boat with floating lamps.', 'Check-in, Evening boat cruise, Witnessing grand musical Ganga Aarti'),
(5, 2, 'Sunrise Boat Cruise, Kashi Vishwanath & Sarnath', 'Early morning subah-e-banaras boat ride along the ghats. Darshan at Kashi Vishwanath corridor. Afternoon tour of Sarnath Buddhist monument.', 'Sunrise rowing boat, Temple darshan, Sarnath Dhamek Stupa tour'),
(5, 3, 'Heritage Street Food Walk & Departure', 'Savor authentic Banarasi kachori-jalebi and creamy lassi. Visit famous silk weavers before departing for the airport or railway station.', 'Food tasting walk, Silk weaving demonstration, Departure transfer');

-- Package 6 (Meghalaya 5 Days)
INSERT INTO `package_itinerary` (`package_id`, `day_number`, `title`, `description`, `activities`) VALUES
(6, 1, 'Guwahati to Shillong via Umiam Lake', 'Arrive at Guwahati and drive to Shillong. Stop at scenic Umiam Lake (Barapani) for watersports and photography.', 'Airport pickup, Water sports at Umiam Lake, Check-in at Shillong'),
(6, 2, 'Cherrapunji Waterfalls & Caves', 'Drive to Cherrapunji. Visit roaring Nohkalikai Falls, Wei Sawdong three-tiered falls, and walk inside ancient Mawsmai limestone caves.', 'Waterfall viewpoints, Limestone cave exploration, Cafe hopping'),
(6, 3, 'Double Decker Living Root Bridge Trek', 'Trek into the lush rainforest of Tyrna down to the world-famous Nongriat Double Decker Living Root Bridge and turquoise natural pools.', 'Rainforest trekking, Swimming in crystal natural pools, Bio-engineering marvels'),
(6, 4, 'Dawki Umngot River & Mawlynnong Cleanest Village', 'Visit Mawlynnong, cleanest village in Asia. Boating on the surreal transparent waters of Umngot River along the Indo-Bangladesh border.', 'Boating on glassy river, Walking around Mawlynnong flower paths, Campfire night'),
(6, 5, 'Elephant Falls & Departure to Guwahati', 'Visit picturesque Elephant Falls and Shillong Peak before returning to Guwahati airport for your onward journey.', 'Elephant falls photo stop, Airport drop-off');

-- Package 7 (Andaman 5 Days)
INSERT INTO `package_itinerary` (`package_id`, `day_number`, `title`, `description`, `activities`) VALUES
(7, 1, 'Arrival at Port Blair & Cellular Jail', 'Meet and greet at Veer Savarkar Airport. Check-in to hotel. In the afternoon, visit historical Cellular Jail and attend the patriotic Light & Sound show.', 'Airport transfer, Cellular jail tour, Sound and light show'),
(7, 2, 'Luxury Cruise to Havelock & Radhanagar Sunset', 'Board premium AC catamaran cruise to Havelock Island (Swaraj Dweep). Spend a magical evening watching the sunset at Radhanagar Beach (Beach No. 7).', 'High-speed catamaran cruise, Beach relaxation, Spectacular sunset views'),
(7, 3, 'Elephant Beach Snorkeling & Coral Reef Adventure', 'Speedboat ride to Elephant Beach. Indulge in complimentary snorkeling amidst colorful coral reefs and exotic tropical fish.', 'Speedboat adventure, Guided snorkeling, Optional jet-skiing and banana boat'),
(7, 4, 'Kalapathar Beach & Return to Port Blair', 'Morning visit to picturesque Kalapathar Beach with turquoise waters and black rocks. Afternoon cruise back to Port Blair.', 'Beach photography, Return cruise to Port Blair, Local handicraft shopping'),
(7, 5, 'Departure from Port Blair', 'Enjoy breakfast overlooking the ocean. Transfer to airport with unforgettable tropical island memories.', 'Check-out, Airport drop');

-- 5. SEED OFFERS / COUPONS
INSERT INTO `offers` (`id`, `code`, `description`, `discount_percent`, `valid_from`, `valid_until`, `is_active`) VALUES
(1, 'EXPLORE15', 'Flat 15% discount on all tour packages', 15, '2026-01-01', '2026-12-31', 1),
(2, 'SUMMER20', 'Special Summer Holiday 20% Discount', 20, '2026-03-01', '2026-08-31', 1),
(3, 'ATLASNEW', 'Welcome Offer: 10% discount for new travellers', 10, '2026-01-01', '2026-12-31', 1);

-- 6. SEED BOOKINGS
INSERT INTO `bookings` (`id`, `booking_number`, `user_id`, `package_id`, `travel_date`, `adults_count`, `children_count`, `base_amount`, `discount_amount`, `total_amount`, `offer_id`, `contact_name`, `contact_email`, `contact_phone`, `special_requests`, `booking_status`, `created_at`) VALUES
(1, 'ATL-2026-1001', 2, 1, '2026-10-15', 2, 0, 53998.00, 8099.70, 45898.30, 1, 'John Traveller', 'john@example.com', '+91 9811223344', 'Vegetarian meals preferred and high floor hotel room please.', 'Confirmed', '2026-09-01 10:30:00'),
(2, 'ATL-2026-1002', 2, 3, '2026-08-10', 1, 0, 15999.00, 0.00, 15999.00, NULL, 'John Traveller', 'john@example.com', '+91 9811223344', 'Window seat for the scenic drive.', 'Completed', '2026-08-01 14:20:00'),
(3, 'ATL-2026-1003', 3, 7, '2026-11-20', 2, 1, 71997.00, 10799.55, 61197.45, 1, 'Priya Sharma', 'priya@example.com', '+91 9877665544', 'Celebrating wedding anniversary. Need candlelight dinner setup.', 'Confirmed', '2026-09-10 16:45:00'),
(4, 'ATL-2026-1004', 3, 5, '2026-09-28', 1, 0, 12999.00, 1299.90, 11699.10, 3, 'Priya Sharma', 'priya@example.com', '+91 9877665544', 'Pickup from Varanasi Junction Railway Station.', 'Pending', '2026-09-20 11:15:00');

-- 7. SEED BOOKING TRAVELLERS
INSERT INTO `booking_travellers` (`booking_id`, `full_name`, `age`, `gender`) VALUES
(1, 'John Traveller', 29, 'Male'),
(1, 'Sarah Traveller', 27, 'Female'),
(2, 'John Traveller', 29, 'Male'),
(3, 'Priya Sharma', 31, 'Female'),
(3, 'Rohit Sharma', 34, 'Male'),
(3, 'Aarav Sharma', 6, 'Male'),
(4, 'Priya Sharma', 31, 'Female');

-- 8. SEED PAYMENTS
INSERT INTO `payments` (`id`, `booking_id`, `user_id`, `razorpay_order_id`, `razorpay_payment_id`, `razorpay_signature`, `amount`, `currency`, `payment_method`, `payment_status`, `created_at`) VALUES
(1, 1, 2, 'order_mock_001_nepal', 'pay_rzp_mock_987123', 'sig_valid_mock_signature_1', 45898.30, 'INR', 'Razorpay UPI', 'Success', '2026-09-01 10:35:00'),
(2, 2, 2, 'order_mock_002_darj', 'pay_rzp_mock_456789', 'sig_valid_mock_signature_2', 15999.00, 'INR', 'Razorpay NetBanking', 'Success', '2026-08-01 14:25:00'),
(3, 3, 3, 'order_mock_003_andaman', 'pay_rzp_mock_112233', 'sig_valid_mock_signature_3', 61197.45, 'INR', 'Razorpay Card', 'Success', '2026-09-10 16:50:00');

-- 9. SEED WISHLIST
INSERT INTO `wishlist` (`user_id`, `package_id`) VALUES
(2, 6),
(2, 7),
(3, 1);

-- 10. SEED REVIEWS
INSERT INTO `reviews` (`user_id`, `package_id`, `booking_id`, `rating`, `review_text`, `is_approved`, `created_at`) VALUES
(2, 3, 2, 5, 'The Darjeeling trip was absolutely breathtaking! Tiger Hill sunrise over Mount Kanchenjunga was a once-in-a-lifetime sight. Our driver and guide from Atlas Tourism were punctual, polite, and very knowledgeable.', 1, '2026-08-16 09:12:00'),
(3, 7, NULL, 5, 'Unbelievable experience in the Andaman Islands! Radhanagar Beach really lives up to the reputation of being among the finest beaches in the world. Seamless arrangements and top-class hotels.', 1, '2026-07-20 18:40:00'),
(2, 1, 1, 5, 'Nepal was mesmerizing. Walking through Kathmandu heritage squares and waking up next to Pokhara lake was so peaceful. Everything was managed with utmost professionalism.', 1, '2026-09-15 14:22:00'),
(3, 5, NULL, 4, 'The Ganga Aarti boat experience in Varanasi was divine. Highly recommend Atlas Tourism for family trips.', 1, '2026-09-18 12:00:00');

-- 11. SEED CONTACT MESSAGES
INSERT INTO `contact_messages` (`name`, `email`, `phone`, `subject`, `message`, `is_read`, `created_at`) VALUES
('Rahul Verma', 'rahul.v@gmail.com', '+91 9845123456', 'Custom Honeymoon Package to Andaman', 'Hi, we are planning our honeymoon in December for 7 days. Can you customize the Andaman package with water villa and private cruise?', 1, '2026-09-18 15:30:00'),
('Sunita Roy', 'sunita.roy@yahoo.com', '+91 9733445566', 'Group booking for Darjeeling & Sikkim', 'We are a college group of 14 students looking for an affordable 5-day tour to Darjeeling. Do you offer student discounts?', 0, '2026-09-21 09:15:00');

-- End of Database Script
