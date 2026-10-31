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
