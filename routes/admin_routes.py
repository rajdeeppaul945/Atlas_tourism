"""
Admin Portal Blueprint
Provides administrative operations for dashboard analytics, users, destinations,
packages, itineraries, bookings, payments, reviews, and promotional offers.
"""

from flask import Blueprint, render_template, request, redirect, url_for, flash, session, jsonify, abort
from models.user_model import UserModel
from models.destination_model import DestinationModel
from models.package_model import PackageModel
from models.booking_model import BookingModel
from models.payment_model import PaymentModel
from models.review_model import ReviewModel
from models.offer_model import OfferModel
from models.contact_model import ContactModel
from utils.auth import admin_required

admin_bp = Blueprint('admin', __name__, url_prefix='/admin')

# 1. Admin Dashboard
@admin_bp.route('/dashboard')
@admin_required
def dashboard():
    stats = BookingModel.get_summary_stats()
    stats['total_users'] = UserModel.count_users()
    stats['total_destinations'] = DestinationModel.count()
    stats['total_packages'] = PackageModel.count()
    stats['total_payments'] = PaymentModel.count()
    stats['unread_messages'] = ContactModel.count_unread()

    recent_bookings = BookingModel.get_all()[:6]
    return render_template('admin/dashboard.html', stats=stats, recent_bookings=recent_bookings)

# 1.1 Dashboard Chart API
@admin_bp.route('/api/chart-data')
@admin_required
def chart_data():
    monthly_bookings = BookingModel.get_monthly_bookings_chart()
    monthly_revenue = BookingModel.get_monthly_revenue_chart()
    popular_destinations = BookingModel.get_popular_destinations_chart()

    return jsonify({
        'bookings': monthly_bookings,
        'revenue': monthly_revenue,
        'destinations': popular_destinations
    })

# 2. User Management
@admin_bp.route('/users')
@admin_required
def users():
    all_users = UserModel.get_all_users()
    return render_template('admin/users.html', users=all_users)

@admin_bp.route('/users/toggle-status/<int:user_id>', methods=['POST'])
@admin_required
def toggle_user_status(user_id):
    if user_id == session.get('user_id'):
        flash('You cannot deactivate your own administrative account.', 'warning')
        return redirect(url_for('admin.users'))

    is_active = request.form.get('is_active') == '1'
    UserModel.toggle_status(user_id, is_active)
    flash(f"User account {'activated' if is_active else 'deactivated'} successfully.", 'success')
    return redirect(url_for('admin.users'))

# 3. Destination Management
@admin_bp.route('/destinations')
@admin_required
def destinations():
    all_destinations = DestinationModel.get_all()
    return render_template('admin/destinations.html', destinations=all_destinations)

@admin_bp.route('/destinations/create', methods=['POST'])
@admin_required
def create_destination():
    name = request.form.get('name', '').strip()
    location = request.form.get('location', '').strip()
    description = request.form.get('description', '').strip()
    starting_price = float(request.form.get('starting_price', 0))
    best_time = request.form.get('best_time', '').strip()
    things_to_do = request.form.get('things_to_do', '').strip()
    attractions = request.form.get('attractions', '').strip()
    budget = request.form.get('budget', '').strip()
    image_url = request.form.get('image_url', '').strip()

    if not all([name, location, description, image_url]):
        flash('Name, Location, Description, and Image URL are required.', 'danger')
        return redirect(url_for('admin.destinations'))

    DestinationModel.create(name, location, description, starting_price, best_time, things_to_do, attractions, budget, image_url)
    flash(f"Destination '{name}' created successfully!", 'success')
    return redirect(url_for('admin.destinations'))

@admin_bp.route('/destinations/edit/<int:destination_id>', methods=['POST'])
@admin_required
def edit_destination(destination_id):
    name = request.form.get('name', '').strip()
    location = request.form.get('location', '').strip()
    description = request.form.get('description', '').strip()
    starting_price = float(request.form.get('starting_price', 0))
    best_time = request.form.get('best_time', '').strip()
    things_to_do = request.form.get('things_to_do', '').strip()
    attractions = request.form.get('attractions', '').strip()
    budget = request.form.get('budget', '').strip()
    image_url = request.form.get('image_url', '').strip()

    DestinationModel.update(destination_id, name, location, description, starting_price, best_time, things_to_do, attractions, budget, image_url)
    flash(f"Destination '{name}' updated successfully!", 'success')
    return redirect(url_for('admin.destinations'))

@admin_bp.route('/destinations/delete/<int:destination_id>', methods=['POST'])
@admin_required
def delete_destination(destination_id):
    DestinationModel.delete(destination_id)
    flash('Destination deleted successfully.', 'info')
    return redirect(url_for('admin.destinations'))

# 4. Package Management
@admin_bp.route('/packages')
@admin_required
def packages():
    all_packages = PackageModel.get_all()
    all_destinations = DestinationModel.get_all()
    return render_template('admin/packages.html', packages=all_packages, destinations=all_destinations)

@admin_bp.route('/packages/create', methods=['POST'])
@admin_required
def create_package():
    destination_id = int(request.form.get('destination_id'))
    name = request.form.get('name', '').strip()
    duration = request.form.get('duration', '').strip()
    duration_days = int(request.form.get('duration_days', 1))
    price = float(request.form.get('price', 0))
    hotel_info = request.form.get('hotel_info', '').strip()
    transport_info = request.form.get('transport_info', '').strip()
    meals_info = request.form.get('meals_info', '').strip()
    description = request.form.get('description', '').strip()
    inclusions = request.form.get('inclusions', '').strip()
    exclusions = request.form.get('exclusions', '').strip()
    available_dates = request.form.get('available_dates', 'Weekly Departures').strip()
    image_url = request.form.get('image_url', '').strip()
    is_featured = request.form.get('is_featured') == '1'

    package_id = PackageModel.create(
        destination_id, name, duration, duration_days, price, hotel_info, transport_info, meals_info,
        description, inclusions, exclusions, available_dates, image_url, is_featured
    )
    flash(f"Tour package '{name}' added successfully!", 'success')
    return redirect(url_for('admin.packages'))

@admin_bp.route('/packages/edit/<int:package_id>', methods=['POST'])
@admin_required
def edit_package(package_id):
    destination_id = int(request.form.get('destination_id'))
    name = request.form.get('name', '').strip()
    duration = request.form.get('duration', '').strip()
    duration_days = int(request.form.get('duration_days', 1))
    price = float(request.form.get('price', 0))
    hotel_info = request.form.get('hotel_info', '').strip()
    transport_info = request.form.get('transport_info', '').strip()
    meals_info = request.form.get('meals_info', '').strip()
    description = request.form.get('description', '').strip()
    inclusions = request.form.get('inclusions', '').strip()
    exclusions = request.form.get('exclusions', '').strip()
    available_dates = request.form.get('available_dates', '').strip()
    image_url = request.form.get('image_url', '').strip()
    is_featured = request.form.get('is_featured') == '1'

    PackageModel.update(
        package_id, destination_id, name, duration, duration_days, price, hotel_info,
        transport_info, meals_info, description, inclusions, exclusions, available_dates,
        image_url, is_featured
    )
    flash(f"Package '{name}' updated successfully!", 'success')
    return redirect(url_for('admin.packages'))

@admin_bp.route('/packages/delete/<int:package_id>', methods=['POST'])
@admin_required
def delete_package(package_id):
    PackageModel.delete(package_id)
    flash('Package deleted successfully.', 'info')
    return redirect(url_for('admin.packages'))

# 4.1 Package Itinerary Management
@admin_bp.route('/packages/<int:package_id>/itinerary', methods=['GET', 'POST'])
@admin_required
def manage_itinerary(package_id):
    package = PackageModel.get_by_id(package_id)
    if not package:
        abort(404)

    if request.method == 'POST':
        action = request.form.get('action')
        if action == 'add_day':
            day_number = int(request.form.get('day_number', 1))
            title = request.form.get('title', '').strip()
            description = request.form.get('description', '').strip()
            activities = request.form.get('activities', '').strip()
            PackageModel.add_itinerary_day(package_id, day_number, title, description, activities)
            flash(f"Day {day_number} added to itinerary.", 'success')
        elif action == 'clear_all':
            PackageModel.delete_itinerary(package_id)
            flash('Itinerary cleared.', 'info')
        return redirect(url_for('admin.manage_itinerary', package_id=package_id))

    itinerary = PackageModel.get_itinerary(package_id)
    return render_template('admin/package_itinerary.html', package=package, itinerary=itinerary)

# 5. Booking Management
@admin_bp.route('/bookings')
@admin_required
def bookings():
    status_filter = request.args.get('status')
    search = request.args.get('search')
    all_bookings = BookingModel.get_all(status_filter=status_filter, search=search)
    return render_template('admin/bookings.html', bookings=all_bookings, current_filter=status_filter, search=search)

@admin_bp.route('/bookings/update-status/<int:booking_id>', methods=['POST'])
@admin_required
def update_booking_status(booking_id):
    new_status = request.form.get('status')
    BookingModel.update_status(booking_id, new_status)
    flash(f"Booking status updated to '{new_status}'.", 'success')
    return redirect(url_for('admin.bookings'))

# 6. Payment Inspector (Read-Only)
@admin_bp.route('/payments')
@admin_required
def payments():
    all_payments = PaymentModel.get_all()
    return render_template('admin/payments.html', payments=all_payments)

# 7. Review Moderation
@admin_bp.route('/reviews')
@admin_required
def reviews():
    all_reviews = ReviewModel.get_all_for_admin()
    return render_template('admin/reviews.html', reviews=all_reviews)

@admin_bp.route('/reviews/approve/<int:review_id>', methods=['POST'])
@admin_required
def approve_review(review_id):
    ReviewModel.approve(review_id)
    flash('Review approved and published publicly.', 'success')
    return redirect(url_for('admin.reviews'))

@admin_bp.route('/reviews/delete/<int:review_id>', methods=['POST'])
@admin_required
def delete_review(review_id):
    ReviewModel.delete(review_id)
    flash('Review deleted.', 'info')
    return redirect(url_for('admin.reviews'))

# 8. Promotional Offers Management
@admin_bp.route('/offers')
@admin_required
def offers():
    all_offers = OfferModel.get_all()
    return render_template('admin/offers.html', offers=all_offers)

@admin_bp.route('/offers/create', methods=['POST'])
@admin_required
def create_offer():
    code = request.form.get('code', '').strip().upper()
    description = request.form.get('description', '').strip()
    discount_percent = int(request.form.get('discount_percent', 10))
    valid_from = request.form.get('valid_from')
    valid_until = request.form.get('valid_until')
    is_active = request.form.get('is_active') == '1'

    try:
        OfferModel.create(code, description, discount_percent, valid_from, valid_until, is_active)
        flash(f"Offer '{code}' created successfully!", 'success')
    except Exception as e:
        flash(f"Failed to create offer: {str(e)}", 'danger')

    return redirect(url_for('admin.offers'))

@admin_bp.route('/offers/toggle/<int:offer_id>', methods=['POST'])
@admin_required
def toggle_offer(offer_id):
    is_active = request.form.get('is_active') == '1'
    OfferModel.toggle_status(offer_id, is_active)
    flash('Offer status updated.', 'success')
    return redirect(url_for('admin.offers'))

@admin_bp.route('/offers/delete/<int:offer_id>', methods=['POST'])
@admin_required
def delete_offer(offer_id):
    OfferModel.delete(offer_id)
    flash('Offer deleted.', 'info')
    return redirect(url_for('admin.offers'))

# 9. Contact Messages View
@admin_bp.route('/contact-messages')
@admin_required
def contact_messages():
    messages = ContactModel.get_all()
    return render_template('admin/contact_messages.html', messages=messages)

@admin_bp.route('/contact-messages/read/<int:message_id>', methods=['POST'])
@admin_required
def mark_message_read(message_id):
    ContactModel.mark_as_read(message_id)
    flash('Message marked as read.', 'info')
    return redirect(url_for('admin.contact_messages'))
