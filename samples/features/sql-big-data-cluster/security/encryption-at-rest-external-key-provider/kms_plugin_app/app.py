# This is a script for running the HSM interaction service using PKCS11
import json
import sys
# Append the current application path to sys path to be able to resolve local modules.
#
sys.path.append('.')
sys.path.append('./model')
from constants import ConfigurationConstants, Operations
import utils
from json_objects import EncryptDecryptRequest
import custom_softhsm as custom

def handler(operation, payload, pin, key_attributes, version):
    """
    Entry point for the application.
    """
    if (payload != None and len(payload) > 0):
        # The payload is base64 URL encoded and needs to be decoded first
        #
        json_request_payload = utils.urlsafe_base64decode_as_str(payload)

    json_key_attributes_dict = json.loads(utils.urlsafe_base64decode_as_str(key_attributes))

    if operation == Operations.OPERATION_ENCRYPT:
        encrypt_decrypt_dict = json.loads(json_request_payload)
        request = EncryptDecryptRequest(**encrypt_decrypt_dict)
        response = wrap_key(request, json_key_attributes_dict, pin, version)
    elif operation == Operations.OPERATION_DECRYPT:
        encrypt_decrypt_dict = json.loads(json_request_payload)
        request = EncryptDecryptRequest(**encrypt_decrypt_dict)
        response = unwrap_key(request, json_key_attributes_dict, pin, version)
    elif operation == Operations.OPERATION_GET_KEY:
        response = get_key(json_key_attributes_dict, pin, version)
    else:
        # Throw exception on unsupported operation.
        #
        raise Exception('Unsupported operation ' + operation)

    # The response should be a base64 url encoded JSON expected by the control plane.
    #
    serialized_json_response = json.dumps(response.__dict__).encode("utf-8")
    return utils.urlsafe_b64encode_as_str(serialized_json_response)

def get_key(json_key_attributes_dict, pin, version):
    """
    Call in to the custom key store module to get the key.
    """
    return custom.get_key(json_key_attributes_dict, pin, version)

def wrap_key(request, json_key_attributes_dict, pin, version):
    """
    Call in to the custom key store module to encrypt.
    """
    return custom.encrypt(request, json_key_attributes_dict, pin, version)

def unwrap_key(request, json_key_attributes_dict, pin, version):
    """
    Call in to the custom key store module to decrypt.
    """
    return custom.decrypt(request, json_key_attributes_dict, pin, version)
