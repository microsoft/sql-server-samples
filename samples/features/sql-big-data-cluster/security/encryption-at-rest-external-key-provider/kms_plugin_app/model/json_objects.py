# Contains the JSON objects for the application.
#
import sys
import os
sys.path.append(os.path.join(os.path.dirname(os.path.realpath(__file__)), os.pardir))
import utils
from constants import CryptoConstants

class EncryptDecryptRequest(object):
    """
    Represents the encryption and decryption request
    """
    def __init__(self, value, alg):
        self.value = utils.urlsafe_base64decode(value)
        self.alg = alg

class EncryptDecryptResponse(object):
    """ 
    Represents the encryption and decryption response
    """
    def __init__(self, value):
        self.value = utils.urlsafe_b64encode_as_str(value)

class JsonWebKeyResponse(object):
    """
    Represents the getKey operation response
    """
    def __init__(self, modulus, exponent):
        self.n = utils.urlsafe_b64encode_as_str(utils._int_to_bytes(modulus))
        self.e = utils.urlsafe_b64encode_as_str(utils._int_to_bytes(exponent))
        self.kty = CryptoConstants.KTY_RSA
