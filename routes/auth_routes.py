"""
Authentication Blueprint
Handles user registration, login, logout, and password recovery.
"""

from flask import Blueprint, render_template, request, redirect, url_for, flash, session
from models.user_model import UserModel
from utils.validators import validate_email_authenticity, validate_phone_authenticity, COUNTRY_LIST
from utils.email_service import send_password_reset_email
import re

auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/register', methods=['GET', 'POST'])
def register():
    if 'user_id' in session:
        return redirect(url_for('user.dashboard'))

    if request.method == 'POST':
        full_name = request.form.get('full_name', '').strip()
        username = request.form.get('username', '').strip()
        email = request.form.get('email', '').strip().lower()
        country_code = request.form.get('country_code', '+91').strip()
        country_name = request.form.get('country_name', '').strip()
        phone = request.form.get('phone', '').strip()
        password = request.form.get('password', '')
        confirm_password = request.form.get('confirm_password', '')

        # Basic validations
        if not all([full_name, username, email, phone, password, confirm_password]):
            flash('All fields are required.', 'danger')
            return render_template('auth/register.html', form_data=request.form, countries=COUNTRY_LIST)

        # Authentic Email verification (valid format, no disposable/fake domains, live MX lookup)
        is_email_valid, email_err = validate_email_authenticity(email)
        if not is_email_valid:
            flash(email_err, 'danger')
            return render_template('auth/register.html', form_data=request.form, countries=COUNTRY_LIST)

        # Authentic Phone verification (real format for country, no repeated fake digits)
        is_phone_valid, phone_err, formatted_phone = validate_phone_authenticity(phone, country_code)
        if not is_phone_valid:
            flash(phone_err, 'danger')
            return render_template('auth/register.html', form_data=request.form, countries=COUNTRY_LIST)
        phone = formatted_phone

        # Password matching check
        if password != confirm_password:
            flash('Passwords do not match. Please re-enter.', 'danger')
            return render_template('auth/register.html', form_data=request.form, countries=COUNTRY_LIST)

        if len(password) < 6:
            flash('Password must be at least 6 characters long.', 'danger')
            return render_template('auth/register.html', form_data=request.form, countries=COUNTRY_LIST)

        # Check for duplicates
        if UserModel.get_by_email(email):
            flash('An account with this email already exists. Please login.', 'warning')
            return render_template('auth/register.html', form_data=request.form, countries=COUNTRY_LIST)

        if UserModel.get_by_username(username):
            flash('This username is already taken. Please choose another.', 'warning')
            return render_template('auth/register.html', form_data=request.form, countries=COUNTRY_LIST)

        # Create user
        try:
            UserModel.create_user(full_name, username, email, phone, password, role='user', country=country_name or 'India')
            flash('Registration successful! You can now log in to your account.', 'success')
            return redirect(url_for('auth.login'))
        except Exception as e:
            flash(f'An error occurred during registration: {str(e)}', 'danger')
            return render_template('auth/register.html', form_data=request.form, countries=COUNTRY_LIST)

    return render_template('auth/register.html', form_data={}, countries=COUNTRY_LIST)

@auth_bp.route('/login', methods=['GET', 'POST'])
def login():
    if 'user_id' in session:
        return redirect(url_for('user.dashboard'))

    if request.method == 'POST':
        identifier = request.form.get('identifier', '').strip()
        password = request.form.get('password', '')
        remember_me = request.form.get('remember_me')

        if not identifier or not password:
            flash('Please enter both email/username and password.', 'danger')
            return render_template('auth/login.html', identifier=identifier)

        user, error_msg = UserModel.authenticate(identifier, password)
        if error_msg:
            flash(error_msg, 'danger')
            return render_template('auth/login.html', identifier=identifier)

        # Establish session
        session['user_id'] = user['id']
        session['user_name'] = user['full_name']
        session['user_email'] = user['email']
        session['role'] = user['role']
        if remember_me:
            session.permanent = True

        flash(f"Welcome back, {user['full_name']}!", 'success')

        next_url = request.args.get('next')
        if next_url and next_url.startswith('/'):
            return redirect(next_url)

        if user['role'] == 'admin':
            return redirect(url_for('admin.dashboard'))
        return redirect(url_for('user.dashboard'))

    return render_template('auth/login.html')

@auth_bp.route('/logout')
def logout():
    session.clear()
    flash('You have been safely logged out. See you again soon!', 'info')
    return redirect(url_for('home.index'))

@auth_bp.route('/forgot-password', methods=['GET', 'POST'])
def forgot_password():
    if request.method == 'POST':
        email = request.form.get('email', '').strip().lower()
        user = UserModel.get_by_email(email)
        if user:
            reset_link = url_for('auth.reset_password_sim', user_id=user['id'], _external=True)
            send_password_reset_email(email, reset_link)
            flash('Password reset instructions have been dispatched to your email address.', 'success')
            return redirect(url_for('auth.login'))
        else:
            flash('If an account exists with that email address, reset instructions have been sent.', 'info')
            return redirect(url_for('auth.login'))

    return render_template('auth/forgot_password.html')

@auth_bp.route('/reset-password/<int:user_id>', methods=['GET', 'POST'])
def reset_password_sim(user_id):
    user = UserModel.get_by_id(user_id)
    if not user:
        flash('Invalid password reset token.', 'danger')
        return redirect(url_for('auth.login'))

    if request.method == 'POST':
        new_pass = request.form.get('new_password', '')
        confirm_pass = request.form.get('confirm_password', '')
        if new_pass != confirm_pass:
            flash('Passwords do not match.', 'danger')
            return render_template('auth/reset_password.html', user=user)
        if len(new_pass) < 6:
            flash('Password must be at least 6 characters.', 'danger')
            return render_template('auth/reset_password.html', user=user)

        UserModel.update_password(user_id, new_pass)
        flash('Your password has been successfully reset! You can now log in.', 'success')
        return redirect(url_for('auth.login'))

    return render_template('auth/reset_password.html', user=user)
