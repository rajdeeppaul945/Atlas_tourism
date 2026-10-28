"""
Validation Utilities for Email and Phone Authenticity.
Enforces real MX/DNS domain verification, disposable domain blacklisting,
and authentic international phone number parsing via Google's phonenumbers library.
"""

import re
import dns.resolver
import phonenumbers

# Master list of countries and international dial codes
COUNTRY_LIST = [
    {"name": "India", "code": "+91", "iso": "IN"},
    {"name": "United States", "code": "+1", "iso": "US"},
    {"name": "United Kingdom", "code": "+44", "iso": "GB"},
    {"name": "Canada", "code": "+1", "iso": "CA"},
    {"name": "United Arab Emirates", "code": "+971", "iso": "AE"},
    {"name": "Australia", "code": "+61", "iso": "AU"},
    {"name": "Singapore", "code": "+65", "iso": "SG"},
    {"name": "Nepal", "code": "+977", "iso": "NP"},
    {"name": "Bangladesh", "code": "+880", "iso": "BD"},
    {"name": "Bhutan", "code": "+975", "iso": "BT"},
    {"name": "Sri Lanka", "code": "+94", "iso": "LK"},
    {"name": "Maldives", "code": "+960", "iso": "MV"},
    {"name": "Malaysia", "code": "+60", "iso": "MY"},
    {"name": "Thailand", "code": "+66", "iso": "TH"},
    {"name": "Saudi Arabia", "code": "+966", "iso": "SA"},
    {"name": "Qatar", "code": "+974", "iso": "QA"},
    {"name": "Kuwait", "code": "+965", "iso": "KW"},
    {"name": "Oman", "code": "+968", "iso": "OM"},
    {"name": "Germany", "code": "+49", "iso": "DE"},
    {"name": "France", "code": "+33", "iso": "FR"},
    {"name": "Italy", "code": "+39", "iso": "IT"},
    {"name": "Spain", "code": "+34", "iso": "ES"},
    {"name": "Netherlands", "code": "+31", "iso": "NL"},
    {"name": "Switzerland", "code": "+41", "iso": "CH"},
    {"name": "New Zealand", "code": "+64", "iso": "NZ"},
    {"name": "South Africa", "code": "+27", "iso": "ZA"},
    {"name": "Japan", "code": "+81", "iso": "JP"},
    {"name": "China", "code": "+86", "iso": "CN"},
    {"name": "Russia", "code": "+7", "iso": "RU"},
    {"name": "Brazil", "code": "+55", "iso": "BR"},
    {"name": "Mexico", "code": "+52", "iso": "MX"},
    {"name": "Indonesia", "code": "+62", "iso": "ID"},
    {"name": "Philippines", "code": "+63", "iso": "PH"},
    {"name": "Vietnam", "code": "+84", "iso": "VN"},
    {"name": "Turkey", "code": "+90", "iso": "TR"},
    {"name": "Egypt", "code": "+20", "iso": "EG"}
]

# Blacklisted fake, test, and disposable mail domains
DISPOSABLE_AND_TEST_DOMAINS = {
    'xyz.com', 'test.com', 'example.com', 'sample.com', 'fake.com',
    'tempmail.com', '10minutemail.com', 'guerrillamail.com', 'mailinator.com',
    'yopmail.com', 'throwaway.com', 'temp-mail.org', 'trashmail.com',
    'dispostable.com', 'getairmail.com', 'sharklasers.com', 'fakemailgenerator.com',
    'generator.email', 'tempmailaddress.com', 'burnermail.io'
}

def validate_email_authenticity(email: str):
    """
    Validates email format, prevents disposable/fake domains,
    and performs live DNS MX record lookup.
    """
    if not email or '@' not in email:
        return False, "Please enter a valid email address."

    email = email.strip().lower()
    local, domain = email.rsplit('@', 1)

    if not local or not domain or '.' not in domain:
        return False, "Invalid email address format."

    # General regex check
    regex = r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$'
    if not re.match(regex, email):
        return False, "Please enter a properly formatted email address."

    # Check against known test and disposable domains
    if domain in DISPOSABLE_AND_TEST_DOMAINS or domain.endswith('.invalid') or domain.endswith('.test'):
        return False, f"Email domain '@{domain}' is a test or disposable service. Please provide an authentic, active email address."

    # Live DNS MX check to verify if the domain can receive emails
    try:
        mx_records = dns.resolver.resolve(domain, 'MX', lifetime=4.0)
        if not mx_records:
            return False, f"The domain '@{domain}' does not have mail exchange (MX) records."
    except (dns.resolver.NoAnswer, dns.resolver.NXDOMAIN):
        return False, f"The email domain '@{domain}' does not exist or cannot receive emails."
    except Exception:
        # Fallback to A record check in case of slow or blocked MX queries
        try:
            dns.resolver.resolve(domain, 'A', lifetime=3.0)
        except Exception:
            return False, f"Could not verify domain '@{domain}'. Please verify your email spelling."

    return True, ""


def validate_phone_authenticity(phone_number: str, country_code: str = "+91"):
    """
    Validates that a phone number is an authentic, valid carrier/mobile number
    for the specified country code. Rejects repetitive digits or placeholder patterns.
    """
    if not phone_number:
        return False, "Phone number is required.", ""

    clean_phone = phone_number.strip()
    
    # Check if number already includes a '+' dial code
    if clean_phone.startswith('+'):
        full_number = clean_phone
    else:
        # Normalize country code
        cc = country_code.strip() if country_code else "+91"
        if not cc.startswith('+'):
            cc = '+' + cc
        # Remove any leading zeros from the local part
        local_part = clean_phone.lstrip('0')
        full_number = f"{cc}{local_part}"

    try:
        parsed = phonenumbers.parse(full_number, None)
        if not phonenumbers.is_valid_number(parsed):
            return False, f"The phone number '{phone_number}' is not valid for country code '{country_code}'.", ""

        # Check for repetitive fake numbers (e.g. 0000000000, 1111111111)
        digits = ''.join(c for c in str(parsed.national_number))
        if len(set(digits)) == 1:
            return False, "Please enter an authentic phone number, not repeated digits.", ""

        # Check for sequential placeholder numbers
        if digits in ['1234567890', '0123456789', '9876543210', '0987654321']:
            return False, "Please enter your real phone number, not a placeholder sequence.", ""

        formatted = phonenumbers.format_number(parsed, phonenumbers.PhoneNumberFormat.INTERNATIONAL)
        return True, "", formatted
    except Exception as e:
        return False, f"Invalid phone number format: {str(e)}", ""
