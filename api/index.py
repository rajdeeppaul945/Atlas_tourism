import os
import sys
import traceback

# Ensure root project directory is in python path
current_dir = os.path.dirname(os.path.abspath(__file__))
root_dir = os.path.dirname(current_dir)
if root_dir not in sys.path:
    sys.path.insert(0, root_dir)

try:
    from app import app

    # WSGI Middleware to handle Vercel serverless path routing
    class VercelPathMiddleware:
        def __init__(self, wsgi_app):
            self.wsgi_app = wsgi_app

        def __call__(self, environ, start_response):
            path_info = environ.get('PATH_INFO', '')
            # If Vercel rewrote request to /api/index, strip the prefix
            if path_info.startswith('/api/index'):
                remainder = path_info[len('/api/index'):]
                environ['PATH_INFO'] = remainder if remainder else '/'
            elif path_info.startswith('/api'):
                remainder = path_info[len('/api'):]
                environ['PATH_INFO'] = remainder if remainder else '/'
            return self.wsgi_app(environ, start_response)

    app.wsgi_app = VercelPathMiddleware(app.wsgi_app)

except Exception as e:
    from flask import Flask, Response
    app = Flask(__name__)
    error_trace = traceback.format_exc()
    @app.route('/', defaults={'path': ''})
    @app.route('/<path:path>')
    def catch_all_startup_error(path):
        html = f"""
        <!DOCTYPE html>
        <html>
        <head><title>Vercel Startup Error</title></head>
        <body style="font-family: sans-serif; padding: 30px; background: #fff1f2; color: #991b1b;">
            <h2>⚠️ Atlas Tourism - Vercel Serverless Startup Exception</h2>
            <p>An exception occurred while loading the application:</p>
            <pre style="background: #ffffff; padding: 20px; border: 1px solid #fecaca; border-radius: 8px; overflow-x: auto; color: #111;">{error_trace}</pre>
        </body>
        </html>
        """
        return Response(html, mimetype="text/html", status=500)

if __name__ == '__main__':
    app.run()
