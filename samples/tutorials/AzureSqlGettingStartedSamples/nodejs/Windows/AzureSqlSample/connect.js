    var Connection = require('tedious').Connection;
    var Request = require('tedious').Request;
    var TYPES = require('tedious').TYPES;

    // Create connection to database
    var config = {
      server: 'your_server.database.windows.net',	// update me
      authentication: {
          type: 'default',
          options: {
              userName: 'your_user', 			// update me
              password: 'your_password' 		// update me
          }
      },
      options: {
          database: 'your_database',			// update me
	  trustServerCertificate: true,
	  encrypt: true
      }
    }
    var connection = new Connection(config);
    connection.connect();

    // Attempt to connect and execute queries if connection goes through
    connection.on('connect', function(err) {
      if (err) {
        console.log(err);
      } else {
        console.log('Connected');
      }
    });