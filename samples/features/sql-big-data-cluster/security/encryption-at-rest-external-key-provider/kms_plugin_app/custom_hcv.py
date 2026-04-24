# Placeholder for adding logic specific to application
# and backend key store.
#
import os
import json
from Crypto.Cipher import PKCS1_OAEP
from Crypto.PublicKey import RSA
from Crypto.Hash import SHA1
import sys
import hvac

# Append the current application path to sys path to be able to resolve local modules.
#
sys.path.append('.')
sys.path.append('./model')
from constants import ConfigurationConstants, Operations, CryptoConstants
import utils
from json_objects import EncryptDecryptRequest, JsonWebKeyResponse, EncryptDecryptResponse

def decrypt(request, json_key_attributes_dict, pin, version):
    """
    This method will be called by the application entry point
    for decrypting the payload.
    request.value has the plaintext payload
    request.alg contains the padding algorithm for encryption.
    """
    key_path = json_key_attributes_dict["keypath"]
    vault_url = json_key_attributes_dict["vaulturl"]
    key_name = json_key_attributes_dict["keyname"]
    hvac_client = hvac.Client(
        url=vault_url,
        token=pin
    )
    read_response = hvac_client.secrets.kv.read_secret_version(path=key_path)
    rsa_key_pem = read_response['data']['data'][key_name]

    key = RSA.import_key(rsa_key_pem)
    if request.alg == CryptoConstants.WRAP_RSA_OAEP:
        cipher_algo = PKCS1_OAEP.new(key, hashAlgo = SHA1)
        plain_text = cipher_algo.decrypt(request.value)
        response = EncryptDecryptResponse(plain_text)
        return response


def encrypt(request, json_key_attributes_dict, pin, version):
    """
    This method will be called by the application entry point
    for encrypting the payload.
    request.value has the plaintext payload
    request.alg contains the padding algorithm for encryption.
    """
    key_path = json_key_attributes_dict["keypath"]
    vault_url = json_key_attributes_dict["vaulturl"]
    key_name = json_key_attributes_dict["keyname"]
    hvac_client = hvac.Client(
        url=vault_url,
        token=pin
    )
    hvac_client = hvac.Client(
        url=vault_url,
        token=pin
    )
    read_response = hvac_client.secrets.kv.read_secret_version(path=key_path)
    rsa_key_pem = read_response['data']['data'][key_name]

    key = RSA.import_key(rsa_key_pem)
    if request.alg == CryptoConstants.WRAP_RSA_OAEP:
        cipher_algo = PKCS1_OAEP.new(key)
        cipher_text = cipher_algo.encrypt(request.value)
        response = EncryptDecryptResponse(cipher_text)
        return response

def get_key(json_key_attributes_dict, pin, version):
    key_path = json_key_attributes_dict["keypath"]
    vault_url = json_key_attributes_dict["vaulturl"]
    key_name = json_key_attributes_dict["keyname"]
    hvac_client = hvac.Client(
        url=vault_url,
        token=pin
    )
    hvac_client = hvac.Client(
        url=vault_url,
        token=pin
    )
    read_response = hvac_client.secrets.kv.read_secret_version(path=key_path)
    rsa_key_pem = read_response['data']['data'][key_name]

    key = RSA.import_key(rsa_key_pem)
    jwk = JsonWebKeyResponse(key.n, key.e)
    return jwk
