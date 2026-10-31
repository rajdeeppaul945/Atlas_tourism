"""
Atlas Tourism - Core Flask Application Entrypoint
Full-stack tourism and travel booking web platform.
"""

import os
from datetime import datetime
from flask import Flask, render_template, session
from config import Config

def create_app():
    root_path = os.path.abspath(os.path.dirname(__file__))
    app = Flask(
        __name__,
        template_folder=os.path.join(root_path, 'templates'),
        static_folder=os.path.join(root_path, 'static')
    )
    app.config.from_object(Config)

    # Ensure upload directory exists safely
    try:
        os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
    except Exception as err:
        print(f"[Upload Folder Warning]: {err}")

    # Register Custom Jinja2 Template Filters
    from utils.helpers import format_currency, format_date
    app.jinja_env.filters['currency'] = format_currency
    app.jinja_env.filters['date_format'] = format_date

    # Context Processor for Universal Global Variables
    @app.context_processor
    def inject_globals():
        wishlist_count = 0
        if 'user_id' in session:
            try:
                from models.wishlist_model import WishlistModel
                wishlist_count = WishlistModel.count(session['user_id'])
            except Exception:
                wishlist_count = 0

        return {
            'now_year': datetime.now().year,
            'wishlist_count': wishlist_count
        }

    # Register Blueprint Modules
    from routes.auth_routes import auth_bp
    from routes.home_routes import home_bp
    from routes.destination_routes import destination_bp
    from routes.package_routes import package_bp
    from routes.booking_routes import booking_bp
    from routes.payment_routes import payment_bp
    from routes.wishlist_routes import wishlist_bp
    from routes.user_routes import user_bp
    from routes.contact_routes import contact_bp
    from routes.admin_routes import admin_bp

    app.register_blueprint(auth_bp)
    app.register_blueprint(home_bp)
    app.register_blueprint(destination_bp)
    app.register_blueprint(package_bp)
    app.register_blueprint(booking_bp)
    app.register_blueprint(payment_bp)
    app.register_blueprint(wishlist_bp)
    app.register_blueprint(user_bp)
    app.register_blueprint(contact_bp)
    app.register_blueprint(admin_bp)

    # Global HTTP Error Handlers
    @app.errorhandler(404)
    def page_not_found(e):
        from flask import request, make_response
        debug_info = f"Requested URL: {request.url} | Path: {request.path} | PATH_INFO: {request.environ.get('PATH_INFO')} | SCRIPT_NAME: {request.environ.get('SCRIPT_NAME')}"
        resp = make_response(render_template('errors/404.html'), 404)
        resp.headers['X-Debug-Info'] = debug_info
        return resp

    @app.errorhandler(500)
    def internal_server_error(e):
        return render_template('errors/500.html'), 500

    @app.errorhandler(403)
    def forbidden_error(e):
        return render_template('errors/404.html'), 403

    return app

app = create_app()

if __name__ == '__main__':
    # Local Development Runner
    print("=" * 60)
    print("  ATLAS TOURISM APPLICATION STARTING")
    print("  Running locally on: http://127.0.0.1:5000")
    print("=" * 60)
    app.run(host='127.0.0.1', port=5000, debug=True)
