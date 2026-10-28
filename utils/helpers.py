"""
Helper functions for formatting, calculations, and unique ID generation.
"""

import random
import time
from datetime import datetime

def format_currency(amount) -> str:
    """Formats a numeric value into Indian Rupee style currency (e.g. ₹ 25,000.00)."""
    try:
        val = float(amount or 0)
        # Format as 2 decimal places with standard commas
        return f"₹{val:,.2f}"
    except (ValueError, TypeError):
        return "₹0.00"

def generate_booking_number() -> str:
    """Generates a unique booking reference code like ATL-2026-8392."""
    year = datetime.now().year
    random_digits = random.randint(1000, 9999)
    return f"ATL-{year}-{random_digits}"

def format_date(value, fmt="%d %b %Y") -> str:
    """Formats datetime or date object/string for display."""
    if not value:
        return ""
    if isinstance(value, str):
        try:
            value = datetime.strptime(value, "%Y-%m-%d")
        except ValueError:
            try:
                value = datetime.strptime(value, "%Y-%m-%d %H:%M:%S")
            except ValueError:
                return value
    return value.strftime(fmt)
