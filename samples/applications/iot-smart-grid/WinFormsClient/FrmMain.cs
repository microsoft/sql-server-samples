/*----------------------------------------------------------------------------------
Copyright (c) Microsoft Corporation. All rights reserved.

THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES
OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
----------------------------------------------------------------------------------
The example companies, organizations, products, domain names,
e-mail addresses, logos, people, places, and events depicted
herein are fictitious.  No association with any real company,
organization, product, domain name, email address, logo, person,
places, or events is intended or should be inferred.

*/

using DataGenerator;
using System;
using System.Configuration;
using System.Diagnostics;
using System.IO;
using System.Windows.Forms;
using System.Windows.Forms.DataVisualization.Charting;
using System.Data;
using System.Data.SqlClient;
using System.Threading.Tasks;

/*----------------------------------------------------------------------------------
High Level Scenario:
This code sample demonstrates how a SQL Server 2016 (or higher) memory optimized database could be used to ingest a very high input data rate
and ultimately help improve the performance of applications with this scenario. The code simulates an IoT Smart Grid scenario where multiple
IoT power meters are constantly sending electricity usage measurements to the database.

Details:
This code sample simulates an IoT Smart Grid scenario where multiple IoT power meters are sending electricity usage measurements to a SQL Server memory optimized database.
The Data Generator, that can be started either from the Console or the Windows Form client, produces a data generated spike to simulate a
shock absorber scenario: https://blogs.technet.microsoft.com/dataplatforminsider/2013/09/19/in-memory-oltp-common-design-pattern-high-data-input-rateshock-absorber/.
Every async task in the Data Generator produces a batch of records with random values in order to simulate the data of an IoT power meter.
It then calls a natively compiled stored procedure, that accepts an memory optimized table valued parameter (TVP), to insert the data into an memory optimized SQL Server table.
In addition to the in-memory features, the sample is offloading historical values to a Clustered Columnstore Index: https://msdn.microsoft.com/en-us/library/dn817827.aspx) for enabling real time operational analytics, and
Power BI: https://powerbi.microsoft.com/en-us/desktop/ for data visualization.
*/
namespace Client
{
    public partial class FrmMain : Form
    {
        private SqlDataGenerator dataGenerator;
        private string[] connection;
        private string spName;
        private string logFileName;
        private int numberOfDataLoadTasks;
        private int numberOfOffLoadTasks;

        private int meters;
        private int batchSize;
        private int deleteBatchSize;

        private string deleteSPName;
        private int dataLoadCommandDelay;
        private int offLoadCommandDelay;

        private int commandTimeout;
        private int rpsFrequency;
        private int rpsChartTime = 0;
        private int delayStart;
        private int appRunDuration;
        private int numberOfRowsOfloadLimit;

        public FrmMain()
        {
            InitializeComponent();
            Init();

            this.dataGenerator = new SqlDataGenerator(this.connection, this.spName, this.commandTimeout, this.meters, this.numberOfDataLoadTasks, this.dataLoadCommandDelay, this.batchSize, this.deleteSPName, this.numberOfOffLoadTasks, this.offLoadCommandDelay, this.deleteBatchSize, this.numberOfRowsOfloadLimit, this.ExceptionCallback);
            StartApp();
        }

        private void ExceptionCallback(int taskId, Exception exception)
        {
            HandleException(exception, taskId);
        }

        private void HandleException(Exception exception, int? taskId = null)
        {
            string ex = taskId?.ToString() + " - " + exception.Message + (exception.InnerException != null ? "\n\nInner Exception\n" + exception.InnerException : "");

            MessageBox.Show(ex, "Invalid Input Parameter", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
            ////using (StreamWriter w = File.AppendText(logFileName)) { w.WriteLine("\r\n{0}: {1}", DateTime.Now, ex); }
        }

        private async void StartApp()
        {
            if (!dataGenerator.IsRunning)
            {
                using (StreamWriter w = File.AppendText(logFileName)) { w.WriteLine("\r\n{0}: {1}", DateTime.Now, "Start"); }

                this.stopTimer.Start();
                this.Stop.Enabled = true;
                this.Stop.Update();
                this.dataGenerator.RunAsync();
                await Task.Delay(this.delayStart);
                this.rpsTimer.Start();
            }
        }
        private void StopApp()
        {
            if (dataGenerator.IsRunning)
            {
                using (StreamWriter w = File.AppendText(logFileName)) { w.WriteLine("\r\n{0}: {1}", DateTime.Now, "Stop - Successful run"); }

                this.UpdateChart(-1);
                this.rpsTimer.Stop();
                this.lblRpsValue.Text = "0";
                this.lblTasksValue.Text = "0";
                this.Stop.Enabled = false;
                this.Stop.Update();

                this.dataGenerator.StopAsync();
                this.dataGenerator.RpsReset();

                this.WindowState = FormWindowState.Minimized;
                //ResetDb();
            }
        }

        private void Stop_Click(object sender, EventArgs e)
        {
            try
            {
                StopApp();
                Application.Exit();
            }
            catch (Exception exception) { HandleException(exception); }
        }

        private void UpdateChart(double rps)
        {
            if (rps >= 0)
            {
                rpsChartTime++;

                if (rpsChartTime > this.RpsChart.ChartAreas[0].AxisX.Maximum)
                {
                    this.RpsChart.ChartAreas[0].AxisX.Maximum += 100;
                }
                this.RpsChart.Series[0].Points.Add(new DataPoint(rpsChartTime, rps));
            }
            else
            {
                this.RpsChart.Series[0].Points.Clear();
                rpsChartTime = 0;
            }
            this.RpsChart.Update();
        }

        private void Init()
        {
            try
            {
                int numberOfSqlConnections = ConfigurationManager.ConnectionStrings.Count;
                connection = new string[numberOfSqlConnections];
                // Read Config Settings
                for (int i = 0; i < numberOfSqlConnections; i++)
                {
                    connection[i] = ConfigurationManager.ConnectionStrings[i].ConnectionString;
                }

                this.spName = ConfigurationManager.AppSettings["insertSPName"];
                this.logFileName = ConfigurationManager.AppSettings["logFileName"];
                this.numberOfDataLoadTasks = int.Parse(ConfigurationManager.AppSettings["numberOfDataLoadTasks"]);
                this.dataLoadCommandDelay = int.Parse(ConfigurationManager.AppSettings["dataLoadCommandDelay"]);
                this.batchSize = int.Parse(ConfigurationManager.AppSettings["batchSize"]);

                this.deleteSPName = ConfigurationManager.AppSettings["deleteSPName"];
                this.numberOfOffLoadTasks = int.Parse(ConfigurationManager.AppSettings["numberOfOffLoadTasks"]);
                this.offLoadCommandDelay = int.Parse(ConfigurationManager.AppSettings["offLoadCommandDelay"]);
                this.deleteBatchSize = int.Parse(ConfigurationManager.AppSettings["deleteBatchSize"]);

                this.meters = int.Parse(ConfigurationManager.AppSettings["numberOfMeters"]);

                this.commandTimeout = int.Parse(ConfigurationManager.AppSettings["commandTimeout"]);
                this.delayStart = int.Parse(ConfigurationManager.AppSettings["delayStart"]);
                this.appRunDuration = int.Parse(ConfigurationManager.AppSettings["appRunDuration"]);
                this.rpsFrequency = int.Parse(ConfigurationManager.AppSettings["rpsFrequency"]);
                numberOfRowsOfloadLimit = int.Parse(ConfigurationManager.AppSettings["numberOfRowsOfloadLimit"]);

                // Initialize Timers
                this.rpsTimer.Interval = this.rpsFrequency;
                this.stopTimer.Interval = this.appRunDuration;

                // Initialize Labels
                this.lblTasksValue.Text = string.Format("{0:#,#}", this.numberOfDataLoadTasks).ToString();

                if (batchSize <= 0) throw new SqlDataGeneratorException("The Batch Size cannot be less or equal to zero.");

                if (numberOfDataLoadTasks <= 0) throw new SqlDataGeneratorException("Number Of Tasks cannot be less or equal to zero.");

                if (dataLoadCommandDelay < 0) throw new SqlDataGeneratorException("Delay cannot be less than zero");

                if (meters <= 0) throw new SqlDataGeneratorException("Number Of Meters cannot be less than zero");

                if (meters < batchSize * numberOfDataLoadTasks) throw new SqlDataGeneratorException("Number Of Meters cannot be less than (Tasks * BatchSize).");

            }
            catch (Exception exception) { HandleException(exception); }
        }

        private void rpsTimer_Tick(object sender, EventArgs e)
        {
            try
            {
                this.lblTasksValue.Text = this.dataGenerator.RunningTasks.ToString();

                double rps = this.dataGenerator.Rps;
                if (dataGenerator.IsRunning)
                {
                    if (this.dataGenerator.RunningTasks == 0) return;

                    if (rps > 0)
                    {
                        this.lblRpsValue.Text = string.Format("{0:#,#}", rps).ToString();
                        UpdateChart(rps);
                    }
                }
            }
            catch (Exception exception) { HandleException(exception); }
        }
        private void ResetDb()
        {
            try
            {
                this.Stop.Text = "Stopping...";
                this.Stop.Update();

                string script = File.ReadAllText(@"setup-or-reset-demo.sql");

                int numberOfSqlConnections = ConfigurationManager.ConnectionStrings.Count;
                for (int i = 0; i < numberOfSqlConnections; i++)
                {
                    using (SqlConnection connection = new SqlConnection(ConfigurationManager.ConnectionStrings[i].ConnectionString))
                    {
                        connection.Open();

                        using (SqlCommand command = new SqlCommand())
                        {
                            command.Connection = connection;
                            command.CommandType = CommandType.Text;
                            command.CommandTimeout = 1800;
                            command.CommandText = script;
                            command.ExecuteNonQuery();
                        }
                    }
                }
            }
            catch (Exception exception) { HandleException(exception); }
            finally
            {
                this.Stop.Text = "Close";
                this.Stop.Update();
            }
        }

        private void stopTimer_Tick(object sender, EventArgs e)
        {
            try
            {
                StopApp();
                Application.Exit();
            }
            catch (Exception exception) { HandleException(exception); }
        }

        private void RpsChart_Click(object sender, EventArgs e)
        {
            StartApp();
        }
    }
}
