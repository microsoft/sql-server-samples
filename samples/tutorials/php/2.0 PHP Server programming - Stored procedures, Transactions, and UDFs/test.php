<?php
$serverName = 'tcp:your_server.database.windows.net,1433';
$connectionOptions = [
    'Database' => 'your_database',
    'Uid' => 'your_username',
    'PWD' => ' your_password',
];
// Establishes the connection
$conn = sqlsrv_connect($serverName, $connectionOptions);

/*
 * Stored Procedure
 */

$tsql = 'CREATE PROCEDURE sp_GetCompanies22 AS BEGIN SELECT [CompanyName] FROM SalesLT.Customer END';
$storedProc = sqlsrv_query($conn, $tsql);
if ($storedProc === false) {
    echo 'Error creating Stored Procedure';
    format_errors(sqlsrv_errors());
    die();
}
sqlsrv_free_stmt($storedProc);

$tsql = 'exec sp_GETCompanies22';
// Executes the query
$getProducts = sqlsrv_query($conn, $tsql);
// Error handling
if ($getProducts === false) {
    echo 'Error executing Stored Procedure';
    format_errors(sqlsrv_errors());
    die();
}
$productCount = 0;
$ctr = 0;
?>
    <h1> First 10 results are after executing the stored procedure: </h1>
<?php
while ($row = sqlsrv_fetch_array($getProducts, SQLSRV_FETCH_ASSOC)) {
    // Printing only the first 10 results
    if ($ctr > 9) {
        break;
    }
    $ctr++;
    echo($row['CompanyName']);
    echo('<br/>');
    $productCount++;
}
sqlsrv_free_stmt($getProducts);
$tsql = 'DROP PROCEDURE sp_GETCompanies22';

$storedProc = sqlsrv_query($conn, $tsql);
if ($storedProc === false) {
    echo 'Error dropping Stored Procedure';
    format_errors(sqlsrv_errors());
    die();
}
sqlsrv_free_stmt($storedProc);
?>
<?php
/*
 * Transaction
 */

if (sqlsrv_begin_transaction($conn) === false) {
    echo 'Error opening connection';
    format_errors(sqlsrv_errors());
    die();
}

/* Set up and execute the first query. */
$tsql1 = 'INSERT INTO SalesLT.SalesOrderDetail
       (SalesOrderID,OrderQty,ProductID,UnitPrice)
       VALUES (71774, 22, 709, 33)';
$stmt1 = sqlsrv_query($conn, $tsql1);

/* Set up and execute the second query. */
$tsql2 = 'UPDATE SalesLT.SalesOrderDetail SET OrderQty = (OrderQty + 1) WHERE ProductID = 709';
$stmt2 = sqlsrv_query($conn, $tsql2);

/* If both queries were successful, commit the transaction. */
/* Otherwise, rollback the transaction. */
if ($stmt1 && $stmt2) {
    sqlsrv_commit($conn);
    ?>
    <h1> Transaction was committed </h1>

    <?php
} else {
    sqlsrv_rollback($conn);
    echo "Transaction was rolled back.\n";
}

/* Free statement and connection resources. */
sqlsrv_free_stmt($stmt1);
sqlsrv_free_stmt($stmt2);

?>
<?php
/*
 * UDF
 */
// Dropping function if it already exists
$tsql1 = "IF OBJECT_ID(N'dbo.ifGetTotalItems', N'IF') IS NOT NULL DROP FUNCTION dbo.ifGetTotalItems;";
$getProducts = sqlsrv_query($conn, $tsql1);
// Error handling
if ($getProducts === false) {
    echo 'Error deleting the UDF';
    format_errors(sqlsrv_errors());
    die();
}
$tsql1 = 'CREATE FUNCTION dbo.ifGetTotalItems (@OrderID INT) RETURNS TABLE WITH SCHEMABINDING AS RETURN (
    SELECT SUM(OrderQty) AS TotalItems FROM SalesLT.SalesOrderDetail
    WHERE SalesOrderID = @OrderID
    GROUP BY SalesOrderID
);';
$getProducts = sqlsrv_query($conn, $tsql1);
// Error handling
if ($getProducts === false) {
    echo 'Error creating the UDF';
    format_errors(sqlsrv_errors());
    die();
}
$tsql1 = 'SELECT s.SalesOrderID, s.OrderDate, s.CustomerID, f.TotalItems
FROM SalesLT.SalesOrderHeader s
CROSS APPLY dbo.ifGetTotalItems(s.SalesOrderID) f
ORDER BY SalesOrderID;';
$getProducts = sqlsrv_query($conn, $tsql1);
// Error handling
if ($getProducts === false) {
    echo 'Error executing the UDF';
    format_errors(sqlsrv_errors());
    die();
}
$productCount = 0;
$ctr = 0;
?>
    <h1> First 10 results are after executing a query that uses the UDF: </h1>
<?php
echo 'SalesOrderID      CustomerID      TotalItems';
echo('<br/>');

while ($row = sqlsrv_fetch_array($getProducts, SQLSRV_FETCH_ASSOC)) {
    // Printing only the top 10 results
    if ($ctr > 9) {
        break;
    }
    $ctr++;
    echo sprintf(
        '%s%s%s%s%s',
        $row['SalesOrderID'],
        str_repeat('&nbsp;', 13),
        $row['CustomerID'],
        str_repeat('&nbsp;', 11),
        $row['TotalItems']
    );
    echo('<br/>');
    $productCount++;
}
sqlsrv_free_stmt($getProducts);
