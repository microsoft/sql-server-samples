var Sequelize = require('sequelize');
    const KeyVaultSecrets = require("@azure/keyvault-secrets");
    const Identity = require("@azure/identity");


    var userName = 'your_user';     			// update me
    var password = 'fetch_from_key_vault';		// fetched from key vault
    var hostName = 'your_server.database.windows.net';  // update me
    var sampleDbName = 'your_database';  		//update me


async function GetSecret(){
	console.log("Getting secret...");
  	// DefaultAzureCredential expects the following three environment variables:
  	// - AZURE_TENANT_ID: The tenant ID in Azure Active Directory
  	// - AZURE_CLIENT_ID: The application (client) ID registered in the AAD tenant
  	// - AZURE_CLIENT_SECRET: The client secret for the registered application
  	const credential = new Identity.DefaultAzureCredential();

	console.log("got default cred");

	const vaultName = process.env["KEYVAULT_NAME"] || "your_key_vault_name";
  	const url = `https://${vaultName}.vault.azure.net`;

	console.log("connecting to vault: " + vaultName + " at: " + url);

	const client = new KeyVaultSecrets.SecretClient(url, credential);

	try {
	secret = await client.getSecret('AppSecret').then((secret) => {
		password = secret.value
		});
	}
	catch (error) {
		console.log("Error connecting to key vault: "+ err);
	}
}

async function Main() {

// Attempt to connect and execute queries if connection goes through
  console.log('Starting');

  await GetSecret();

    // Initialize Sequelize to connect to sample DB
    var sampleDb = new Sequelize(sampleDbName, userName, password, {
        dialect: 'mssql',
        host: hostName,
        port: 1433, // Default port
        logging: false, // disable logging; default: console.log,
	encrypt: true,

        dialectOptions: {
            requestTimeout: 30000 // timeout = 30 seconds
        }
    });

    // Define the 'User' model
    var User = sampleDb.define('user', {
        firstName: Sequelize.STRING,
        lastName: Sequelize.STRING
    });

    // Define the 'Task' model
    var Task = sampleDb.define('task', {
        title: Sequelize.STRING,
        dueDate: Sequelize.DATE,
        isComplete: Sequelize.BOOLEAN
    });

    // Model a 1:Many relationship between User and Task
    User.hasMany(Task);

    console.log('**Node CRUD sample with Sequelize and MSSQL **');

    // Tell Sequelize to DROP and CREATE tables and relationships in the database
    sampleDb.sync({force: true})
    .then(function() {
        console.log('\nCreated database schema from model.');

        // Create demo: Create a User instance and save it to the database
        User.create({firstName: 'Anna', lastName: 'Shrestinian'})
        .then(function(user) {
            console.log('\nCreated User:', user.get({ plain: true}));

            // Create demo: Create a Task instance and save it to the database
            Task.create({
                title: 'Ship Helsinki', dueDate: new Date(2017,04,01), isComplete: false
            })
            .then(function(task) {
                console.log('\nCreated Task:', task.get({ plain: true}));

                // Association demo: Assign task to user
                user.setTasks([task])
                .then(function() {
                    console.log('\nAssigned task \''
                + task.title
                + '\' to user ' + user.firstName
                + ' ' + user.lastName);

                    // Read demo: find incomplete tasks assigned to user 'Anna''
                    User.findAll({
                        where: { firstName: 'Anna'},
                        include: [{
                            model: Task,
                            where: { isComplete: false }
                        }]
                    })
                    .then(function(users) {
                        console.log('\nIncomplete tasks assigned to Anna:\n',
                    JSON.stringify(users));

                        // Update demo: change the 'dueDate' of a task
                        Task.findByPk(1).then(function(task) {
                            console.log('\nUpdating task:',
                    task.title + ' ' + task.dueDate);
                            task.update({
                                dueDate: new Date(2016,06,30)
                            })
                            .then(function() {
                                console.log('dueDate changed:',
                        task.title + ' ' + task.dueDate);

                                // Delete demo: delete all tasks with a dueDate in 2016
                                console.log('\nDeleting all tasks with with a dueDate in 2016');
                                Task.destroy({
                                    where: { dueDate: {[Sequelize.Op.lte]: new Date(2016,12,31)}},
                                }).then(function() {  // delete this line and the below, and corresponding closing braces and see what happens.
                                	Task.findAll()
					.then(function(tasks) {
                                        console.log('Tasks in database after delete:',
                            JSON.stringify(tasks));
                                        console.log('\nAll done!');
				    })

                                })
                            })
                        })
                    })
                })
            })
        })
    })
}

Main();