# Definition of all the constants
import codecs
import base64

def urlsafe_base64decode(value):
    """
    urlsafe_b64decode without padding
    """
    # Python requires padding even for base64 URL encoded
    # strings. Compute the required padding and append.
    pad = '=' * (4 - (len(value) % 3))
    return base64.urlsafe_b64decode(value + pad)

def urlsafe_base64decode_as_str(value):
    """
    urlsafe_b64decode without padding. Returns result as UTF-8 encoded string.
    """
    return urlsafe_base64decode(value).decode("utf-8")

def urlsafe_b64encode_as_str(value):
    """
    base64 url safe encoding which returns result as UTF-8 encoded string
    """
    return base64.urlsafe_b64encode(value).decode("utf-8")

def _int_to_bytes(i):
    """
    Converts the given int to the big-endian bytes
    """
    h = hex(i)
    if len(h) > 1 and h[0:2] == "0x":
        h = h[2:]

    # need to strip L in python 2.x
    h = h.strip("L")

    if len(h) % 2:
        h = "0" + h
    return codecs.decode(h, "hex")
