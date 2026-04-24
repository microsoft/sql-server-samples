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

/*----------------------------------------------------------------------------------
High Level Scenario:
This code sample demonstrates how a SQL Server 2016 (or higher) memory optimized database could be used to ingest a very high input data rate
and ultimately help improve the performance of applications with this scenario. The code simulates an IoT Connected car scenario where multiple
IoT telemetry data are constantly sending car events to the Azure SQL database.
*/
namespace Client
{
    public partial class FrmMain : Form
    {
        private SqlDataGenerator dataGenerator;
        private string connection;
        private string spName;
        private string logFileName;
        private int tasks;
        private int cars;
        private int batchSize;
        private int delay;
        private int commandTimeout;
        private int rpsFrequency;
        private int rpsChartTime = 0;
        private int enableShock;

        public FrmMain()
        {
            InitializeComponent();
            Init();

            this.dataGenerator = new SqlDataGenerator(this.connection, this.spName, this.commandTimeout, this.cars, this.tasks, this.delay, this.batchSize, this.ExceptionCallback);
        }

        private void ExceptionCallback(int taskId, Exception exception)
        {
            HandleException(exception, taskId);
        }

        private void HandleException(Exception exception, int? taskId = null)
        {
            //string ex = taskId?.ToString() + " - " + exception.Message + (exception.InnerException != null ? "\n\nInner Exception\n" + exception.InnerException : "");

            //MessageBox.Show(ex, "Invalid Input Parameter", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
            //using (StreamWriter w = File.AppendText(logFileName)) { w.WriteLine("\r\n{0}: {1}", DateTime.Now, ex); }
        }

        private async void Start_Click(object sender, EventArgs e)
        {
            try
            {
                this.rpsTimer.Start();
                this.Stop.Enabled = true;
                this.Stop.Update();
                this.Start.Enabled = false;
                this.Start.Update();
                this.Reset.Enabled = false;
                this.Reset.Update();

                await this.dataGenerator.RunAsync();
            }
            catch (Exception exception) { HandleException(exception); }
        }

        private async void Stop_Click(object sender, EventArgs e)
        {
            try
            {
                this.UpdateChart(-1);
                this.rpsTimer.Stop();
                this.lblRpsValue.Text = "0";
                this.lblTasksValue.Text = "0";
                this.Stop.Enabled = false;
                this.Stop.Update();
                this.Start.Enabled = true;
                this.Start.Update();
                this.Reset.Enabled = true;
                this.Reset.Update();

                await this.dataGenerator.StopAsync();
                this.dataGenerator.RpsReset();
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
                // Read Config Settings
                this.connection = ConfigurationManager.ConnectionStrings["Db"].ConnectionString;
                this.spName = ConfigurationManager.AppSettings["insertSPName"];
                this.logFileName = ConfigurationManager.AppSettings["logFileName"];
                this.tasks = int.Parse(ConfigurationManager.AppSettings["numberOfTasks"]);
                this.cars = int.Parse(ConfigurationManager.AppSettings["numberOfCars"]);
                this.batchSize = int.Parse(ConfigurationManager.AppSettings["batchSize"]);
                this.delay = int.Parse(ConfigurationManager.AppSettings["commandDelay"]);
                this.commandTimeout = int.Parse(ConfigurationManager.AppSettings["commandTimeout"]);
                this.enableShock = int.Parse(ConfigurationManager.AppSettings["enableShock"]);

                this.rpsFrequency = int.Parse(ConfigurationManager.AppSettings["rpsFrequency"]);

                // Initialize Timers
                this.rpsTimer.Interval = this.rpsFrequency;

                // Initialize Labels
                this.lblTasksValue.Text = string.Format("{0:#,#}", this.tasks).ToString();
                this.lblBatchSizeValue.Text = string.Format("{0:#,#}", this.batchSize).ToString();
                this.lblMetersValue.Text = string.Format("{0:#,#}", this.cars).ToString();

                if (batchSize <= 0) throw new SqlDataGeneratorException("The Batch Size cannot be less or equal to zero.");

                if (tasks <= 0) throw new SqlDataGeneratorException("Number Of Tasks cannot be less or equal to zero.");

                if (delay < 0) throw new SqlDataGeneratorException("Delay cannot be less than zero");

                if (cars <= 0) throw new SqlDataGeneratorException("Number Of Meters cannot be less than zero");

                if (cars < batchSize * tasks) throw new SqlDataGeneratorException("Number Of Meters cannot be less than (Tasks * BatchSize).");
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

        private void Reset_Click(object sender, EventArgs e)
        {
            try
            {
                this.Reset.Text = "Executing...";
                this.Reset.Update();

                string script = File.ReadAllText(@"setup_reset.sql");

                using (SqlConnection connection = new SqlConnection(this.connection))
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
            catch (Exception exception) {HandleException(exception); }
            finally
            {
                this.Reset.Text = "Setup/Reset DB";
                this.Reset.Update();
            }

        }
    }
}
