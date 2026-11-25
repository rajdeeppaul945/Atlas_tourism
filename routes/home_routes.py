"""
Home Blueprint
Handles landing page, search query redirect, sitemap, robots.txt, and marketing sections.
"""

from flask import Blueprint, render_template, request, redirect, url_for, session, Response
from datetime import datetime
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

@home_bp.route('/robots.txt')
def robots_txt():
    """Provides directives for Googlebot and other web crawlers."""
    content = """User-agent: *
Allow: /
Allow: /destinations/
Allow: /packages/
Allow: /about
Allow: /contact
Disallow: /admin/
Disallow: /user/
Disallow: /booking/

Sitemap: https://atlas-tourism-five.vercel.app/sitemap.xml
"""
    return Response(content, mimetype='text/plain')

@home_bp.route('/sitemap.xml')
def sitemap_xml():
    """Generates an XML sitemap for Google Search indexing."""
    base_url = "https://atlas-tourism-five.vercel.app"
    today = datetime.now().strftime("%Y-%m-%d")

    urls = [
        {"loc": f"{base_url}/", "priority": "1.0", "freq": "daily"},
        {"loc": f"{base_url}/destinations/", "priority": "0.9", "freq": "weekly"},
        {"loc": f"{base_url}/packages/", "priority": "0.9", "freq": "daily"},
        {"loc": f"{base_url}/about", "priority": "0.7", "freq": "monthly"},
        {"loc": f"{base_url}/contact", "priority": "0.7", "freq": "monthly"},
    ]

    try:
        destinations = DestinationModel.get_all()
        if destinations:
            for d in destinations:
                urls.append({"loc": f"{base_url}/destinations/{d['id']}", "priority": "0.8", "freq": "weekly"})
    except Exception:
        pass

    try:
        packages = PackageModel.get_all()
        if packages:
            for p in packages:
                urls.append({"loc": f"{base_url}/packages/{p['id']}", "priority": "0.8", "freq": "weekly"})
    except Exception:
        pass

    xml_lines = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
    ]
    for u in urls:
        xml_lines.append(f"  <url>")
        xml_lines.append(f"    <loc>{u['loc']}</loc>")
        xml_lines.append(f"    <lastmod>{today}</lastmod>")
        xml_lines.append(f"    <changefreq>{u['freq']}</changefreq>")
        xml_lines.append(f"    <priority>{u['priority']}</priority>")
        xml_lines.append(f"  </url>")
    xml_lines.append('</urlset>')

    return Response("\n".join(xml_lines), mimetype='application/xml')
