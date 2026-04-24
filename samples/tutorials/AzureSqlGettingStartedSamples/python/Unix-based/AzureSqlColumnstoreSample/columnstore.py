import pyodbc
import datetime
server = 'your_server.database.windows.net'
database = 'your_database'
username = 'your_user'


from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

credential = DefaultAzureCredential()

secret_client = SecretClient(vault_url="https://<your_key_vault_name>.vault.azure.net", credential=credential)

# NOTE: please replace the ("<your-secret-name>") with the name of the secret in your vault
secret = secret_client.get_secret("AppSecret")

password = secret.value

cnxn = pyodbc.connect('DRIVER={ODBC Driver 17 for SQL Server};SERVER='+server+';DATABASE='+database+';UID='+username+';PWD='+ password)
cursor = cnxn.cursor()
tsql = "SELECT SUM(Price) as sum FROM Table_with_3M_rows"
a = datetime.datetime.now()
with cursor.execute(tsql):
  b = datetime.datetime.now()
  c = b - a
  for row in cursor:
    print ('Sum:', str(row[0]))
  print ('QueryTime:', c.microseconds, 'ms')