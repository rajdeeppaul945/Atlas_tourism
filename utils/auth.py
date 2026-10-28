"""
Authentication & Authorization Utilities
Handles password hashing, session checking, and route-protecting decorators.
"""

from functools import wraps
from flask import session, redirect, url_for, flash, request, abort
from werkzeug.security import generate_password_hash, check_password_hash
from utils.database import execute_query

def hash_password(password: str) -> str:
    """Generates a secure hash for the given password."""
    return generate_password_hash(password)

def verify_password(password: str, hashed_password: str) -> bool:
    """Verifies a plain password against its hash."""
    return check_password_hash(hashed_password, password)

def login_required(f):
    """Decorator to enforce that the user must be logged in."""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            flash('Please log in to access this page.', 'warning')
            return redirect(url_for('auth.login', next=request.path))
        return f(*args, **kwargs)
    return decorated_function

def admin_required(f):
    """Decorator to enforce that the current user must have the 'admin' role."""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            flash('Admin authentication required.', 'warning')
            return redirect(url_for('auth.login', next=request.path))
        
        if session.get('role') != 'admin':
            flash('Access denied. Administrator privileges required.', 'danger')
            return redirect(url_for('user.dashboard'))
            
        return f(*args, **kwargs)
    return decorated_function

def get_current_user():
    """Retrieves full user record for currently authenticated session."""
    user_id = session.get('user_id')
    if not user_id:
        return None
    sql = "SELECT id, full_name, username, email, phone, role, is_active, created_at FROM users WHERE id = %s"
    return execute_query(sql, (user_id,), fetchone=True)
