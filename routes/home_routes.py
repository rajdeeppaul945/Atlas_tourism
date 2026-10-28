"""
Home Blueprint
Handles landing page, search query redirect, and high-level marketing sections.
"""

from flask import Blueprint, render_template, request, redirect, url_for, session
from models.destination_model import DestinationModel
from models.package_model import PackageModel
from models.review_model import ReviewModel
from models.wishlist_model import WishlistModel

home_bp = Blueprint('home', __name__)

@home_bp.route('/')
def index():
    # Retrieve destinations
    destinations = DestinationModel.get_all()
    
    # Retrieve featured tour packages
    packages = PackageModel.get_featured(limit=6)
    
    # Retrieve real approved customer testimonials
    reviews = ReviewModel.get_featured_reviews(limit=3)

    user_dest_wishlist = set()
    user_pkg_wishlist = set()
    if 'user_id' in session:
        user_dest_wishlist = WishlistModel.get_user_destination_ids(session['user_id'])
        user_pkg_wishlist = WishlistModel.get_user_package_ids(session['user_id'])
    
    return render_template(
        'home/index.html',
        destinations=destinations,
        packages=packages,
        reviews=reviews,
        user_dest_wishlist=user_dest_wishlist,
        user_pkg_wishlist=user_pkg_wishlist
    )

@home_bp.route('/search')
def search():
    query = request.args.get('q', '').strip()
    if not query:
        return redirect(url_for('packages.index'))
    return redirect(url_for('packages.index', q=query))
