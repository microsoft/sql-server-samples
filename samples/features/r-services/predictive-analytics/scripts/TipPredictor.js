var Connection = require('tedious').Connection;
var Request = require('tedious').Request;
var TYPES = require('tedious').TYPES;

// Provide the connection details appropriate to your environment
var config = {
    userName: '<youruser>',
    password: '<yourpass>',
    server: '<yourserver>',
    options: {
        database: 'taxidata',
        encrypt: true
    }
};

var connection = new Connection(config);

connection.on('connect', function(err) {

    if (err)
    {
        console.log("Unable to Connect: " + err);
        return;
    }

    // If no error, then good to go...
    console.log("Connected.");

    executeStatement();

});


function executeStatement() {
    // Specify the name of the predictive stored procedure
    storedProcedureName = "[dbo].[PredictTip]";

    request = new Request(storedProcedureName, function(err, rowCount) {
        if (err) {
            console.log(err);
        } else {
            console.log(rowCount + ' rows');
        }
    });

    // The input values to the prediction are provided here:
    request.addParameter('passenger_count', TYPES.Int, '1');
    request.addParameter('trip_distance', TYPES.Float, '2.5');
    request.addParameter('trip_time_in_secs', TYPES.Int, '631');
    request.addParameter('direct_distance', TYPES.Float, '2');

    // Iterate over any received rows in the result
    request.on('row', function(columns) {
        columns.forEach(function(column) {
        console.log(column.metadata.colName + " = " + column.value);
        });
    });

    connection.callProcedure(request);
}