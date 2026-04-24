<?php
$serverName = 'localhost';
$connectionOptions = [
    'Database' => 'SampleDB',
    'Uid' => 'sa',
    'PWD' => 'your_password',
];
// Establishes the connection
$conn = sqlsrv_connect($serverName, $connectionOptions);

// Insert Query
echo('Inserting a new row into table' . PHP_EOL);
$tsql = 'INSERT INTO TestSchema.Employees (Name, Location) VALUES (?,?);';
$params = ['Jake', 'United States'];
$getResults = sqlsrv_query($conn, $tsql, $params);
$rowsAffected = sqlsrv_rows_affected($getResults);
if ($getResults === false || $rowsAffected === false) {
    format_errors(sqlsrv_errors());
    die();
}
echo($rowsAffected . ' row(s) inserted: ' . PHP_EOL);

sqlsrv_free_stmt($getResults);

// Update Query

$userToUpdate = 'Nikita';
$tsql = 'UPDATE TestSchema.Employees SET Location = ? WHERE Name = ?';
$params = ['Sweden', $userToUpdate];
echo('Updating Location for user ' . $userToUpdate . PHP_EOL);

$getResults = sqlsrv_query($conn, $tsql, $params);
$rowsAffected = sqlsrv_rows_affected($getResults);
if ($getResults === false || $rowsAffected === false) {
    format_errors(sqlsrv_errors());
    die();
}
echo($rowsAffected . ' row(s) updated: ' . PHP_EOL);
sqlsrv_free_stmt($getResults);

// Delete Query
$userToDelete = 'Jared';
$tsql = 'DELETE FROM TestSchema.Employees WHERE Name = ?';
$params = [$userToDelete];
$getResults = sqlsrv_query($conn, $tsql, $params);
echo('Deleting user ' . $userToDelete . PHP_EOL);
$rowsAffected = sqlsrv_rows_affected($getResults);
if ($getResults === false || $rowsAffected === false) {
    format_errors(sqlsrv_errors());
    die();
}
echo($rowsAffected . ' row(s) deleted: ' . PHP_EOL);
sqlsrv_free_stmt($getResults);

// Read Query
$tsql = 'SELECT Id, Name, Location FROM TestSchema.Employees;';
$getResults = sqlsrv_query($conn, $tsql);
echo('Reading data from table' . PHP_EOL);
if ($getResults === false) {
    format_errors(sqlsrv_errors());
    die();
}
while ($row = sqlsrv_fetch_array($getResults, SQLSRV_FETCH_ASSOC)) {
    echo($row['Id'] . ' ' . $row['Name'] . ' ' . $row['Location'] . PHP_EOL);
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
