"""
Booking Blueprint
Orchestrates package selection, traveller registration, price calculation,
and transition to checkout.
"""

from flask import Blueprint, render_template, request, redirect, url_for, flash, session, abort
from models.package_model import PackageModel
from models.booking_model import BookingModel
from models.offer_model import OfferModel
from models.user_model import UserModel
from utils.auth import login_required
from utils.helpers import generate_booking_number
from datetime import datetime

booking_bp = Blueprint('booking', __name__, url_prefix='/booking')

@booking_bp.route('/book/<int:package_id>', methods=['GET', 'POST'])
@login_required
def book(package_id):
    package = PackageModel.get_by_id(package_id)
    if not package:
        abort(404)

    user_id = session['user_id']
    user = UserModel.get_by_id(user_id)

    if request.method == 'POST':
        travel_date = request.form.get('travel_date')
        adults_count = int(request.form.get('adults_count', 1))
        children_count = int(request.form.get('children_count', 0))
        contact_name = request.form.get('contact_name', '').strip()
        contact_email = request.form.get('contact_email', '').strip()
        contact_phone = request.form.get('contact_phone', '').strip()
        special_requests = request.form.get('special_requests', '').strip()
        offer_id = request.form.get('offer_id') or None
        
        # Validation
        if not travel_date or not contact_name or not contact_email or not contact_phone:
            flash('Please complete all required booking fields.', 'danger')
            return render_template('booking/book.html', package=package, user=user)

        # Ensure travel date is in the future
        try:
            parsed_date = datetime.strptime(travel_date, '%Y-%m-%d').date()
            if parsed_date <= datetime.now().date():
                flash('Please select a future travel date.', 'warning')
                return render_template('booking/book.html', package=package, user=user)
        except ValueError:
            flash('Invalid travel date format.', 'danger')
            return render_template('booking/book.html', package=package, user=user)

        # Calculate financial amounts accurately
        base_rate = float(package['price'])
        base_amount = (base_rate * adults_count) + (base_rate * 0.6 * children_count)
        
        discount_amount = 0.0
        if offer_id:
            offer = OfferModel.get_by_id(offer_id)
            if offer and offer['is_active']:
                discount_amount = (base_amount * offer['discount_percent']) / 100.0

        total_amount = max(0.0, base_amount - discount_amount)
        booking_number = generate_booking_number()

        # Insert booking record
        booking_id = BookingModel.create_booking(
            booking_number=booking_number,
            user_id=user_id,
            package_id=package_id,
            travel_date=travel_date,
            adults_count=adults_count,
            children_count=children_count,
            base_amount=base_amount,
            discount_amount=discount_amount,
            total_amount=total_amount,
            offer_id=offer_id,
            contact_name=contact_name,
            contact_email=contact_email,
            contact_phone=contact_phone,
            special_requests=special_requests
        )

        # Insert traveller passenger roster
        traveller_names = request.form.getlist('traveller_name[]')
        traveller_ages = request.form.getlist('traveller_age[]')
        traveller_genders = request.form.getlist('traveller_gender[]')

        for i in range(len(traveller_names)):
            name = traveller_names[i].strip()
            age = int(traveller_ages[i]) if i < len(traveller_ages) and traveller_ages[i] else 25
            gender = traveller_genders[i] if i < len(traveller_genders) else 'Male'
            if name:
                BookingModel.add_traveller(booking_id, name, age, gender)

        # Redirect to payment portal
        return redirect(url_for('payment.checkout', booking_id=booking_id))

    return render_template('booking/book.html', package=package, user=user)

@booking_bp.route('/confirmation/<int:booking_id>')
@login_required
def confirmation(booking_id):
    booking = BookingModel.get_by_id(booking_id)
    if not booking:
        abort(404)

    # Authorization guard: allow owner or admin
    if booking['user_id'] != session['user_id'] and session.get('role') != 'admin':
        abort(403)

    travellers = BookingModel.get_travellers(booking_id)
    return render_template('booking/confirmation.html', booking=booking, travellers=travellers)
