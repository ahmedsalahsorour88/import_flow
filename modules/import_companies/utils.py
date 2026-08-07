from datetime import date


def calculate_days_to_renew(expiry_date: date) -> int:
    """
    Calculate remaining days until expiry.
    Negative value means expired.
    """

    return (expiry_date - date.today()).days