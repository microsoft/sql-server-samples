using Microsoft.Azure.KeyVault;
using Microsoft.Azure.KeyVault.Models;
using Microsoft.Azure.Services.AppAuthentication;
using System;
using System.Data.SqlClient;
using System.Text;
using System.Threading.Tasks;

namespace AzureSqlColumnstoreSample
{
    class Program
    {
        static void Main(string[] args)
        {
            System.Threading.Tasks.Task task = Program.DoWork(args);
            // Becuase this program takes user input, have a long wait.
            var result = task.Wait(TimeSpan.FromMinutes(30));
        }

        static async System.Threading.Tasks.Task DoWork(string[] args)
        {

            Console.WriteLine("*** Azure SQL Columnstore demo ***");

            // Build connection string
            SqlConnectionStringBuilder builder = new SqlConnectionStringBuilder();
            builder.DataSource = "your_server.database.windows.net";   //  update me
            builder.UserID = "your_user";              //  update me
            builder.Password = await GetPasswordFromKeyVault();
            builder.InitialCatalog = "your_database";

            // Connect to Azure SQL
            Console.Write("Connecting to Azure SQL ... ");
            using (SqlConnection connection = new SqlConnection(builder.ConnectionString))
            {
                string sql;
                try
                {
                    connection.Open();
                    string dropTable = "Drop table if exists Table_with_3M_rows";
                    using (SqlCommand command = new SqlCommand(dropTable, connection))
                    {
                        command.ExecuteNonQuery();
                        Console.WriteLine("Table cleaned up.");
                    }

                    // Insert 5 million rows into the table 'Table_with_3M_rows'
                    Console.Write("Inserting 3 million rows into table 'Table_with_3M_rows'. This takes ~1 minute, please wait ... ");
                    StringBuilder sb = new StringBuilder();
                    sb.Append("WITH a AS (SELECT * FROM (VALUES(1),(2),(3),(4),(5),(6),(7),(8),(9),(10)) AS a(a))");
                    sb.Append("SELECT TOP(3000000)");
                    sb.Append("ROW_NUMBER() OVER (ORDER BY a.a) AS OrderItemId ");
                    sb.Append(",a.a + b.a + c.a + d.a + e.a + f.a + g.a + h.a AS OrderId ");
                    sb.Append(",a.a * 10 AS Price ");
                    sb.Append(",CONCAT(a.a, N' ', b.a, N' ', c.a, N' ', d.a, N' ', e.a, N' ', f.a, N' ', g.a, N' ', h.a) AS ProductName ");
                    sb.Append("INTO Table_with_3M_rows ");
                    sb.Append("FROM a, a AS b, a AS c, a AS d, a AS e, a AS f, a AS g, a AS h;");
                    sql = sb.ToString();
                    using (SqlCommand command = new SqlCommand(sql, connection))
                    {
                        command.ExecuteNonQuery();
                        Console.WriteLine("Done.");
                    }

                    // Execute SQL query without columnstore index
                    double elapsedTimeWithoutIndex = SumPrice(connection);
                    Console.WriteLine("Query time WITHOUT columnstore index: " + elapsedTimeWithoutIndex + "ms");

                    // Add a Columnstore Index
                    Console.Write("Adding a columnstore to table 'Table_with_3M_rows'  ... ");
                    sql = "CREATE CLUSTERED COLUMNSTORE INDEX columnstoreindex ON Table_with_3M_rows;";
                    using (SqlCommand command = new SqlCommand(sql, connection))
                    {
                        command.ExecuteNonQuery();
                        Console.WriteLine("Done.");
                    }

                    // Execute the same SQL query again after columnstore index was added
                    double elapsedTimeWithIndex = SumPrice(connection);
                    Console.WriteLine("Query time WITH columnstore index: " + elapsedTimeWithIndex + "ms");

                    // Calculate performance gain from adding columnstore index
                    Console.WriteLine("Performance improvement with columnstore index: "
                        + Math.Round(elapsedTimeWithoutIndex / elapsedTimeWithIndex) + "x!");
                }

                catch (Exception e)
                {
                    Console.WriteLine(e.ToString());
                }
                finally
                {
                    string dropTable = "Drop table if exists Table_with_3M_rows";
                    using (SqlCommand command = new SqlCommand(dropTable, connection))
                    {
                        command.ExecuteNonQuery();
                        Console.WriteLine("Table cleaned up.");
                    }
                }
            }
            Console.WriteLine("All done. Press any key to finish...");
            Console.ReadKey(true);
        }

        private static async Task<string> GetPasswordFromKeyVault()
        {
            Console.WriteLine("Trying to get Password from Key Vault.  Press a key to continue...");
            Console.ReadKey(true);
            /* The next four lines of code show you how to use AppAuthentication library to fetch secrets from your key vault */
            AzureServiceTokenProvider azureServiceTokenProvider = new AzureServiceTokenProvider();
            KeyVaultClient keyVaultClient = new KeyVaultClient(new KeyVaultClient.AuthenticationCallback(azureServiceTokenProvider.KeyVaultTokenCallback));
            SecretBundle secret = await keyVaultClient.GetSecretAsync("https://your_keyvault_name.vault.azure.net/secrets/AppSecret"); // update me
            return secret.Value;
        }

        public static double SumPrice(SqlConnection connection)
        {
            String sql = "SELECT SUM(Price) FROM Table_with_3M_rows";
            long startTicks = DateTime.Now.Ticks;
            using (SqlCommand command = new SqlCommand(sql, connection))
            {
                try
                {
                    var sum = command.ExecuteScalar();
                    TimeSpan elapsed = TimeSpan.FromTicks(DateTime.Now.Ticks) - TimeSpan.FromTicks(startTicks);
                    return elapsed.TotalMilliseconds;
                }
                catch (Exception e)
                {
                    Console.WriteLine(e.ToString());
                }
            }
            return 0;
        }
    }
}