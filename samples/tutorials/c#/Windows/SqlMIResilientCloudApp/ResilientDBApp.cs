using System;
using System.Configuration; // use App.config file
using System.Collections.Specialized;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Data.SqlClient; // use SQL client library
using CG = System.Collections.Generic;
using TD = System.Threading;
using QC = System.Data.SqlClient;

namespace ResilientDBApp
{
	public class Program
	{
		static void Main(string[] args)
		{
			// Query executions and waits
			int executions = 100;				// how many executions
			int sleeptime = 2;                              // wait time between executions (seconds)

			// Connection parameters and resiliency options
			string InstanceConnectionString = "ConnMI1";	// connection string to SQL MI
			bool ResilientQuery = true;			// execute resilient, or non-resilient query to transient errors (retry logic true/false)

			// Query text to execute
			string SQLtext = "INSERT INTO timetable (datestamp) VALUES (CURRENT_TIMESTAMP);";
			bool ReadBack = false;                          // read query response from SQL MI - if using SELECT statements

			try
			{
				for (int i = 1; i <= executions; i++)
				{
					Console.Write("Execution # {0} ", i);
					if (!ResilientQuery)
                    {
						Console.WriteLine ("(NON-RESILIENT)");
						InsertNonResilient(SQLtext, InstanceConnectionString, ReadBack);	// execute NON-resilient DB query - NO retry logic
					} else
                    {
						Console.WriteLine("(RESILIENT)");
						InsertResilient(SQLtext, InstanceConnectionString, ReadBack);		// execute resilient DB query - HAS RETRY LOGIC
					}
					TD.Thread.Sleep(1000 * sleeptime); // wait between the queries
				}
			}
			catch (Exception e)
			{
				Console.WriteLine("Error: " + e.Message); // throw error message if connection unsuccessul
			}
			Console.WriteLine("\nProgram terminated. Press any key to close the window...");
			Console.ReadLine();
		}

		// Logic to execure NON-RESILIENT database query (no retry logic)
		static public void InsertNonResilient(string SQLtext, string InstanceConnectionString, bool ReadBack)
		{
			AccessDatabase(SQLtext, InstanceConnectionString, ReadBack);
			Console.WriteLine();
		}

		// Logic to execure RESILIENT database query
		static public int InsertResilient(string SQLtext, string InstanceConnectionString, bool ReadBack)
		{
			bool succeeded = false;
			int totalNumberOfTimesToTry = 4;	// how many times to retry
			int retryIntervalSeconds = 10;		// after how many seconds

			for (int tries = 1;
			  tries <= totalNumberOfTimesToTry;
			  tries++)
			{
				try
				{
					if (tries > 1)
					{
						Console.WriteLine
						  ("Transient error encountered. Will begin attempt number {0} of {1} max...",
						  tries, totalNumberOfTimesToTry
						  );
						TD.Thread.Sleep(1000 * retryIntervalSeconds);
						retryIntervalSeconds = Convert.ToInt32
						  (retryIntervalSeconds * 1.5);
					}

					AccessDatabase(SQLtext, InstanceConnectionString, ReadBack);
					succeeded = true;
					break;
				}

				catch (QC.SqlException sqlExc)
				{
					if (TransientErrorNumbers.Contains
					  (sqlExc.Number) == true)
					{
						Console.WriteLine("{0}: transient error.", sqlExc.Number);
						continue;
					}
					else
					{
						Console.WriteLine(sqlExc);
						succeeded = false;
						break;
					}
				}

				catch (Exception Exc)
				{
					Console.WriteLine(Exc);
					succeeded = false;
					break;
				}
			}

			if (succeeded == true)
			{
				Console.WriteLine("SUCCESS.\n");
				return 0;
			}
			else
			{
				Console.WriteLine("ERROR: Unable to access the database.\n");
				return 1;
			}
		}

		// Connects to the database, executes query
		static public void AccessDatabase(string sqltext, string instance, bool read)
		{
			//throw new TestSqlException(4060); //(7654321);  // Uncomment for testing.  

			using (var sqlConnection = new QC.SqlConnection
				(GetSqlConnectionString(instance)))
			{
				using (var dbCommand = sqlConnection.CreateCommand())
				{
					sqlConnection.Open();
					dbCommand.CommandText = sqltext;
					Console.WriteLine("Executing query: " + dbCommand.CommandText);

					// are we reading from SQL Server, or only comitting
					if (read == true) // execute SQL query and read reaspons
					{
						var dataReader = dbCommand.ExecuteReader();
						while (dataReader.Read())
						{
							Console.WriteLine(dataReader.GetString(0));
						}
					} else // exectue SQL query and report rows affected
                    {
						int rowsAffected = dbCommand.ExecuteNonQuery(); //execute query and get row count
						Console.WriteLine(rowsAffected + " row(s) updated");
					}
				}
			}
		}

		// Build connection string to the server
		// ADD your SQL MI server details into App.config,
		// OR manuall edit the four string values - DataSource, InitialCatalog, UserID, Password with your SQL MI connection details
		static private string GetSqlConnectionString(string instance)
		{
			// Prepare the connection string to Azure SQL Database.  
			var sqlConnectionSB = new QC.SqlConnectionStringBuilder();

			// Change these values to your values.  
			sqlConnectionSB.DataSource = ConfigurationManager.AppSettings.Get(instance + ".server"); // Server  
			sqlConnectionSB.InitialCatalog = ConfigurationManager.AppSettings.Get(instance + ".database"); // Database  
			sqlConnectionSB.UserID = ConfigurationManager.AppSettings.Get(instance + ".username");
			sqlConnectionSB.Password = ConfigurationManager.AppSettings.Get(instance + ".pass");
			
			// Adjust these values if you like. (ADO.NET 4.5.1 or later.)  
			sqlConnectionSB.ConnectRetryCount = 3;
			sqlConnectionSB.ConnectRetryInterval = 10;  // Seconds.  

			// Leave these values as they are.  
			sqlConnectionSB.IntegratedSecurity = false;
			sqlConnectionSB.Encrypt = true;
			sqlConnectionSB.ConnectTimeout = 30;

			// Test the connection string configuration online
			// Console.WriteLine(sqlConnectionSB);

			return sqlConnectionSB.ToString();
		}

		// Error numbers for transient errors
		static public CG.List<int> TransientErrorNumbers =
		  new CG.List<int> { 4060, 40197, 40501, 40613, 49918, 49919, 49920, 11001 };
	}

}
