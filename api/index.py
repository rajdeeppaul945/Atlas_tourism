import os
import sys

# Ensure root project directory is in python path
current_dir = os.path.dirname(os.path.abspath(__file__))
root_dir = os.path.dirname(current_dir)
if root_dir not in sys.path:
    sys.path.insert(0, root_dir)

from app import app

# Vercel Serverless WSGI Application entrypoint
if __name__ == '__main__':
    app.run()
