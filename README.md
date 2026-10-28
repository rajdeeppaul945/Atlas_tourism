<<<<<<< HEAD
# Atlas Tourism - Full-Stack Travel Booking Website
**MCA 2nd Semester Project Documentation**

---

## 1. Project Overview

**Atlas Tourism** is an enterprise-grade, responsive, full-stack tourism and holiday booking web application developed specifically for an **MCA (Master of Computer Applications) 2nd Semester** project. 

The website delivers a modern, light-themed, real-world travel agency experience. Travellers can discover destinations across the Indian subcontinent and Himalayas, explore curated multi-day tour packages with day-wise itineraries, dynamically calculate booking costs based on party size and promotional coupons, submit payments via a dual-mode Razorpay gateway (with an academic demo sandbox), and receive printable travel confirmation vouchers.

A dedicated administrative portal provides analytics dashboards powered by **Chart.js**, full CRUD controls for destinations and packages, day-by-day itinerary builders, booking status tracking, payment audit logs, customer review moderation, and promotional coupon management.

---

## 2. Key Features

### For Travellers & Guests:
- **Responsive Landing Page**: Hero banner with dual-mode search, statistics counter, popular destinations, featured tour packages, why-us value propositions, approved reviews, and quick call-to-actions.
- **Destination Catalog**: Filter and inspect destinations (e.g. Nepal, Darjeeling, Varanasi, Shillong, Andaman & Nicobar) with best season to visit, average budget, top attractions, and linked tour packages.
- **Tour Packages & Day-Wise Itineraries**: Rich package cards with durations, inclusions/exclusions, meal/transport/hotel amenities, and detailed daily schedules.
- **Interactive Search & Filtering**: Multi-facet filtering by destination, trip duration (Short, Medium, Extended), price ranges, and text keywords.
- **Dynamic Booking Calculation**: Real-time client & server price computation:
  $$\text{Total Amount} = (\text{Price} \times \text{Adults}) + (\text{Price} \times 0.6 \times \text{Children}) - \text{Discount}$$
- **Promotional Coupons**: Live coupon validation for promotional codes (e.g., `EXPLORE15`, `ATLASNEW`).
- **Secure Dual-Mode Payment**:
  - **Live Razorpay Test Mode**: Renders the official Razorpay Checkout modal for UPI/Card testing.
  - **Academic Demonstration Sandbox**: Instant 1-click test checkout allowing offline presentations and examiner evaluations without API keys.
  - **Zero Card Data Storage**: Strictly never stores sensitive card or CVV information in the database.
- **Printable Travel Voucher**: Printable booking confirmation voucher (`@media print` clean layout).
- **Personal Traveller Portal**: Summary cards, upcoming trip alarms, past booking records, saved wishlist, and post-trip review submissions.
- **Password Security**: Eye toggle visibility controls, PBKDF2:SHA256 password hashing, and simulated forgot-password recovery.

### For Administrators:
- **Role-Based Access Control**: Strict `@admin_required` decorators; standard travellers cannot access admin routes.
- **Interactive Analytics Dashboard**: Total users, destinations, packages, bookings, total revenue, and pending orders.
- **Chart.js Visualizations**: Monthly booking volume bar chart, revenue trendline, and top destinations doughnut chart.
- **Destination & Package CRUD**: Add, edit, delete, and feature tour packages and destinations with modal forms.
- **Package Itinerary Builder**: Append or manage day-wise schedules (`Day 1`, `Day 2`, etc.) with titles and activities.
- **Order Management**: Search, filter by status (`Pending`, `Confirmed`, `Completed`, `Cancelled`), and update bookings.
- **Payment Audit Log**: Read-only log of transaction IDs, customer names, payment methods, and timestamps.
- **Review Moderation**: One-click approval desk to verify reviews before they appear publicly.
- **Promotional Coupon Management**: Create, toggle active/inactive, or delete discount promo codes.
- **Inquiry Inbox**: Review messages sent via the Contact Us form and mark them as read.

---

## 3. Technology Stack

| Layer | Technology |
|---|---|
| **Frontend** | HTML5, CSS3, JavaScript (ES6+), Bootstrap 5.3, Bootstrap Icons 1.11 |
| **Styling & Fonts** | Custom CSS with Poppins font, CSS Grid, Flexbox, `@media print` |
| **Charting** | Chart.js 4.x (via CDN) |
| **Backend** | Python 3.10+ / Flask 3.x |
| **Templating** | Jinja2 Templates (with custom currency and date filters) |
| **Database** | MySQL Server 8.0+ / MySQL Workbench 8.0 |
| **Database Driver** | PyMySQL 1.2+ & mysql-connector-python 9.x |
| **Security** | Werkzeug (`generate_password_hash`, `check_password_hash`), Session cookies (`HttpOnly`, `SameSite=Lax`) |
| **Payment Gateway** | Razorpay Python SDK & Checkout JS (with integrated fallback Demo Sandbox) |

---

## 4. Project Directory Structure

```
atlas_tourism/
│
├── app.py                     # Flask application factory and blueprint registration
├── config.py                  # Environment-driven configuration
├── requirements.txt           # Python dependencies
├── .env                       # Environment credentials (MySQL, Razorpay, Secret Key)
├── .env.example               # Template for environment configuration
├── README.md                  # Comprehensive setup manual & project documentation
│
├── database/
│   ├── tourism_database.sql   # Complete SQL DDL schema + realistic sample data
│   └── db_setup.py            # 1-Click database and table initialization script
│
├── models/                    # Data Access Objects (parameterized queries)
│   ├── user_model.py          # User registration, authentication, profile updates
│   ├── destination_model.py   # Destination CRUD, search, and details
│   ├── package_model.py       # Package CRUD, filters, and itinerary operations
│   ├── booking_model.py       # Bookings, travellers, status transitions, analytics
│   ├── payment_model.py       # Payment transaction logging
│   ├── review_model.py        # Rating and review moderation
│   ├── wishlist_model.py      # Wishlist toggle and duplication prevention
│   ├── offer_model.py         # Promotional code verification and CRUD
│   └── contact_model.py       # Contact messages storage and inbox
│
├── routes/                    # Modular Flask Blueprints
│   ├── auth_routes.py         # /login, /register, /logout, /forgot-password
│   ├── home_routes.py         # / (Landing page), /search
│   ├── destination_routes.py  # /destinations, /destinations/<id>
│   ├── package_routes.py      # /packages, /packages/<id>
│   ├── booking_routes.py      # /booking/book/<id>, /booking/confirmation/<id>
│   ├── payment_routes.py      # /payment/checkout/<id>, /payment/callback, /payment/demo-process
│   ├── wishlist_routes.py     # /wishlist/toggle/<id>, /wishlist/remove/<id>
│   ├── user_routes.py         # /user/dashboard, /profile, /bookings, /wishlist, /reviews
│   ├── contact_routes.py      # /about, /contact, /faq, /api/validate-offer
│   └── admin_routes.py        # /admin/dashboard, users, destinations, packages, bookings, etc.
│
├── templates/                 # Jinja2 HTML Templates
│   ├── base.html              # Main layout (Navbar, flash alerts, footer)
│   ├── home/index.html        # Landing page with hero, search, stats, why us, reviews
│   ├── auth/                  # Login, Register, Forgot Password, Reset Password
│   ├── destinations/          # Destination listing & destination details
│   ├── packages/              # Package listing with filter sidebar & package details with itinerary
│   ├── booking/               # Booking form, payment gateway page, printable confirmation voucher
│   ├── user/                  # Dashboard, profile, my bookings, booking details, wishlist, reviews
│   ├── about/about.html       # Company introduction, mission, vision, guide highlights
│   ├── contact/contact.html   # Contact form, office address, emergency numbers
│   ├── faq/faq.html           # Bootstrap accordion FAQ
│   ├── admin/                 # Admin layout, dashboard, users, destinations, packages, bookings, etc.
│   └── errors/                # 404 and 500 error pages
│
├── static/
│   ├── css/style.css          # Custom styling, Poppins font, elevated cards, print styles
│   ├── js/main.js             # Eye toggles, dynamic price calculation, coupon validation
│   ├── js/admin_charts.js     # Chart.js analytics loader
│   ├── images/                # Static assets & placeholders
│   └── uploads/               # Dynamic uploads folder
│
└── utils/
    ├── database.py            # Safe PyMySQL connection factory with dictionary cursor
    ├── auth.py                # Password hashing and @login_required, @admin_required decorators
    ├── email_service.py       # Simulated email dispatch logger
    └── helpers.py             # Indian Rupee formatting (₹) and unique reference generator
```

---

## 5. MySQL Database Setup

### Option A: Using the Automated Python Script (Recommended)
You can set up the database and all seed data with a single command:
```bash
python database/db_setup.py
```
This automatically connects to your MySQL server, creates the database `atlas_tourism`, builds all 11 tables with foreign keys, and inserts all realistic sample data.

### Option B: Using MySQL Workbench
1. Open **MySQL Workbench**.
2. Connect to your local MySQL instance (e.g. `localhost:3306`).
3. Click on **File > Open SQL Script...** (or press `Ctrl + Shift + O`).
4. Select `database/tourism_database.sql` from this project folder.
5. Click the **Execute (Lightning Icon)** button or press `Ctrl + Shift + Enter`.
6. Refresh your schema list in the left panel to verify `atlas_tourism` and its 11 tables.

---

## 6. Python Environment Setup & Installation

### Step 1: Clone or Navigate to the Project Folder
Open VS Code in the project root:
```bash
cd atlas_tourism
```

### Step 2: (Optional) Create and Activate a Virtual Environment
```bash
# Windows
python -m venv venv
venv\Scripts\activate

# macOS / Linux
python3 -m venv venv
source venv/bin/activate
```

### Step 3: Install Required Packages
```bash
pip install -r requirements.txt
```

---

## 7. Environment Configuration (`.env`)

The project uses a `.env` file for local secrets. Ensure your `.env` contains your MySQL credentials:

```ini
# Atlas Tourism Environment Configuration
SECRET_KEY=atlas_tourism_mca_secure_secret_key_2026

# MySQL Database Configuration
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_USER=root
MYSQL_PASSWORD=your_mysql_password
MYSQL_DB=atlas_tourism

# Razorpay Test / Sandbox Credentials
# Leave demo payment mode enabled for seamless offline/viva testing
RAZORPAY_KEY_ID=rzp_test_sampleKey12345
RAZORPAY_KEY_SECRET=sampleSecret67890
DEMO_PAYMENT_MODE=True
```

---

## 8. Running the Application

Start the Flask development server:
```bash
python app.py
```

Open your web browser and navigate to:
```
http://127.0.0.1:5000
```

---

## 9. Pre-Configured Test Credentials

The database comes pre-seeded with accounts for immediate testing:

| Role | Email / Username | Password | Notes |
|---|---|---|---|
| **Administrator** | `admin@atlastourism.com` (or `admin`) | `admin123` | Full access to `/admin/dashboard` |
| **Traveller 1** | `john@example.com` (or `john_traveller`) | `user123` | Has upcoming & past bookings |
| **Traveller 2** | `priya@example.com` (or `priya_sharma`) | `user123` | Has active wishlist items |

---

## 10. Sample Data Included

1. **5 Destinations**:
   - Nepal & Himalayas
   - Darjeeling (Queen of the Hills)
   - Varanasi (Spiritual Ghats & Sarnath)
   - Shillong & Meghalaya (Living Root Bridges & Dawki)
   - Andaman & Nicobar (Radhanagar Beach & Scuba)
2. **8 Tour Packages**:
   - Mystical Nepal: Kathmandu & Pokhara Odyssey (6 Days)
   - Everest View & Annapurna Panorama Trek (8 Days)
   - Darjeeling Enchantment & Kanchenjunga Sunrise (4 Days)
   - Tea Garden Bliss & Mirik Lake Escape (5 Days)
   - Spiritual Kashi & Ancient Sarnath Immersion (3 Days)
   - Meghalaya Wonderland: Cherrapunji & Dawki (5 Days)
   - Andaman Island Dream: Port Blair & Havelock (5 Days)
   - Exotic Andaman Explorer: Havelock & Neil Island (6 Days)
3. **Day-wise Itineraries**: Daily itineraries mapped in `package_itinerary`.
4. **Active Promo Coupons**:
   - `EXPLORE15` - 15% discount
   - `SUMMER20` - 20% discount
   - `ATLASNEW` - 10% discount

---

## 11. Razorpay Testing & Demonstration Mode

- **Live Sandbox**: If you have a Razorpay test key and secret, input them into `.env`. The checkout page will automatically render the official Razorpay modal.
- **Academic Demo Mode**: When running locally without live keys, the checkout page automatically activates the **Academic Demonstration Sandbox**. Clicking **Confirm Test Payment** simulates an authentic payment callback, generates an official reference ID (`pay_demo_...`), updates the booking in MySQL to `Confirmed`, logs a simulated confirmation email, and opens the printable voucher.

---

## 12. Troubleshooting & Common Questions (MCA Viva Prep)

**Q1: What happens if I get MySQL `Access denied for user 'root'@'localhost'`?**  
- Check your password in `.env`. Ensure `MYSQL_PASSWORD` matches the root password you configured when installing MySQL Server or Workbench.

**Q2: How does the application prevent SQL Injection?**  
- Every database interaction in the `models/` directory uses parameterized SQL queries (`%s` placeholders passed as tuples to PyMySQL). Raw user input is never concatenated directly into SQL strings.

**Q3: How are passwords secured?**  
- Passwords are salted and hashed using Werkzeug's implementation of PBKDF2 with SHA-256 (`generate_password_hash`). Plaintext passwords are never stored in the database or displayed in the admin panel.

**Q4: Can a regular traveller access admin routes?**  
- No. Admin routes are guarded by the `@admin_required` decorator. If a user without `role = 'admin'` attempts to navigate to `/admin/...`, the system redirects them to their user dashboard with an access denied flash message.

**Q5: How does the print voucher work?**  
- The confirmation template incorporates CSS `@media print` rules that automatically hide navigation bars, footers, and buttons when the user clicks **Print Booking Voucher** or uses `Ctrl + P`, leaving a clean, official invoice document.

---

**Developed for MCA 2nd Semester Project**  
*Atlas Tourism — Discover Your Next Adventure*
=======
# Atlas_tourism
>>>>>>> 1f27a6ebccb3fb7a27ea924eeaccc75acad1fea4
