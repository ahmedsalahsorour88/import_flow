from datetime import datetime


def utc_now():

    return datetime.utcnow()


def to_str(value):

    if value is None:

        return None

    return str(value)