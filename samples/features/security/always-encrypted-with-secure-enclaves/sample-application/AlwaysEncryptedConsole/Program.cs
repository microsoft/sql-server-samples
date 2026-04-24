//********************************************************* 
// Copyright (c) Microsoft. All rights reserved. 
// This code is licensed under the MIT License (MIT). 
// THIS CODE IS PROVIDED *AS IS* WITHOUT WARRANTY OF 
// ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY 
// IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR 
// PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT. 
// 
// Author: Michael Howard, Azure Data Security
//*********************************************************

//*********************************************************
// Demo Steps
// Step 1
// Run, as-is, AE is set to false,
// and the code will return ciphertext
// 
// Step 2
// Set useAlwaysEncrypted to true (line 47)
// Re-run code, will fail because of no params
//
// Step 3
// Set testWithParams to true (line 50)
// Re-run code, but will fail because of no AKV
//
// Step 4
// Set registerAkv4Ae to true (line 53)
// Re-run. At this point everything should work.
// Two queries, the first is slow because intial authn/authz/column metadata
// Second is much faster

using Azure.Core;
using Microsoft.Data.SqlClient;
using System.Data;
using System.Diagnostics;

partial class Program
{
    static void Main()
    {
        // START all these flags should be false

        // Demo step 1 will not use AE,
        // and you will only see the SSN and Salary columns as ciphertext

        // Demo step 2 set this to true
        bool useAlwaysEncrypted = true;

        // Demo step 3 set this to true
        bool testWithParams = true;

        // Demo step 4 set this to true
        bool registerAkv4Ae = true;

        Console.WriteLine($"Cold Start\nUse Always Encrypted with Enclaves? {(useAlwaysEncrypted ? "Yes" : "No")}");

        // Login to Azure and get Azure SQL DB OAuth2 token
        Console.WriteLine("Connecting to Azure");
        (TokenCredential? credential, string? oauth2TokenSql) = LoginToAure();
        if (credential is null || oauth2TokenSql is null)
            throw new ArgumentNullException("Unable to login to Azure");

        Console.WriteLine("Connecting to Azure SQL DB");

        // Connect to Azure SQL DB using EntraID AuthN rather than Windows or SQL AuthN
        var connectionString = GetSQLConnectionString(useAlwaysEncrypted);
        using SqlConnection conn = new(connectionString)
        {
            AccessToken = oauth2TokenSql
        };
        conn.Open();

        // Register the enclave attestation URL, do this once on app startup
        if (useAlwaysEncrypted && registerAkv4Ae)
            RegisterAkvForAe(credential);

        // From here on is real database work
        SqlCommand sqlCommand;

        if (useAlwaysEncrypted == false)
        {
            string query =
                "SELECT Top 10 SSN, Salary, LastName, FirstName " +
                "FROM Employees";

            sqlCommand = new(query, conn);
            DoQuery(sqlCommand);
        }
        else
        {
            ///////////////////////////////////////////////////
            // QUERY #1: Get count based on employee salary 
            // Demo step 4 - keep as is, but after demo set to false
            if (testWithParams == false)
            {
                string query1 = "SELECT count(*) FROM Employees where [Salary] > 50000";
                sqlCommand = new(query1, conn);
                DoQuery(sqlCommand);
            }

            ///////////////////////////////////////////////////
            // QUERY #2: Find minimum salary with specific SSN
            string query2 =
                "SELECT [SSN], [Salary], [LastName], [FirstName] " +
                "FROM Employees WHERE [Salary] > @MinSalary AND [SSN] LIKE @SSN " +
                "ORDER by [Salary] DESC";

            sqlCommand = new(query2, conn);

            // MUST use parameters
            SqlParameter minSalaryParam = new("@MinSalary", SqlDbType.Money) {
                Value = 50_000
            };
            sqlCommand.Parameters.Add(minSalaryParam);

            SqlParameter ssnParam = new("@SSN", SqlDbType.Char) {
                Value = "6%"
            };
            sqlCommand.Parameters.Add(ssnParam);

            DoQuery(sqlCommand);

            ///////////////////////////////////////////////////
            // QUERY #2: sproc to find salary range
            string query3 = "EXEC usp_GetSalary @MinSalary = @MinSalaryRange, @MaxSalary = @MaxSalaryRange";

            sqlCommand = new(query3, conn);

            SqlParameter minSalaryRange = new("@MinSalaryRange", SqlDbType.Money) {
                Value = 40_000
            };
            sqlCommand.Parameters.Add(minSalaryRange);

            SqlParameter maxSalaryRange = new("@MaxSalaryRange", SqlDbType.Money) {
                Value = 42_000
            };
            sqlCommand.Parameters.Add(maxSalaryRange);

            DoQuery(sqlCommand);
        }
    }
    
    // Perform the actual query and gather stats
    // The time is the round trip time to and from the database
    // This will be higher than the actual query time due to network latency
    // IMPORTANT: the first query is slower due to lots of moving parts
    // getting loaded, authN, AuthZ, etc.
    static void DoQuery(SqlCommand sqlCommand)
    {
        var stopwatch = Stopwatch.StartNew();

        Console.WriteLine($"\nPerforming Query\n{sqlCommand.CommandText}");
        
        SqlDataReader? data = null;
        try
        {
            data = sqlCommand.ExecuteReader();
        }
        catch (SqlException ex)
        {
            Console.WriteLine(ex.Message);
            Environment.Exit(-1);
        }
        catch (System.InvalidOperationException ex)
        {
            Console.WriteLine(ex.Message);
            Environment.Exit(-1);
        }

        stopwatch.Stop();
        Console.WriteLine($"Network Roundtrip + Query took [{stopwatch.ElapsedMilliseconds}ms]");

        DumpData(data);
        data.Close();
    }
}