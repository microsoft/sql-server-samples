using System;
using System.Data;
using System.Data.SqlClient;
using System.IO;

namespace BulkLoader
{
    class Program
    {
        static void Main(string[] args)
        {
            try
            {
                Load(args[0]);
            }
            catch(Exception e)
            {
                Console.WriteLine("Error: {0}", e.ToString());
            }
        }

        static void Load(string path)
        {
            // Load the file
            var reader = new StreamReader(path);

            // Get the Data Table to hold the rows
            var datatable = GetDataTable();

            // Setup our SQL Connection to our SQL Data Warehouse
            var connection = GetConnection();

            // Iterate through the file
            string row;
            while ((row = reader.ReadLine()) != null)
            {
                // Split the row by comma
                var values = row.Split(',');

                // Add the row values to the Data Table
                datatable.Rows.Add(values[0], values[1], values[2]);
            };

            // Open the connection to SQL Data Warehouse
            connection.Open();

            // Create a Bulk Copy class
            var bulkCopy = new SqlBulkCopy(connection);

            // Define the target table
            bulkCopy.DestinationTableName = "dbo.DimProducts";

            // Write the rows to the table
            bulkCopy.WriteToServer(datatable);

            // Cleanup
            connection.Close();
            reader.Close();
            datatable.Dispose();
        }

        static SqlConnection GetConnection()
        {
            var sb = new SqlConnectionStringBuilder();
            sb.DataSource = "##LOGICAL SQL SERVER##.database.windows.net";
            sb.InitialCatalog = "##DATABASE##";
            sb.UserID = "##USERNAME##";
            sb.Password = "##PASSWORD##";

            return new SqlConnection(sb.ConnectionString);

        }

        static DataTable GetDataTable()
        {
            var dt = new DataTable();
            dt.Columns.AddRange
            (
                new DataColumn[3]
                {
                    new DataColumn("ProductId", typeof(int)),
                    new DataColumn("Name", typeof(string)),
                    new DataColumn("Description", typeof(string))
                }
            );

            return dt;
        }
    }
}