using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Data.SqlClient;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace MultithreadedInMemoryTableInsert
{
    public partial class MultithreadedOrderInsertMain : Form
    {
        public bool errorHasOccurred;
        public string errorDetails;

        private Thread[] sqlTasks;
        private Int64 totalOrders;
        private Int64 totalMilliseconds;

        public MultithreadedOrderInsertMain()
        {
            InitializeComponent();
        }

        private void MultithreadedOrderInsertMain_Load(object sender, EventArgs e)
        {
            ConnectionStringTextBox.Text = MultithreadedOrderInsert.Properties.Settings.Default.WWI_ConnectionString;
            if (ConnectionStringTextBox.Text.Length == 0)
            {
                ConnectionStringTextBox.Text = "Server=.;Database=WideWorldImporters;Integrated Security=true;Column Encryption Setting=disabled;Max Pool Size=250;";
            }
        }

        private void MultithreadedOrderInsertMain_FormClosing(object sender, FormClosingEventArgs e)
        {
            MultithreadedOrderInsert.Properties.Settings.Default.WWI_ConnectionString = ConnectionStringTextBox.Text;
            MultithreadedOrderInsert.Properties.Settings.Default.Save();
        }

        public void UpdateTotals(int MillisecondsForOrder)
        {
            lock (this)
            {
                this.totalOrders += 1;
                this.totalMilliseconds += MillisecondsForOrder;
            }
        }

        private void InsertButton_Click(object sender, EventArgs e)
        {
            if (InsertButton.Text == "&Insert")
            {
                InsertButton.Text = "&Stop Now";
                InsertButton.Refresh();
                this.Refresh();

                DisplayUpdateTimer.Enabled = true;

                this.errorHasOccurred = false;
                this.errorDetails = "";

                this.totalOrders = 0;
                this.totalMilliseconds = 0;

                if (ConnectionStringTextBox.Text.Length == 0)
                {
                    ConnectionStringTextBox.Text = "Server=.;Database=WideWorldImporters;Integrated Security=true;Column Encryption Setting=disabled;Max Pool Size=250;";
                }

                if (!ConnectionStringTextBox.Text.ToUpper().Contains("MAX POOL SIZE"))
                {
                    ConnectionStringTextBox.Text = (ConnectionStringTextBox.Text + ";Max Pool Size=250;").Replace(";;", ";");
                }

                try
                {
                    int numberOfThreads = (int)NumberOfThreadsNumericUpDown.Value;

                    sqlTasks = new Thread[numberOfThreads];

                    for (int threadCounter = 0; threadCounter < numberOfThreads; threadCounter++)
                    {
                        sqlTasks[threadCounter] = new System.Threading.Thread(() => PerformSqlTask(threadCounter, this));
                        sqlTasks[threadCounter].Start();
                    }

                }
                catch (Exception ex)
                {
                    this.errorHasOccurred = true;
                    this.errorDetails = ex.ToString();
                }

                if (this.errorHasOccurred)
                {
                    var errorForm = new ErrorDetailsForm();
                    errorForm.ErrorMessage = this.errorDetails;
                    errorForm.ShowDialog();
                }
            }
            else
            {
                InsertButton.Text = "Stopping";
                InsertButton.Refresh();
                this.Refresh();

                DisplayUpdateTimer.Enabled = false;

                if (sqlTasks != null)
                {
                    foreach (Thread thread in sqlTasks)
                    {
                        thread.Abort();
                    }
                }

                InsertButton.Text = "&Insert";
            }
        }

        public void PerformSqlTask(int TaskNumber, MultithreadedOrderInsertMain ParentForm)
        {
            var errorOccurred = false;

            while (!errorOccurred)
            {
                try
                {
                    using (var con = new SqlConnection(ConnectionStringTextBox.Text))
                    {
                        var startingTime = DateTime.Now;

                        con.Open();

                        using (var selectCommand = con.CreateCommand())
                        {
                            var da = new SqlDataAdapter(selectCommand);
                            var rnd = new Random(TaskNumber);

                            selectCommand.CommandText = "SELECT TOP(1) PersonID FROM [Application].People WHERE IsEmployee <> 0 ORDER BY NEWID();";
                            var personTable = new DataTable("Person");
                            da.Fill(personTable);

                            var salespersonID = (int)(personTable.Rows[0]["PersonID"]);

                            selectCommand.CommandText = "SELECT TOP(1) 1 AS OrderReference, c.CustomerID, c.PrimaryContactPersonID AS ContactPersonID, CAST(DATEADD(day, 1, SYSDATETIME()) AS date) AS ExpectedDeliveryDate, CAST(FLOOR(RAND() * 10000) + 1 AS nvarchar(20)) AS CustomerPurchaseOrderNumber, CAST(0 AS bit) AS IsUndersupplyBackordered, N'Auto-generated' AS Comments, c.DeliveryAddressLine1 + N', ' + c.DeliveryAddressLine2 AS DeliveryInstructions FROM Sales.Customers AS c ORDER BY NEWID();";
                            var orderTable = new DataTable("Orders");
                            da.Fill(orderTable);

                            selectCommand.CommandText = "SELECT * FROM (SELECT TOP(7) 1 AS OrderReference, si.StockItemID, si.StockItemName AS [Description], FLOOR(RAND() * 10) + 1 AS Quantity FROM Warehouse.StockItems AS si WHERE IsChillerStock = 0 ORDER BY NEWID()) x";
                            if (rnd.Next(1, 100) < 4)
                            {
                                selectCommand.CommandText += " UNION ALL SELECT * FROM (SELECT TOP(1) 1 AS OrderReference, si.StockItemID, si.StockItemName AS [Description], FLOOR(RAND() * 10) + 1 AS Quantity FROM Warehouse.StockItems AS si WHERE IsChillerStock <> 0 ORDER BY NEWID()) x";
                            }
                            selectCommand.CommandText += ";";
                            var orderLinesTable = new DataTable("OrderLines");
                            da.Fill(orderLinesTable);

                            using (var insertCommand = con.CreateCommand())
                            {
                                insertCommand.CommandType = CommandType.StoredProcedure;
                                insertCommand.CommandText = "Website.InsertCustomerOrders";

                                var orderList = new SqlParameter("@Orders", SqlDbType.Structured);
                                orderList.TypeName = "Website.OrderList";
                                orderList.Value = orderTable;
                                insertCommand.Parameters.Add(orderList);

                                var orderLineList = new SqlParameter("@OrderLines", SqlDbType.Structured);
                                orderLineList.TypeName = "Website.OrderLineList";
                                orderLineList.Value = orderLinesTable;
                                insertCommand.Parameters.Add(orderLineList);

                                var ordersCreatedByPersonID = new SqlParameter("@OrdersCreatedByPersonID", SqlDbType.Int);
                                ordersCreatedByPersonID.Value = salespersonID;
                                insertCommand.Parameters.Add(ordersCreatedByPersonID);

                                var salespersonPersonID = new SqlParameter("@SalespersonPersonID", SqlDbType.Int);
                                salespersonPersonID.Value = salespersonID;
                                insertCommand.Parameters.Add(salespersonPersonID);

                                insertCommand.ExecuteNonQuery();
                            }
                        }
                        con.Close();

                        ParentForm.UpdateTotals((int) DateTime.Now.Subtract(startingTime).TotalMilliseconds);
                    }
                }
                catch (Exception ex)
                {
                    errorOccurred = true;
                    ParentForm.errorHasOccurred = true;
                    ParentForm.errorDetails = ex.ToString();
                }
            }
        }

        private void DisplayUpdateTimer_Tick(object sender, EventArgs e)
        {
            if (this.totalOrders > 0)
            {
                AverageOrderInsertionTimeTextBox.Text = (totalMilliseconds / totalOrders).ToString();
                AverageOrderInsertionTimeTextBox.Refresh();
                this.Refresh();
            }
        }
    }
}

