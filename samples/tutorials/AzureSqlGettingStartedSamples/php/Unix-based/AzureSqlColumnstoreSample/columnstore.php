<?php
$time_start = microtime(true);

$serverName = "your_server.database.windows.net";
$connectionOptions = array(
    "Database" => "your_database",
    "Uid" => "your_user",
    "PWD" => "your_password"
);
//Establishes the connection
$conn = sqlsrv_connect($serverName, $connectionOptions);

//Read Query
$tsql= "SELECT SUM(Price) as sum FROM Table_with_3M_rows";
$getResults= sqlsrv_query($conn, $tsql);
echo ("Sum: ");
if ($getResults == FALSE)
    die(FormatErrors(sqlsrv_errors()));
while ($row = sqlsrv_fetch_array($getResults, SQLSRV_FETCH_ASSOC)) {
    echo ($row['sum'] . PHP_EOL);

}
sqlsrv_free_stmt($getResults);

function FormatErrors( $errors )
{
    /* Display errors. */
    echo "Error information: ";

    foreach ( $errors as $error )
    {
        echo "SQLSTATE: ".$error['SQLSTATE']."";
        echo "Code: ".$error['code']."";
        echo "Message: ".$error['message']."";
    }
}
$time_end = microtime(true);
$execution_time = round((($time_end - $time_start)*1000),2);
echo 'QueryTime: '.$execution_time.' ms';

?>