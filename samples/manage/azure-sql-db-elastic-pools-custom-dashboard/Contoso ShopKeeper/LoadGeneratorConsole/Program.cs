using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Data.SqlClient;

namespace LoadGeneratorConsole
{
    class Program
    {
        static string _poolConnectionString;
        static int _numRowsToInsert = Properties.Settings.Default.Spike_NumRowsToInsert;
        static int _numTaskPerSpike = Properties.Settings.Default.Spike_NumParallelClients;

        static void Main(string[] args)
        {
            _poolConnectionString = System.Configuration.ConfigurationManager.ConnectionStrings["AdventureWorksCycles"].ConnectionString;

            List<Task> tasks = new List<Task>();

            foreach (var dbname in Properties.Settings.Default.Spike_DatabaseNames)
            {
                tasks.AddRange(ScheduleLoadSpike(dbname, _numTaskPerSpike));
            }

            Task.WaitAll( tasks.ToArray() ) ;
            Console.WriteLine("Tasks completed.");

            Console.ReadLine();
        }

        static Task[] ScheduleLoadSpike(string databaseName, int numTasks)
        {
            Task[] tasks =  new Task[numTasks];
            for (int i =0; i<numTasks;i++)
            {
                tasks[i] = Task.Run(() => GenerateLoadSpike(databaseName));
            }

            return tasks;
        }

        static int _numTasks = 0;
        static int GenerateLoadSpike(string databaseName)
        {
            int taskID = System.Threading.Interlocked.Increment(ref _numTasks);
            Console.WriteLine("{0}_{1}: Preparing load spike...", databaseName, taskID);

            SqlConnectionStringBuilder sqlConnBuilder = new SqlConnectionStringBuilder(_poolConnectionString);
            sqlConnBuilder.InitialCatalog = databaseName;
            string connectionString = sqlConnBuilder.ToString();

            int numRowsAffected = 0;

            try
            {

                SqlConnection conn = new SqlConnection(connectionString);

                string commandText = "INSERT [SalesLT].[SalesOrderHeader] (PurchaseOrderNumber, DueDate, CustomerID, ShipToAddressID, BillToAddressID, ShipMethod, SubTotal) " +
                                        "VALUES (@PoNum, @DueDate,@CustomerID, @ShipToAddressID, @BillToAddressID, @ShipMethod, @SubTotal) ";

                Random r = new Random(1);

                conn.Open();

                for (int i = 0; i < _numRowsToInsert; i++)
                {
                    // if a transient error closed our connection, create a new one and open it
                    if(conn.State == System.Data.ConnectionState.Closed)
                    {
                        Console.ForegroundColor = ConsoleColor.Red;
                        Console.WriteLine("{0}_{1}: Re-creating closed connection", databaseName, taskID);
                        Console.ResetColor();
                        conn = new SqlConnection(connectionString);
                        conn.Open();
                    }


                    List<SqlParameter> parameters = new List<SqlParameter>() {
                        new SqlParameter("@PoNum", String.Format("PO{0}{1}", DateTime.UtcNow.ToString("yyyymmddhhmmss"), r.Next(0,256)) ),
                        new SqlParameter("@DueDate", DateTime.UtcNow.AddDays(3)),
                        new SqlParameter("@CustomerID", 30089),
                        new SqlParameter("@ShipToAddressID", 1034),
                        new SqlParameter("@BillToAddressID", 1034),
                        new SqlParameter("@ShipMethod", "CARGO TRANSPORT 5"),
                        new SqlParameter("@SubTotal", 202.332M)};


                    try
                    {
                        using (SqlCommand cmd = new SqlCommand(commandText, conn))
                        {
                            cmd.CommandType = System.Data.CommandType.Text;
                            cmd.Parameters.AddRange(parameters.ToArray());
                            numRowsAffected += cmd.ExecuteNonQuery();

                        }
                    }
                    catch (SqlException sqlex)
                    {
                        Console.ForegroundColor = ConsoleColor.Green;
                        Console.WriteLine(sqlex.Message);
                        Console.ResetColor();

                        System.Threading.Thread.Sleep(200);
                    }
                    catch (Exception cmdex)
                    {
                        Console.ForegroundColor = ConsoleColor.Blue;
                        Console.WriteLine(cmdex.Message);
                        Console.ResetColor();

                    }

                    if (i % 1000 == 0)
                    {
                        Console.WriteLine("{0}_{1}: Inserted {2} new rows so far", databaseName, taskID, numRowsAffected);
                    }
                }

                conn.Close();
                conn.Dispose();

                Console.WriteLine("{0}_{1}: Inserted {1} new rows", databaseName, taskID, numRowsAffected);
            }
            catch (Exception ex)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine(ex.Message);
                Console.ResetColor();
            }

            Console.WriteLine("{0}_{1}: Finished with load spike.", databaseName, taskID);
            return numRowsAffected;
        }
    }
}
