"""
User Dashboard Blueprint
Handles user portal, profile editing, bookings history, wishlist, and reviews.
"""

from flask import Blueprint, render_template, request, redirect, url_for, flash, session, abort
from models.user_model import UserModel
from models.booking_model import BookingModel
from models.wishlist_model import WishlistModel
from models.review_model import ReviewModel
from models.package_model import PackageModel
from utils.validators import validate_email_authenticity, validate_phone_authenticity, COUNTRY_LIST
from utils.auth import login_required, verify_password

user_bp = Blueprint('user', __name__, url_prefix='/user')

@user_bp.route('/dashboard')
@login_required
def dashboard():
    user_id = session['user_id']
    user = UserModel.get_by_id(user_id)
    if not user:
        session.clear()
        return redirect(url_for('auth.login'))

    counts = BookingModel.get_user_dashboard_counts(user_id)
    upcoming_bookings = BookingModel.get_user_bookings(user_id, filter_type='upcoming')
    recent_bookings = BookingModel.get_user_bookings(user_id)[:3]
    wishlist_items = WishlistModel.get_by_user(user_id)[:3]
    reviews = ReviewModel.get_user_reviews(user_id)[:3]

    return render_template(
        'user/dashboard.html',
        user=user,
        counts=counts,
        upcoming_bookings=upcoming_bookings,
        recent_bookings=recent_bookings,
        wishlist_items=wishlist_items,
        reviews=reviews
    )

@user_bp.route('/profile', methods=['GET', 'POST'])
@login_required
def profile():
    user_id = session['user_id']
    user = UserModel.get_by_id(user_id)

    if request.method == 'POST':
        action = request.form.get('action')

        if action == 'update_info':
            full_name = request.form.get('full_name', '').strip()
            email = request.form.get('email', '').strip().lower()
            country_name = request.form.get('country_name', 'India').strip()
            country_code = request.form.get('country_code', '+91').strip()
            phone = request.form.get('phone', '').strip()

            if not all([full_name, email, phone]):
                flash('All profile fields are required.', 'danger')
                return render_template('user/profile.html', user=user, countries=COUNTRY_LIST)

            # Authentic Email verification
            is_email_valid, email_err = validate_email_authenticity(email)
            if not is_email_valid:
                flash(email_err, 'danger')
                return render_template('user/profile.html', user=user, countries=COUNTRY_LIST)

            # Authentic Phone verification
            is_phone_valid, phone_err, formatted_phone = validate_phone_authenticity(phone, country_code)
            if not is_phone_valid:
                flash(phone_err, 'danger')
                return render_template('user/profile.html', user=user, countries=COUNTRY_LIST)
            phone = formatted_phone

            # Check if email is used by another user
            existing_email = UserModel.get_by_email(email)
            if existing_email and existing_email['id'] != user_id:
                flash('This email address is already in use by another account.', 'danger')
                return render_template('user/profile.html', user=user, countries=COUNTRY_LIST)

            UserModel.update_profile(user_id, full_name, email, phone, country=country_name or 'India')
            session['user_name'] = full_name
            session['user_email'] = email
            flash('Your profile details have been successfully updated!', 'success')
            return redirect(url_for('user.profile'))

        elif action == 'change_password':
            current_pass = request.form.get('current_password', '')
            new_pass = request.form.get('new_password', '')
            confirm_pass = request.form.get('confirm_password', '')

            # Re-fetch user to check password_hash
            raw_user = UserModel.get_by_identifier(user['username'])
            if not verify_password(current_pass, raw_user['password_hash']):
                flash('Current password entered is incorrect.', 'danger')
                return render_template('user/profile.html', user=user, countries=COUNTRY_LIST)

            if len(new_pass) < 6:
                flash('New password must be at least 6 characters long.', 'danger')
                return render_template('user/profile.html', user=user, countries=COUNTRY_LIST)

            if new_pass != confirm_pass:
                flash('New password and confirmation do not match.', 'danger')
                return render_template('user/profile.html', user=user, countries=COUNTRY_LIST)

            UserModel.update_password(user_id, new_pass)
            flash('Your password has been changed successfully.', 'success')
            return redirect(url_for('user.profile'))

    return render_template('user/profile.html', user=user, countries=COUNTRY_LIST)

@user_bp.route('/bookings')
@login_required
def bookings():
    user_id = session['user_id']
    tab = request.args.get('tab', 'upcoming')
    
    upcoming = BookingModel.get_user_bookings(user_id, filter_type='upcoming')
    completed = BookingModel.get_user_bookings(user_id, filter_type='completed')
    
    return render_template(
        'user/bookings.html',
        upcoming=upcoming,
        completed=completed,
        active_tab=tab
    )

@user_bp.route('/bookings/<int:booking_id>')
@login_required
def booking_details(booking_id):
    user_id = session['user_id']
    booking = BookingModel.get_by_id(booking_id)

    if not booking or (booking['user_id'] != user_id and session.get('role') != 'admin'):
        abort(404)

    travellers = BookingModel.get_travellers(booking_id)
    return render_template(
        'user/booking_details.html',
        booking=booking,
        travellers=travellers
    )

@user_bp.route('/bookings/<int:booking_id>/cancel', methods=['POST'])
@login_required
def cancel_booking(booking_id):
    user_id = session['user_id']
    booking = BookingModel.get_by_id(booking_id)

    if not booking or (booking['user_id'] != user_id and session.get('role') != 'admin'):
        abort(404)

    if booking['booking_status'] in ['Completed', 'Cancelled']:
        flash('This booking cannot be cancelled.', 'danger')
        return redirect(url_for('user.bookings'))

    BookingModel.update_booking_status(booking_id, 'Cancelled')
    flash('Tour cancelled. Refund initiated.', 'info')
    return redirect(url_for('user.bookings'))

@user_bp.route('/wishlist')
@login_required
def wishlist():
    user_id = session['user_id']
    tab = request.args.get('tab', 'packages')
    items = WishlistModel.get_by_user(user_id)
    destination_items = WishlistModel.get_destinations_by_user(user_id)
    return render_template(
        'user/wishlist.html',
        items=items,
        destination_items=destination_items,
        active_tab=tab,
        user=UserModel.get_by_id(user_id)
    )

@user_bp.route('/reviews', methods=['GET', 'POST'])
@login_required
def reviews():
    user_id = session['user_id']

    if request.method == 'POST':
        package_id = request.form.get('package_id', type=int)
        booking_id = request.form.get('booking_id', type=int)
        rating = request.form.get('rating', type=int, default=5)
        review_title = request.form.get('review_title', '').strip()
        review_tags = request.form.getlist('review_tags')
        review_text = request.form.get('review_text', '').strip()

        if not package_id:
            flash('Please choose a tour package to review.', 'danger')
            return redirect(url_for('user.reviews'))

        if not rating or rating < 1 or rating > 5:
            flash('Rating must be between 1 and 5 stars.', 'danger')
            return redirect(url_for('user.reviews'))

        if not review_text:
            flash('Please write your review feedback.', 'danger')
            return redirect(url_for('user.reviews'))

        # Combine title, experience tags, and review text
        content_parts = []
        if review_title:
            content_parts.append(f"★ {review_title}")
        if review_tags:
            content_parts.append("Highlights: " + " • ".join(review_tags))
        content_parts.append(review_text)

        full_review = "\n\n".join(content_parts)

        ReviewModel.create(user_id, package_id, booking_id if booking_id else None, rating, full_review, is_approved=True)
        flash('Thank you! Your review has been submitted and published successfully!', 'success')
        return redirect(url_for('user.reviews'))

    user_reviews = ReviewModel.get_user_reviews(user_id)
    user_bookings = BookingModel.get_user_bookings(user_id)
    all_packages = PackageModel.get_all()

    return render_template(
        'user/reviews.html',
        user_reviews=user_reviews,
        user_bookings=user_bookings,
        all_packages=all_packages
    )
