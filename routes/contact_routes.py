"""
Contact, About, FAQ and Public Utility Routes
"""

from flask import Blueprint, render_template, request, flash, redirect, url_for, jsonify
from models.contact_model import ContactModel
from models.offer_model import OfferModel

contact_bp = Blueprint('contact', __name__)

@contact_bp.route('/about')
def about():
    return render_template('about/about.html')

@contact_bp.route('/contact', methods=['GET', 'POST'])
def contact():
    if request.method == 'POST':
        name = request.form.get('name', '').strip()
        email = request.form.get('email', '').strip()
        phone = request.form.get('phone', '').strip()
        subject = request.form.get('subject', '').strip()
        message = request.form.get('message', '').strip()

        if not all([name, email, subject, message]):
            flash('Please complete all required fields.', 'danger')
            return render_template('contact/contact.html', form_data=request.form)

        try:
            ContactModel.create(name, email, phone, subject, message)
            flash('Thank you for contacting Atlas Tourism! Our holiday specialist will respond shortly.', 'success')
            return redirect(url_for('contact.contact'))
        except Exception as e:
            flash('An error occurred sending your message. Please try again.', 'danger')
            return render_template('contact/contact.html', form_data=request.form)

    return render_template('contact/contact.html', form_data={})

@contact_bp.route('/faq')
def faq():
    return render_template('faq/faq.html')

@contact_bp.route('/api/validate-offer')
def validate_offer():
    code = request.args.get('code', '').strip()
    if not code:
        return jsonify({'valid': False, 'message': 'No code provided.'})

    offer = OfferModel.get_valid_offer(code)
    if offer:
        return jsonify({
            'valid': True,
            'offer_id': offer['id'],
            'discount_percent': offer['discount_percent'],
            'code': offer['code'],
            'description': offer['description']
        })
    else:
        return jsonify({'valid': False, 'message': 'Invalid, expired, or inactive coupon code.'})