"""
Wishlist Blueprint
Handles saving, removing, and toggling packages and destinations in user's wishlist.
"""

from flask import Blueprint, request, jsonify, session, redirect, url_for, flash
from models.wishlist_model import WishlistModel
from utils.auth import login_required

wishlist_bp = Blueprint('wishlist', __name__, url_prefix='/wishlist')

# --- Package Wishlist Routes ---
@wishlist_bp.route('/toggle/<int:package_id>', methods=['POST'])
def toggle(package_id):
    if 'user_id' not in session:
        return jsonify({'status': 'unauthorized', 'message': 'Please login to use wishlist'}), 401

    user_id = session['user_id']
    is_added = WishlistModel.toggle(user_id, package_id)
    total_count = WishlistModel.count(user_id)

    return jsonify({
        'status': 'added' if is_added else 'removed',
        'total_count': total_count
    })

@wishlist_bp.route('/remove/<int:package_id>', methods=['POST', 'GET'])
@login_required
def remove(package_id):
    user_id = session['user_id']
    WishlistModel.remove(user_id, package_id)
    flash('Package removed from your wishlist.', 'info')
    return redirect(url_for('user.wishlist', tab='packages'))

# --- Destination Wishlist Routes ---
@wishlist_bp.route('/toggle-destination/<int:destination_id>', methods=['POST'])
def toggle_destination(destination_id):
    if 'user_id' not in session:
        return jsonify({'status': 'unauthorized', 'message': 'Please login to use wishlist'}), 401

    user_id = session['user_id']
    is_added = WishlistModel.toggle_destination(user_id, destination_id)
    total_count = WishlistModel.count(user_id)

    return jsonify({
        'status': 'added' if is_added else 'removed',
        'total_count': total_count
    })

@wishlist_bp.route('/remove-destination/<int:destination_id>', methods=['POST', 'GET'])
@login_required
def remove_destination(destination_id):
    user_id = session['user_id']
    WishlistModel.remove_destination(user_id, destination_id)
    flash('Destination removed from your wishlist.', 'info')
    return redirect(url_for('user.wishlist', tab='destinations'))
