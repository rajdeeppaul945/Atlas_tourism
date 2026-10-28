"""
Destinations Blueprint
Handles destination browsing, searching, and detailed overview with wishlist support.
"""

from flask import Blueprint, render_template, request, session, abort
from models.destination_model import DestinationModel
from models.package_model import PackageModel
from models.wishlist_model import WishlistModel

destination_bp = Blueprint('destinations', __name__, url_prefix='/destinations')

@destination_bp.route('/')
def index():
    search_query = request.args.get('search', '').strip()
    if search_query:
        destinations = DestinationModel.search(search_query)
    else:
        destinations = DestinationModel.get_all()

    user_dest_wishlist = set()
    if 'user_id' in session:
        user_dest_wishlist = WishlistModel.get_user_destination_ids(session['user_id'])

    return render_template(
        'destinations/index.html',
        destinations=destinations,
        search_query=search_query,
        user_dest_wishlist=user_dest_wishlist
    )

@destination_bp.route('/<int:destination_id>')
def details(destination_id):
    destination = DestinationModel.get_by_id(destination_id)
    if not destination:
        abort(404)

    # Fetch packages available for this destination
    packages = PackageModel.get_by_destination(destination_id)

    in_wishlist = False
    if 'user_id' in session:
        in_wishlist = WishlistModel.is_destination_in_wishlist(session['user_id'], destination_id)

    return render_template(
        'destinations/details.html',
        destination=destination,
        packages=packages,
        in_wishlist=in_wishlist
    )
