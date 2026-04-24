<?php
$timeStart = microtime(true);

$serverName = 'localhost';
$connectionOptions = [
    'Database' => 'SampleDB',
    'Uid' => 'sa',
    'PWD' => 'your_password',
];
// Establishes the connection
$conn = sqlsrv_connect($serverName, $connectionOptions);

// Read Query
$tsql = 'SELECT SUM(Price) as sum FROM Table_with_5M_rows';
$getResults = sqlsrv_query($conn, $tsql);
echo('Sum: ');
if ($getResults === false) {
    format_errors(sqlsrv_errors());
    die();
}
while ($row = sqlsrv_fetch_array($getResults, SQLSRV_FETCH_ASSOC)) {
    echo($row['sum'] . PHP_EOL);
}
sqlsrv_free_stmt($getResults);

function format_errors($errors)
{
    /* Display errors. */
    echo 'Error information: ';

    foreach ($errors as $error) {
        echo 'SQLSTATE: ' . $error['SQLSTATE'] . '';
        echo 'Code: ' . $error['code'] . '';
        echo 'Message: ' . $error['message'] . '';
    }
}

$timeEnd = microtime(true);
$executionTime = round((($timeEnd - $timeStart) * 1000), 2);
echo 'QueryTime: ' . $executionTime . ' ms';
