var Connection = require('tedious').Connection;
var Request = require('tedious').Request;
var uuid = require('node-uuid');
var async = require('async');
const KeyVaultSecrets = require("@azure/keyvault-secrets");
const Identity = require("@azure/identity");

var password;
var conn;

async function GetSecret(){
	console.log("Getting secret...");
  	// DefaultAzureCredential expects the following three environment variables:
  	// - AZURE_TENANT_ID: The tenant ID in Azure Active Directory
  	// - AZURE_CLIENT_ID: The application (client) ID registered in the AAD tenant
  	// - AZURE_CLIENT_SECRET: The client secret for the registered application
  	const credential = new Identity.DefaultAzureCredential();

	const vaultName = process.env["KEY_VAULT_NAME"] || "your_keyvault_name";
  	const url = `https://${vaultName}.vault.azure.net`;

	const client = new KeyVaultSecrets.SecretClient(url, credential);

	try {
	  secret = await client.getSecret('AppSecret').then((secret) => {
		password = secret.value;
		});
	}
	catch (error) {
		console.log("Error connecting to key vault: " + error);
	}
}

async function GetConnection(){
   var config = {
     server: 'your_server.database.windows.net',  // update me
     authentication: {
        type: 'default',
        options: {
            userName: 'your_user', 		// update me
            password: password 			// will be retrieved
        }
      },
      options: {
	encrypt: true,
	trustServerCertificate: true,
	database: 'your_database'		// update me
      }
    };

  conn = new Connection(config);
  conn.connect();
}

function exec(sql) {
    var timerName = "QueryTime";

    var request = new Request(sql, function(err) {
        if (err) {
            console.log(err);
        }
    });
    request.on('doneProc', function(rowCount, more, rows) {
        if(!more){
            console.timeEnd(timerName);
        }
    });
    request.on('row', function(columns) {
        columns.forEach(function(column) {
            console.log("Sum: " +  column.value);
        });
    });
    console.time(timerName);
    conn.execSql(request);
}

async function Main() {

  await GetSecret();
  await GetConnection();

	console.log("Got connection");

  conn.on('connect', function(err) {
    if (err) {
     console.log(err);
    } else {
      console.log('Connected');

    // Execute all functions in the array serially
    async.waterfall([
        function(){
            exec('SELECT SUM(Price) FROM Table_with_3M_rows');},
        ]);
     }});

}

Main();