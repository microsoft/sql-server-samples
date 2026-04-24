// Learn more about F# at http://fsharp.org

open System
open System.Data.SqlClient

let SumPrice connection =
    let sql = "SELECT SUM(Price) FROM Table_with_5M_rows;"
    let startTicks = DateTime.Now.Ticks;
    use command = new SqlCommand(sql, connection)
    try
        command.ExecuteScalar() |> ignore
        let elapsed = TimeSpan.FromTicks(DateTime.Now.Ticks) - TimeSpan.FromTicks(startTicks)
        elapsed.TotalMilliseconds
    with
    | ex ->
        printfn "%O" ex
        0.

let executeSqlCommand sql connection =
    use command = new SqlCommand(sql, connection)
    command.CommandTimeout <- 300 //5 minutes
    command.ExecuteNonQuery() |> ignore

[<EntryPoint>]
let main argv =
    try
        printfn "*** SQL Server Columnstore demo ***"

        // Build connection string
        let builder = new SqlConnectionStringBuilder()
        builder.DataSource <- "localhost"
        builder.UserID <- "sa"
        builder.Password <- "your_password"
        builder.InitialCatalog <- "master"

        // Connect to SQL
        printf "Connecting to SQL Server ... "
        use connection = new SqlConnection(builder.ConnectionString)
        connection.Open()
        printfn "Done."

        // Create a sample database
        printf "Dropping and creating database 'FSharpSampleDB' ... "
        let sql = "DROP DATABASE IF EXISTS [FSharpSampleDB]; CREATE DATABASE [FSharpSampleDB]"
        executeSqlCommand sql connection
        printfn "Done."

        // Insert 5 million rows into the table 'Table_with_5M_rows'
        printf "Inserting 5 million rows into table 'Table_with_5M_rows'. This takes ~1 minute, please wait ... "
        let sql = "
            USE FSharpSampleDB;
            WITH a AS (SELECT * FROM (VALUES(1),(2),(3),(4),(5),(6),(7),(8),(9),(10)) AS a(a))
            SELECT TOP(5000000)
            ROW_NUMBER() OVER (ORDER BY a.a) AS OrderItemId
            ,a.a + b.a + c.a + d.a + e.a + f.a + g.a + h.a AS OrderId
            ,a.a * 10 AS Price
            ,CONCAT(a.a, N' ', b.a, N' ', c.a, N' ', d.a, N' ', e.a, N' ', f.a, N' ', g.a, N' ', h.a) AS ProductName
            INTO Table_with_5M_rows
            FROM a, a AS b, a AS c, a AS d, a AS e, a AS f, a AS g, a AS h;"

        executeSqlCommand sql connection
        printfn "Done."

        // Execute SQL query without columnstore index
        let elapsedTimeWithoutIndex = SumPrice(connection)
        printfn "Query time WITHOUT columnstore index: %fms" elapsedTimeWithoutIndex

        // Add a Columnstore Index
        printf "Adding a columnstore to table 'Table_with_5M_rows'  ... "
        let sql = "CREATE CLUSTERED COLUMNSTORE INDEX columnstoreindex ON Table_with_5M_rows;"
        executeSqlCommand sql connection
        printfn "Done."

        // Execute the same SQL query again after columnstore index was added
        let elapsedTimeWithIndex = SumPrice(connection)
        printfn "Query time WITH columnstore index: %fms" elapsedTimeWithIndex

        // Calculate performance gain from adding columnstore index
        Math.Round(elapsedTimeWithoutIndex / elapsedTimeWithIndex)
        |> printfn "Performance improvement with columnstore index: %f x!"

        printfn "All done. Press any key to finish..."
        Console.ReadKey(true) |> ignore

    with
    | ex -> printfn "%O" ex

    0 // return an integer exit code
