"""
Packages Blueprint
Handles tour package listing with multi-facet filters and package detail inspection.
"""

from flask import Blueprint, render_template, request, abort, session
from models.package_model import PackageModel
from models.destination_model import DestinationModel
from models.review_model import ReviewModel
from models.wishlist_model import WishlistModel

package_bp = Blueprint('packages', __name__, url_prefix='/packages')

@package_bp.route('/')
def index():
    destination_id = request.args.get('destination_id', type=int)
    duration_filter = request.args.get('duration', '').strip()
    min_price = request.args.get('min_price', '').strip()
    max_price = request.args.get('max_price', '').strip()
    search_query = request.args.get('q', '').strip()

    packages = PackageModel.get_all(
        destination_id=destination_id,
        min_price=min_price,
        max_price=max_price,
        duration_filter=duration_filter,
        search=search_query
    )

    destinations = DestinationModel.get_all()

    return render_template(
        'packages/index.html',
        packages=packages,
        destinations=destinations,
        selected_destination=destination_id,
        selected_duration=duration_filter,
        min_price=min_price,
        max_price=max_price,
        search_query=search_query
    )

@package_bp.route('/<int:package_id>')
def details(package_id):
    package = PackageModel.get_by_id(package_id)
    if not package:
        abort(404)

    # Fetch day-wise itinerary
    itinerary = PackageModel.get_itinerary(package_id)

    # Fetch approved package reviews
    reviews = ReviewModel.get_approved_for_package(package_id)

    # Check if current logged-in user has this in wishlist
    in_wishlist = False
    if 'user_id' in session:
        in_wishlist = WishlistModel.is_in_wishlist(session['user_id'], package_id)

    return render_template(
        'packages/details.html',
        package=package,
        itinerary=itinerary,
        reviews=reviews,
        in_wishlist=in_wishlist
    )
