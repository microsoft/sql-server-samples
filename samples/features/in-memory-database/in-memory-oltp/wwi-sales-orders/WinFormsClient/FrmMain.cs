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

namespace Client
{
    public partial class FrmMain : Form
    {
        private SqlDataGenerator dataGenerator;
        private string connection;
        private string spName;
        private string logFileName;
        private int tasks;
        private int batchSize;
        private int delay;
        private int commandTimeout;
        private int rpsFrequency;
        private int rpsChartTime = 0;

        public FrmMain()
        {
            InitializeComponent();
        }

        private void ExceptionCallback(int taskId, Exception exception)
        {
            HandleException(exception, taskId);
        }

        private void HandleException(Exception exception, int? taskId = null)
        {
            // Uncomment for debugging
            string ex = taskId?.ToString() + " - " + exception.Message + (exception.InnerException != null ? "\n\nInner Exception\n" + exception.InnerException : "");
            using (StreamWriter w = File.AppendText(logFileName)) { w.WriteLine("\r\n{0}: {1}", DateTime.Now, ex); }
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

                this.OnDiskRadioButton.Enabled = false;
                this.InMemoryRadioButton.Enabled = false;
                this.InMemoryWithCSIRadioButton.Enabled = false;

                Init();

                await this.dataGenerator.RunAsync();
            }
            catch (Exception exception) { HandleException(exception); }
        }

        private async void Stop_Click(object sender, EventArgs e)
        {
            try
            {
                //this.UpdateChart(-1);
                this.rpsTimer.Stop();
                //this.lblRpsValue.Text = "0";
                //this.lblTasksValue.Text = "0";
                this.Stop.Enabled = false;
                this.Stop.Update();
                this.Start.Enabled = true;
                this.Start.Update();
                this.OnDiskRadioButton.Enabled = true;
                this.InMemoryRadioButton.Enabled = true;
                this.InMemoryWithCSIRadioButton.Enabled = true;

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

                if (OnDiskRadioButton.Checked)
                {
                    this.spName = ConfigurationManager.AppSettings["sqlOndiskSPName"];

                }
                else if (InMemoryRadioButton.Checked)
                {
                    this.spName = ConfigurationManager.AppSettings["sqlInMemorySPName"];
                }
                else
                {
                    this.spName = ConfigurationManager.AppSettings["sqlInMemoryWithCCISPName"];
                }

                this.logFileName = ConfigurationManager.AppSettings["logFileName"];
                this.tasks = int.Parse(ConfigurationManager.AppSettings["numberOfTasks"]);
                this.batchSize = int.Parse(ConfigurationManager.AppSettings["batchSize"]);
                this.delay = int.Parse(ConfigurationManager.AppSettings["commandDelay"]);
                this.commandTimeout = int.Parse(ConfigurationManager.AppSettings["commandTimeout"]);
                this.rpsFrequency = int.Parse(ConfigurationManager.AppSettings["rpsFrequency"]);

                this.dataGenerator = new SqlDataGenerator(this.connection, this.spName, this.commandTimeout, this.tasks, this.delay, this.batchSize, this.ExceptionCallback);

                // Initialize Timers
                this.rpsTimer.Interval = this.rpsFrequency;

                // Initialize Labels
                this.lblTasksValue.Text = string.Format("{0:#,#}", this.tasks).ToString();
                this.lblBatchSizeValue.Text = string.Format("{0:#,#}", this.batchSize).ToString();

                if (batchSize <= 0) throw new SqlDataGeneratorException("The Batch Size cannot be less or equal to zero.");

                if (tasks <= 0) throw new SqlDataGeneratorException("Number Of Tasks cannot be less or equal to zero.");

                if (delay < 0) throw new SqlDataGeneratorException("Delay cannot be less than zero");


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
    }
}
