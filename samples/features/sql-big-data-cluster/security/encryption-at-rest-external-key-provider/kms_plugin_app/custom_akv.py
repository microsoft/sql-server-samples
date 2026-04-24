# Placeholder for adding logic specific to application
# and backend key store.
#
import os
import json
import sys
from azure.identity import DefaultAzureCredential
from azure.keyvault.keys import KeyClient
from azure.keyvault.keys.crypto import CryptographyClient, EncryptionAlgorithm
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
    set_env(json_key_attributes_dict, pin)
    credential = DefaultAzureCredential()
    key_vault_key = get_akv_key(json_key_attributes_dict, credential)
    crypto_client = CryptographyClient(key_vault_key, credential=credential)
    decrypted_payload = crypto_client.decrypt(EncryptionAlgorithm.rsa_oaep, request.value)
    response = EncryptDecryptResponse(decrypted_payload.plaintext)
    return response

def encrypt(request, json_key_attributes_dict, pin, version):
    """
    This method will be called by the application entry point
    for encrypting the payload.
    request.value has the plaintext payload
    request.alg contains the padding algorithm for encryption.
    """
    set_env(json_key_attributes_dict, pin)
    credential = DefaultAzureCredential()
    key_vault_key = get_akv_key(json_key_attributes_dict, credential)
    crypto_client = CryptographyClient(key_vault_key, credential=credential)
    encrypted_payload = crypto_client.encrypt(EncryptionAlgorithm.rsa_oaep, request.value)
    response = EncryptDecryptResponse(encrypted_payload.ciphertext)
    return response

def get_key(json_key_attributes_dict, pin, version):
    set_env(json_key_attributes_dict, pin)
    credential = DefaultAzureCredential()

    key_vault_key = get_akv_key(json_key_attributes_dict, credential)

    # JsonWebKeyResponse expects integer inputs and converts them to byte array
    # However AKV SDK already provides byte arrays for Exponent and Modulus.
    # We will instantiate the object with a dummy value and then overwrite the
    # exponent and module value.
    #
    dummy_val = 1
    key_response = JsonWebKeyResponse(1,1)
    key_response.e = utils.urlsafe_b64encode_as_str(key_vault_key.key.e)
    key_response.n = utils.urlsafe_b64encode_as_str(key_vault_key.key.n)
    return key_response

def get_akv_key(json_key_attributes_dict, credential):
    """
    Gets the AKV key object.
    """
    if "vault_url" in json_key_attributes_dict:
        vault_url = json_key_attributes_dict["vault_url"]
    else:
        raise KeyError('vault_url was expected in the parameters but not found')

    if "keyname" in json_key_attributes_dict:
        key_name = json_key_attributes_dict["keyname"]
    else:
        raise KeyError('keyname was expected in the parameters but not found')
    if "keyversion" in json_key_attributes_dict:
        key_version = json_key_attributes_dict["keyversion"]
    else:
        raise KeyError('keyversion was expected in the parameters but not found')

    key_client = KeyClient(vault_url=vault_url, credential=credential)
    key_vault_key = key_client.get_key(key_name, key_version)

    return key_vault_key

def set_env(json_key_attributes_dict, pin):
    """
    Sets the environment variables for the MS identity credential lookup to work.
    """
    if "azure_client_id" in json_key_attributes_dict:
        key_version = json_key_attributes_dict["azure_client_id"]
    else:
        raise KeyError('azure_client_id was expected in the parameters but not found')

    if "azure_tenant_id" in json_key_attributes_dict:
        key_version = json_key_attributes_dict["azure_tenant_id"]
    else:
        raise KeyError('azure_tenant_id was expected in the parameters but not found')

    os.environ["AZURE_CLIENT_ID"]=json_key_attributes_dict["azure_client_id"]
    os.environ["AZURE_TENANT_ID"]=json_key_attributes_dict["azure_tenant_id"]
    os.environ["AZURE_CLIENT_SECRET"]=pin
