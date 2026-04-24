<?php
    $serverName = "your_server.database.windows.net";
    $connectionOptions = array(
        "Database" => "your_database",
        "Uid" => "your_user",
        "PWD" => "your_password"
    );
    //Establishes the connection
    $conn = sqlsrv_connect($serverName, $connectionOptions);
    if($conn)
        echo "Connected!"
?>