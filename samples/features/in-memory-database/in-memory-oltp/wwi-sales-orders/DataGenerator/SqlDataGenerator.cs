//----------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
//
// THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
// EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES
// OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
//----------------------------------------------------------------------------------
// The example companies, organizations, products, domain names,
// e-mail addresses, logos, people, places, and events depicted
// herein are fictitious.  No association with any real company,
// organization, product, domain name, email address, logo, person,
// places, or events is intended or should be inferred.

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Data.SqlClient;
using System.Data.Sql;
using System.Data;
using System.Diagnostics;
using System.Collections.Concurrent;
using Microsoft.SqlServer.Server;

namespace DataGenerator
{
    /// <summary>SqlDataGenerator is a class used for creating SQL Server sample data by using multiple Asychronous Tasks.</summary>
    public class SqlDataGenerator
    {
        private Action<int, Exception> onException;
        private ConcurrentDictionary<int, CancellableTask> tasks;

        private string sqlConnectionString;
        private string sqlInsertSPName;
        private int sqlCommandTimeout;
        private int batchSize;
        private int initialNumberOfTasks;
        private int delay;

        private Stopwatch timer;
        private int numberOfRowsInserted = 0;

        protected ThreadLocal<Random> randomValue;
        private bool running = false;

        /// <summary>Wait Time in milliseconds between executing SqlCommands.</summary>
        /// <returns>Integer</returns>
        public int Delay
        {
            get { return delay; }
            set
            {
                Validate(this.batchSize, this.initialNumberOfTasks, value);
                delay = value;
            }
        }

        /// <summary>The row count of the sample data batch that every task generates.</summary>
        /// <returns>Integer</returns>
        public int BatchSize
        {
            get { return batchSize; }
            set
            {
                Validate(value, this.initialNumberOfTasks, this.delay);
                batchSize = value;
            }
        }

        /// <summary>Rows (inserted or updated) per second.</summary>
        /// <returns>Double</returns>
        public double Rps => (double)this.numberOfRowsInserted / this.timer.Elapsed.TotalSeconds;

        /// <summary>The number of current active tasks.</summary>
        /// <returns>Integer</returns>
        public int RunningTasks => this.tasks.Count();

        /// <summary>Running Status</summary>
        /// <returns>Bool</returns>
        public bool IsRunning => this.running;

        /// <summary>Creates a new instance of the SqlDataGenerator Class.</summary>
        /// <param name="sqlConnectionString">The sqlserver connectionString. Example: "Data Source=.;Initial Catalog=DbName;Integrated Security=True"</param>
        /// <param name="sqlInsertSPName">The Insert Orders sqlserver stored procedure. Example: "InsertOrdersSP". </param>
        /// <param name="sqlCommandTimeout">The sqlserver command timeout. Example: 600</param>
        /// <param name="initialNumberOfTasks">The number of concurrent tasks. Example: 5. Note that every task 1.Creates and opens a new sql connection 2.Creates sample data and 3.Executes the sql stored procedure passed in sqlStoredProcedureName endless times until stopped by the user.</param>
        /// <param name="delayInMilliseconds">Delay in Millisecods betweeen Sql Commands. Example. 100</param>
        /// <param name="batchSize">The row count of the batch size to be used by every task. Example: 200</param>
        /// <param name="onException">Exception call back method with TaskId(int) and exception(Exception). Example: ExceptionCallback</param>
        public SqlDataGenerator(
            string sqlConnectionString,
            string sqlInsertSPName,
            int sqlCommandTimeout,
            int initialNumberOfTasks,
            int delayInMilliseconds,
            int batchSize,
            Action<int, Exception> onException)
        {

            this.sqlConnectionString = sqlConnectionString;
            this.sqlInsertSPName = sqlInsertSPName;
            this.sqlCommandTimeout = sqlCommandTimeout;
            this.onException = onException;
            this.tasks = new ConcurrentDictionary<int, CancellableTask>();
            this.randomValue = new ThreadLocal<Random>(() => new Random(Guid.NewGuid().GetHashCode()));
            this.initialNumberOfTasks = initialNumberOfTasks;
            this.delay = delayInMilliseconds;
            this.batchSize = batchSize;

            Validate(this.batchSize, this.initialNumberOfTasks, this.delay);

        }

        /// <summary>Creates and Starts all the tasks asynchronously. Note that every task 1.Creates and opens a new sql connection 2.Creates a batch of BatchSize sample data and 3.Executes the sql stored procedure passed in sqlStoredProcedureName endless times until stopped by the user.</summary>
        /// <returns>Task</returns>
        public async Task RunAsync()
        {
            if (this.running)
            {
                return;
            }
            timer = Stopwatch.StartNew();
            await this.RunAsync(this.initialNumberOfTasks);
        }

        /// <summary>Stops all tasks asynchronously.</summary>
        /// <returns>Task</returns>
        public async Task StopAsync()
        {
            await this.StopAsync(this.RunningTasks);
        }

        /// <summary>Restarts the Rows/Second Counter. This is called internally every time the input is changed.</summary>
        /// <returns>void</returns>
        public void RpsReset()
        {
            if (running)
            {
                this.timer.Restart();
                this.numberOfRowsInserted = 0;
            }
        }

        /// <summary>Updates the number of tasks that the DataGenerator is using.</summary>
        /// <returns>Task</returns>
        /// <remarks></remarks>
        /// <param name="numberOfTasks">The number of Tasks to start/stop depending of the number of tasks currently running.</param>
        public async Task UpdateTasksAsync(int numberOfTasks)
        {
            int diff = numberOfTasks - this.RunningTasks;

            if (!running || diff == 0)
            {
                this.initialNumberOfTasks = numberOfTasks;
                return;
            }

            if (diff < 0)
            {
                await this.StopAsync(-diff);
            }
            else
            {
                await this.RunAsync(diff);
            }
        }

        /// <summary>InsertOrdersAsync(int taskId, CancellationToken token)</summary>
        /// <returns>Task</returns>
        /// <remarks>Every Task creates a new sql connection, creates a new sqlcommand, create a batch of random numbers, and executes indefinetely until stopped by the user.</remarks>
        /// <param name="taskId">The taskId</param>
        /// <param name="token">The task's CancellationToken</param>
        private async Task InsertOrdersAsync(int taskId, CancellationToken token)
        {
            int size = this.BatchSize;
            int personId;
            var orderTable = new DataTable("Orders");
            var orderLinesTable = new DataTable("OrderLines");

            using (SqlConnection connection = new SqlConnection(this.sqlConnectionString))
            {
                await connection.OpenAsync(token);

                using (var insertCommand = connection.CreateCommand())
                {
                    insertCommand.CommandType = CommandType.StoredProcedure;
                    insertCommand.CommandTimeout = this.sqlCommandTimeout;
                    insertCommand.CommandText = this.sqlInsertSPName;
                    insertCommand.Parameters.Add("@Orders", SqlDbType.Structured);
                    insertCommand.Parameters.Add("@OrderLines", SqlDbType.Structured);
                    insertCommand.Parameters.Add("@OrdersCreatedByPersonID", SqlDbType.Int);
                    insertCommand.Parameters.Add("@SalespersonPersonID", SqlDbType.Int);

                    while (!token.IsCancellationRequested)
                    {
                        using (var selectCommand = connection.CreateCommand())
                        {
                            var da = new SqlDataAdapter(selectCommand);
                            var rnd = new Random();

                            personId = rnd.Next(1,1000); // Random person Id

                            // Get Order
                            selectCommand.CommandText = "SELECT TOP(1) 1 AS OrderReference, c.CustomerID, c.PrimaryContactPersonID AS ContactPersonID, CAST(DATEADD(day, 1, SYSDATETIME()) AS date) AS ExpectedDeliveryDate, CAST(FLOOR(RAND() * 10000) + 1 AS nvarchar(20)) AS CustomerPurchaseOrderNumber, CAST(0 AS bit) AS IsUndersupplyBackordered, N'Auto-generated' AS Comments, c.DeliveryAddressLine1 + N', ' + c.DeliveryAddressLine2 AS DeliveryInstructions FROM Sales.Customers AS c ORDER BY NEWID();";
                            orderTable = new DataTable("Orders");
                            da.Fill(orderTable);

                            // Get Order Lines
                            selectCommand.CommandText = "SELECT TOP(" + size + ") 1 AS OrderReference, si.StockItemID, si.StockItemName AS [Description], FLOOR(RAND() * 10) + 1 AS Quantity FROM Warehouse.StockItems AS si WHERE IsChillerStock = 0 ORDER BY NEWID()";
                            orderLinesTable = new DataTable("OrderLines");
                            da.Fill(orderLinesTable);
                        }

                        insertCommand.Parameters["@Orders"].Value = orderTable;
                        insertCommand.Parameters["@OrderLines"].Value = orderLinesTable;
                        insertCommand.Parameters["@OrdersCreatedByPersonID"].Value = personId;
                        insertCommand.Parameters["@SalespersonPersonID"].Value = personId;

                        await insertCommand.ExecuteNonQueryAsync(token);
                        Interlocked.Add(ref this.numberOfRowsInserted, size);
                        await Task.Delay(this.Delay, token);

                        orderTable.Clear();
                        orderLinesTable.Clear();
                    }
                }
            }
        }
        /// <summary>StopAsync(int numberOfTasksToStop)</summary>
        /// <returns>Task</returns>
        /// <param name="numberOfTasksToStop">The number of Tasks to stop.</param>
        private async Task StopAsync(int numberOfTasksToStop)
        {
            // TODO: Lock
            if (numberOfTasksToStop >= this.RunningTasks) { this.running = false; }

            numberOfTasksToStop = Math.Min(numberOfTasksToStop, this.RunningTasks);
            List<CancellableTask> cancellableTasksToKill = this.tasks.Take(numberOfTasksToStop).Select(kv => kv.Value).ToList();

            foreach (CancellableTask cancellableTask in cancellableTasksToKill)
            {
                cancellableTask.CancellationTokenSource.Cancel();
            }

            await Task.WhenAll(cancellableTasksToKill.Select(c => c.Task));
        }

        /// <summary>RunAsync(int numberOfTasks)</summary>
        /// <returns>Task</returns>
        /// <param name="numberOfTasks">The number of Tasks to start/stop depending of the number of tasks currently running.</param>
        private async Task RunAsync(int numberOfTasks)
        {
            for (int i = 0; i < numberOfTasks; i++)
            {
                CancellationTokenSource tokenSource = new CancellationTokenSource();
                int taskId = i;
                Task task = Task.Factory.StartNew(
                    async () => await this.InsertOrdersAsync(taskId, tokenSource.Token).ContinueWith(t => CleanupTask(taskId, t)),
                    tokenSource.Token,
                    TaskCreationOptions.LongRunning,
                    TaskScheduler.Default).Unwrap();

                tasks.TryAdd(taskId, new CancellableTask(taskId, task, tokenSource));
            }

            this.running = true;

            await Task.WhenAll(this.tasks.Values.Select(t => t.Task));
        }

        /// <summary>CleanupTask(int taskId, Task task)</summary>
        /// <returns>void</returns>
        /// <remarks></remarks>
        /// <param name="taskId">The taskId</param>
        /// <param name="task">The actual Task</param>
        private void CleanupTask(int taskId, Task task)
        {
            CancellableTask cancellableTask;
            bool succeeded = this.tasks.TryRemove(taskId, out cancellableTask);

            if (task.IsFaulted && !cancellableTask.CancellationTokenSource.IsCancellationRequested)
            {
                this.onException(taskId, task.Exception?.InnerException);
            }
        }

        /// <summary>Validate(int batchSize, int tasks, int delay)</summary>
        /// <param name="batchSize">The Batch Size</param>
        /// <param name="tasks">The number Of Tasks</param>
        /// <param name="delay">Teh Delay</param>
        private void Validate(int batchSize, int tasks, int delay)
        {
            // Validate
            if (batchSize <= 0)
            {
                throw new SqlDataGeneratorException("The Batch Size cannot be less or equal to zero.");
            }
            if (tasks <= 0)
            {
                throw new SqlDataGeneratorException("Number Of Tasks cannot be less or equal to zero.");
            }
            if (delay < 0)
            {
                throw new SqlDataGeneratorException("Delay cannot be less than zero");
            }

            // Reset Rps
            RpsReset();
        }
    }
}
