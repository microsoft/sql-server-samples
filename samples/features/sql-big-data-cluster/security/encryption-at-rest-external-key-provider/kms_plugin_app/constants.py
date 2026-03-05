# Definition of all the constants
#
class ConfigurationConstants(object):
    """
    File where the application configurations are available
    """
    CONFIG_HSM_SETTINGS_FILE = "configuration.ini"

    """
    Configuration section name where environment variables 
    to be loaded before application execution are defined.
    """
    CONFIG_SECTION_ENVIRONMENT_VARIABLE = "EnvironmentVariables"

    CONFIG_SECTION_PKCS11_CONFIGURATION = "PKCS11Configuration"

    CONFIG_KEY_PKCS11_MODULE_PATH = "PKCS11_MODULE_PATH"

class Operations(object):
    """
    Operations supported by the application. These are the operations 
    that the Big Data Cluster control plane will invoke.
    """
    OPERATION_ENCRYPT='encrypt'
    OPERATION_DECRYPT='decrypt'
    OPERATION_GET_KEY='getKey'

class CryptoConstants(object):
    """
    General constants for cryptography
    """
    KTY_RSA="RSA"
    WRAP_RSA_OAEP="RSA-OAEP"
