<?php
    // Setup the connection
    $serverName = 'localhost';
    $connectionOptions = [
        'Database' => 'SampleDB',
        'Uid' => 'sa',
        'PWD' => 'your_password'
    ];

    // Establish the connection
    $connection = sqlsrv_connect($serverName, $connectionOptions);
    if ($connection) {
        echo 'Connected!';
    }
