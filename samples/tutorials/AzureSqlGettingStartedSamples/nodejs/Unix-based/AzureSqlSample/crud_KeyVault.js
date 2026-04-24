var Connection = require('tedious').Connection;
var Request = require('tedious').Request;
var TYPES = require('tedious').TYPES;
var async = require('async');
const KeyVaultSecrets = require("@azure/keyvault-secrets");
const Identity = require("@azure/identity");

var pwd;
var connection;

async function GetSecret(){
	console.log("Getting secret...");
  	// DefaultAzureCredential expects the following three environment variables:
  	// - AZURE_TENANT_ID: The tenant ID in Azure Active Directory
  	// - AZURE_CLIENT_ID: The application (client) ID registered in the AAD tenant
  	// - AZURE_CLIENT_SECRET: The client secret for the registered application
  	const credential = new Identity.DefaultAzureCredential();

	console.log("got default cred");

	const vaultName = process.env["KEY_VAULT_NAME"] || "your_keyvault_name";
  	const url = `https://${vaultName}.vault.azure.net`;

	const client = new KeyVaultSecrets.SecretClient(url, credential);

	try {
	secret = await client.getSecret('AppSecret').then((secret) => {
		pwd = secret.value
		});
	}
	catch (error) {
		console.log("Error connecting to key vault: " + error);
	}
}

async function GetConnection(){
	
	// Create connection to database
	var config = {
  		server: 'your_server.database.windows.net',	// update me
	  	authentication: {
	      		type: 'default',
	      		options: {
        	  		userName: 'your_user', 		// update me
	          		password: pwd			// fetched from key vault
      			}
  		},
	 	options: {
	 	   	database: 'your_database',		// update me
			trustServerCertificate: true,
			encrypt: true
  		}
	}
	connection = new Connection(config);
	await connection.connect();
	console.log("Connected");
	
}

function Start(callback) {
    console.log('Starting...');
    callback(null, 'Jake', 'United States');
}

function Insert(name, location, callback) {
    console.log("Inserting '" + name + "' into Table...");

    request = new Request(
        'INSERT INTO TestSchema.Employees (Name, Location) OUTPUT INSERTED.Id VALUES (@Name, @Location);',
        function(err, rowCount, rows) {
        if (err) {
            callback(err);
        } else {
            console.log(rowCount + ' row(s) inserted');
            callback(null, 'Nikita', 'United States');
        }
        });
    request.addParameter('Name', TYPES.NVarChar, name);
    request.addParameter('Location', TYPES.NVarChar, location);

    // Execute SQL statement
    connection.execSql(request);
}

function Update(name, location, callback) {
    console.log("Updating Location to '" + location + "' for '" + name + "'...");

    // Update the employee record requested
    request = new Request(
    'UPDATE TestSchema.Employees SET Location=@Location WHERE Name = @Name;',
    function(err, rowCount, rows) {
        if (err) {
        callback(err);
        } else {
        console.log(rowCount + ' row(s) updated');
        callback(null, 'Jared');
        }
    });
    request.addParameter('Name', TYPES.NVarChar, name);
    request.addParameter('Location', TYPES.NVarChar, location);

    // Execute SQL statement
    connection.execSql(request);
}

function Delete(name, callback) {
    console.log("Deleting '" + name + "' from Table...");

    // Delete the employee record requested
    request = new Request(
        'DELETE FROM TestSchema.Employees WHERE Name = @Name;',
        function(err, rowCount, rows) {
        if (err) {
            callback(err);
        } else {
            console.log(rowCount + ' row(s) deleted');
            callback(null);
        }
        });
    request.addParameter('Name', TYPES.NVarChar, name);

    // Execute SQL statement
    connection.execSql(request);
}

function Read(callback) {
    console.log('Reading rows from the Table...');

    // Read all rows from table
    request = new Request(
    'SELECT Id, Name, Location FROM TestSchema.Employees;',
    function(err, rowCount, rows) {
    if (err) {
        callback(err);
    } else {
        console.log(rowCount + ' row(s) returned');
        callback(null);
    }
    });

    // Print the rows read
    var result = "";
    request.on('row', function(columns) {
        columns.forEach(function(column) {
            if (column.value === null) {
                console.log('NULL');
            } else {
                result += column.value + " ";
            }
        });
        console.log(result);
        result = "";
    });

    // Execute SQL statement
    connection.execSql(request);
}

function Complete(err, result) {
    if (err) {
       throw err;
    } else {
        console.log("Done!");
    }
}


async function Main() {

// Attempt to connect and execute queries if connection goes through
  console.log('Starting');

  await GetSecret();
  await GetConnection();

  connection.on('connect', function(err) {
    if (err) {
     console.log(err);
    } else {
      console.log('Connected');

    // Execute all functions in the array serially
    async.waterfall([
	Start,
        Insert,
        Update,
        Delete,
        Read
    ], Complete);
   }});
}

Main();