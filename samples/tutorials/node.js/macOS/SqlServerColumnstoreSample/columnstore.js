var Connection = require('tedious').Connection;
var Request = require('tedious').Request;
var uuid = require('node-uuid');
var async = require('async');

var config = {
    userName: 'sa',
    password: 'your_password',
    server: 'localhost',
    options: {
        database: 'SampleDB'
    }
    // When you connect to Azure SQL Database, you need these next options.
    //options: {encrypt: true, database: 'yourDatabase'}
};


var connection = new Connection(config);
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
    connection.execSql(request);
}
// Open connection and execute query
connection.on('connect', function(err) {
    async.waterfall([
        function(){
            exec('SELECT SUM(Price) FROM Table_with_5M_rows');
        },
    ]);
});

// Initialize the connection.
connection.connect();
