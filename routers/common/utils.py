from datetime import datetime, timezone


def utc_now():

    return datetime.now(timezone.utc)


def to_str(value):

    if value is None:

        return None

    return str(value)