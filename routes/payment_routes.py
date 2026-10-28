"""
Payment Gateway Blueprint
Integrates Razorpay test/sandbox alongside an academic demonstration sandbox mode.
"""

from flask import Blueprint, render_template, request, redirect, url_for, flash, session, abort
from models.booking_model import BookingModel
from models.payment_model import PaymentModel
from utils.auth import login_required
from config import Config
import time
import random

payment_bp = Blueprint('payment', __name__, url_prefix='/payment')

@payment_bp.route('/checkout/<int:booking_id>')
@login_required
def checkout(booking_id):
    booking = BookingModel.get_by_id(booking_id)
    if not booking or booking['user_id'] != session['user_id']:
        abort(404)

    if booking['booking_status'] == 'Confirmed':
        flash('This booking is already paid and confirmed!', 'info')
        return redirect(url_for('booking.confirmation', booking_id=booking_id))

    amount_in_paise = int(float(booking['total_amount']) * 100)
    razorpay_order_id = None
    razorpay_enabled = False

    # Attempt Razorpay Order initialization if keys are present and not mock
    if Config.RAZORPAY_KEY_ID and not Config.RAZORPAY_KEY_ID.startswith('rzp_test_sample'):
        try:
            import razorpay
            client = razorpay.Client(auth=(Config.RAZORPAY_KEY_ID, Config.RAZORPAY_KEY_SECRET))
            order_data = {
                'amount': amount_in_paise,
                'currency': 'INR',
                'receipt': booking['booking_number'],
                'notes': {'booking_id': str(booking_id)}
            }
            order = client.order.create(data=order_data)
            razorpay_order_id = order['id']
            razorpay_enabled = True
        except Exception as e:
            print(f"[Razorpay Init Warning]: {e}. Falling back to clean academic demo mode.")
            razorpay_enabled = False

    return render_template(
        'booking/payment.html',
        booking=booking,
        amount_in_paise=amount_in_paise,
        razorpay_key=Config.RAZORPAY_KEY_ID,
        razorpay_order_id=razorpay_order_id,
        razorpay_enabled=razorpay_enabled,
        demo_mode=Config.DEMO_PAYMENT_MODE or not razorpay_enabled
    )

@payment_bp.route('/callback', methods=['POST'])
@login_required
def callback():
    booking_id = request.form.get('booking_id', type=int)
    razorpay_payment_id = request.form.get('razorpay_payment_id')
    razorpay_order_id = request.form.get('razorpay_order_id')
    razorpay_signature = request.form.get('razorpay_signature')

    booking = BookingModel.get_by_id(booking_id)
    if not booking or booking['user_id'] != session['user_id']:
        abort(404)

    # Record payment
    PaymentModel.create_payment(
        booking_id=booking_id,
        user_id=session['user_id'],
        razorpay_order_id=razorpay_order_id,
        razorpay_payment_id=razorpay_payment_id,
        razorpay_signature=razorpay_signature,
        amount=booking['total_amount'],
        currency='INR',
        payment_method='Razorpay Gateway',
        payment_status='Success'
    )

    # Update booking status
    BookingModel.update_status(booking_id, 'Confirmed')

    flash('Payment received successfully! Your tour is confirmed.', 'success')
    return redirect(url_for('booking.confirmation', booking_id=booking_id))

@payment_bp.route('/demo-process/<int:booking_id>', methods=['POST'])
@login_required
def demo_process(booking_id):
    """
    Instant test sandbox payment simulation for academic presentation
    and examiners without live API keys.
    """
    booking = BookingModel.get_by_id(booking_id)
    if not booking or booking['user_id'] != session['user_id']:
        abort(404)

    payment_method = request.form.get('demo_method', 'UPI (GooglePay / PhonePe / Paytm)')
    generated_pay_id = f"pay_demo_{int(time.time())}_{random.randint(1000, 9999)}"
    generated_order_id = f"order_demo_{int(time.time())}"

    # Record payment
    PaymentModel.create_payment(
        booking_id=booking_id,
        user_id=session['user_id'],
        razorpay_order_id=generated_order_id,
        razorpay_payment_id=generated_pay_id,
        razorpay_signature="sig_verified_demo_sandbox",
        amount=booking['total_amount'],
        currency='INR',
        payment_method=payment_method,
        payment_status='Success'
    )

    # Mark booking as Confirmed
    BookingModel.update_status(booking_id, 'Confirmed')

    flash('Payment received successfully! Your booking is confirmed.', 'success')
    return redirect(url_for('booking.confirmation', booking_id=booking_id))
