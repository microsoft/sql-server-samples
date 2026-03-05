<?php
$serverName = 'localhost';
$connectionOptions = [
    'Database' => 'SampleDB',
    'Uid' => 'sa',
    'PWD' => 'your_password',
];
// Establishes the connection
$conn = sqlsrv_connect($serverName, $connectionOptions);
if ($conn) {
    echo 'Connected!';
}
