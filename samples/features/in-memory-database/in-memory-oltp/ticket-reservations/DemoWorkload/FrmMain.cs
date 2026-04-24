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
using System.Data;
using System.Data.SqlClient;
using System.Diagnostics;
using System.Linq;
using System.Threading;
using System.Windows.Forms;
using System.Windows.Forms.DataVisualization.Charting;
using System.Windows.Forms.Integration;

/// <summary>
///
/// Documentation References:
/// In-Memory OLTP (In-Memory Optimization): https://msdn.microsoft.com/en-us/library/dn133186.aspx
/// OLTP and database management: https://www.microsoft.com/en-us/server-cloud/solutions/oltp-database-management.aspx
/// </summary>
///

namespace DemoWorkload
{
    public partial class FrmMain : Form
    {
        delegate void SetTextCallback(string text);

        public Object ErrorLock = new Object();
        public Object StopLock = new Object();

        List<Thread> RunningThreads = new List<Thread>();
        Thread MonitorThread;

        bool Stopped = true;
        long BaselineTPS = 1;
        int Height_2Panels = 0;
        int Height_1Panel = 0;
        int TPSChartTime = 0;

        UIControls uiControls = new UIControls();

        public FrmMain()
        {
            InitializeComponent();
            uiControls.speedDial.MaxValue = Program.MAX_TPS;
        }

        delegate void SetInt64Callback(Int64 value);
        delegate void SetIntCallback(int value);

        /// <summary>
        /// Adds a line of text into the message box
        /// </summary>
        private void AddText(string text)
        {
            // InvokeRequired required compares the thread ID of the
            // calling thread to the thread ID of the creating thread.
            // If these threads are different, it returns true.
            if (this.ErrorMessages.InvokeRequired)
            {
                SetTextCallback d = new SetTextCallback(AddText);
                this.Invoke(d, new object[] { text });
            }
            else
            {
                this.ErrorMessages.AppendText("\r\n" + text);
            }

        }
        /// <summary>
        /// Updates the thread count display
        /// </summary>
        private void UpdateCount(string TC)
        {
            try { this.lblThreads.Text = TC.ToString(); }
            catch (Exception ex) { ShowThreadExceptionDialog("UpdateCount", ex); }
        }

        /// <summary>
        /// Updates the elapsed time display
        /// </summary>
        private void UpdateElapsed(string Elapsed)
        {
            this.lblTime.Text = Elapsed.ToString();
        }

        /// <summary>
        /// Updates the CPU% bar in the chart
        /// Note that this proc does NOT cause the chart to refresh.
        /// that is done in UpdateTPS(), which should be called after this proc.
        /// </summary>
        private void UpdateCPUChart(int CPU)
        {
            try {
                if (this.statusStrip1.InvokeRequired)
                {
                    SetIntCallback d = new SetIntCallback(UpdateCPUChart);
                    this.Invoke(d, new object[] { CPU });
                }
                else
                {
                    CPU = (CPU == 0) ? 1 : CPU;
                    this.chtCPU.Series["CPUUsage"].Points.Clear();
                    this.chtCPU.Series["CPUUsage"].Points.Add(new DataPoint(0, CPU));
                    this.chtCPU.Update();
                }
            }
            catch (Exception ex) { ShowThreadExceptionDialog("UpdateCPUChart", ex); }
        }

        /// <summary>
        /// Updates Latches in the Chart
        /// </summary>
        private void UpdateLatchChart(Int64 Latches)
        {
            try {
                if (this.statusStrip1.InvokeRequired)
                {
                    SetInt64Callback d = new SetInt64Callback(UpdateLatchChart);
                    this.Invoke(d, new object[] { Latches });
                }
                else
                {
                    Latches = (Latches == 0) ? 1 : Latches;
                    this.chtLatches.Series["Latches"].Points.Clear();
                    this.chtLatches.Series["Latches"].Points.Add(new DataPoint(0, Latches));
                    this.chtLatches.Update();
                }
            }
            catch (Exception ex) { ShowThreadExceptionDialog("UpdateLatchChart", ex); }
        }

        /// <summary>
        /// Updates the TPS bar in the chart, and causes the whole chart to be re-drawn with the new data.
        /// </summary>
        private void UpdateTPSChart(Int64 TPS)
        {
            try {
                if (this.statusStrip1.InvokeRequired)
                {
                    SetInt64Callback d = new SetInt64Callback(UpdateTPSChart);
                    this.Invoke(d, new object[] { TPS });
                }
                else
                {
                    // Updating Speedometer
                    if (TPS >= 0)
                    {
                        double normalizedTPS = (double)TPS / 1000;
                        uiControls.speedDial.CurrentValue = normalizedTPS;
                        uiControls.speedDial.DialText = normalizedTPS.ToString("#.##");

                        // Updating TPS chart
                        TPSChartTime++;

                        // X Axis Overflow
                        if (TPSChartTime > this.chtTPS.ChartAreas[0].AxisX.Maximum)
                        {
                            this.chtTPS.ChartAreas[0].AxisX.Maximum += 100;
                        }

                        this.chtTPS.Series[0].Points.Add(new System.Windows.Forms.DataVisualization.Charting.DataPoint(TPSChartTime, TPS));
                    }
                    else
                    {
                        this.chtTPS.Series[0].Points.Clear();
                        TPSChartTime = 0;
                    }
                    this.chtTPS.Update();
                }
            }
            catch (Exception ex) { ShowThreadExceptionDialog("UpdateTPSChart", ex); }
        }

        /// <summary>
        /// Updates Results
        /// </summary>
        private void UpdateResults(string Results)
        {
            try
            {
                lock (StopLock)
                {
                    if (Stopped)
                    {
                        return;
                    }
                }
                if (this.statusStrip1.InvokeRequired)
                {
                    SetTextCallback d = new SetTextCallback(UpdateResults);
                    this.Invoke(d, new object[] { Results });
                }
                else
                {
                    this.lbResults.Text = Results;
                    this.lbResults.Refresh();
                }
            }
            catch (Exception ex) { ShowThreadExceptionDialog("UpdateResults", ex); }
        }

        /// <summary>
        /// Executes Write/Read Commands
        /// </summary>
        void OnRunClick(object sender, EventArgs e)
        {
            try
            {
                string ReadCommand;
                string WriteCommand;
                lock (StopLock)
                {
                    Stopped = false;
                }

                WriteCommand = "EXEC BatchInsertReservations @ServerTransactions, @RowsPerTransaction, @ThreadID";
                ReadCommand = "EXEC ReadMultipleReservations @ServerTransactions, @RowsPerTransaction, @ThreadID";
                this.ErrorMessages.Clear();

                ThreadParams tp = new ThreadParams(Program.REQUEST_COUNT, Program.TRANSACTION_COUNT, Program.ROW_COUNT,
                    Program.READS_PER_WRITE, ReadCommand, WriteCommand);
                for (int j = 0; j < Program.THREAD_COUNT; j++)
                {
                    int Threads = RunningThreads.Count();
                    // Create a thread with parameters.
                    ParameterizedThreadStart pts = new ParameterizedThreadStart(ThreadWorker);
                    RunningThreads.Add(new Thread(pts));
                    RunningThreads.ElementAt(Threads).Start(tp);
                }
                ThreadStart ts1 = new ThreadStart(ThreadMonitor);
                this.MonitorThread = new Thread(ts1);
                this.MonitorThread.Start();
            }
            catch (Exception ex) { ShowThreadExceptionDialog("OnRunClick", ex); }
        }

        /// <summary>
        /// Executes Transactions on the target server
        /// </summary>
        void ThreadWorker(object tp)
        {
            ////////////////////////////////////////////////////////////////////////////////
            // Connect to the data source.
            ////////////////////////////////////////////////////////////////////////////////

            System.Data.SqlClient.SqlConnection conn = new SqlConnection(Program.CONN_STR);

            ThreadParams MyTP = (ThreadParams)tp;
            SqlCommand WriteCmd = new SqlCommand();
            WriteCmd.Connection = conn;
            WriteCmd.CommandTimeout = 600;
            WriteCmd.CommandText = MyTP.WriteCommandText;
            WriteCmd.Parameters.Add("@ServerTransactions", SqlDbType.Int, 4).Value = (int)MyTP.serverTransactions;
            WriteCmd.Parameters.Add("@RowsPerTransaction", SqlDbType.Int, 4).Value = (int)MyTP.rowsPerTransaction;
            WriteCmd.Parameters.Add("@ThreadID", SqlDbType.Int, 4).Value = (int)Thread.CurrentThread.ManagedThreadId;

            SqlCommand ReadCmd = new SqlCommand();
            ReadCmd.Connection = conn;
            ReadCmd.CommandTimeout = 600;
            ReadCmd.CommandText = MyTP.ReadCommandText;
            ReadCmd.Parameters.Add("@ServerTransactions", SqlDbType.Int, 4).Value = (int)MyTP.serverTransactions;
            ReadCmd.Parameters.Add("@RowsPerTransaction", SqlDbType.Int, 4).Value = (int)MyTP.rowsPerTransaction;
            ReadCmd.Parameters.Add("@ThreadID", SqlDbType.Int, 4).Value = (int)Thread.CurrentThread.ManagedThreadId;

            // Executing transactions on the target server
            try
            {
                conn.Open();
                for (int i = 0; i < MyTP.requestsPerThread; i++)
                {
                    lock (StopLock)
                    {
                        if (Stopped)
                        {
                            break;
                        }
                    }
                    WriteCmd.ExecuteNonQuery();
                    for (int j = 0; j < MyTP.readsPerWrite && !Stopped; j++)
                    {
                        ReadCmd.ExecuteNonQuery();
                    }
                }
            }
            catch (Exception ex)
            {
                lock (this.ErrorLock)
                {
                    this.AddText(ex.Message + " " + Thread.CurrentThread.ManagedThreadId.ToString());
                }
            }
            finally
            {
                conn.Close();
            }
        }

        /// <summary>
        /// Thread Monitor
        /// </summary>
        void ThreadMonitor()
        {
            //Set-up & initialization
            DateTime Start = DateTime.Now;
            DateTime PerfCounterStart = DateTime.Now, PerfCounterEnd;
            Int64 LastPerfCounterValue = 0, ThisPerfCounterValue = 0, TPS = 0;
            Int64 LatchCounterValue = 0, LastLatchCounter = 0, ThisLatchCounter = 0;
            int CPU_Usage = 0;
            int mo_tables = 0;
            PerformanceCounter CPUCounter = new PerformanceCounter("Processor", "% Processor Time", "_Total");
            Int64 TotalTPS = 0, TotalIterations = 0;

            // Open the connection
            System.Data.SqlClient.SqlConnection conn = new SqlConnection(Program.CONN_STR);

            string cmdStr = string.Format("select max(cntr_value) FROM sys.dm_os_performance_counters WHERE counter_name = 'Transactions/sec'");

            string LatchcmdStr = string.Format("select max(cntr_value) FROM sys.dm_os_performance_counters WHERE counter_name = 'Latch Waits/sec'");
            SqlCommand Perfcmd = new SqlCommand();
            Perfcmd.Connection = conn;
            Perfcmd.CommandTimeout = 600;
            Perfcmd.CommandText = cmdStr;

            //query to determine which stage we're in
            SqlCommand Latchcmd = new SqlCommand();
            Latchcmd.Connection = conn;
            Latchcmd.CommandTimeout = 600;
            Latchcmd.CommandText = LatchcmdStr;
            string ConfigSelect = string.Format("select count(*) from sys.tables where is_memory_optimized = 1 and object_id=object_id('dbo.TicketReservationDetail')");

            SqlCommand ConfigQuery = new SqlCommand();
            ConfigQuery.Connection = conn;
            ConfigQuery.CommandTimeout = 600;
            ConfigQuery.CommandText = ConfigSelect;

            try
            {
                conn.Open();
            }
            catch (Exception ex)
            {
                lock (this.ErrorLock)
                {
                    this.AddText(ex.Message + " " + Thread.CurrentThread.ManagedThreadId.ToString());
                }
            }

            if (conn.State != ConnectionState.Open)
            {
                MessageBox.Show("Monitor failed to connect to server.", "Error", MessageBoxButtons.OK);
                return;
            }

            mo_tables = (int)ConfigQuery.ExecuteScalar();
            if (mo_tables == 0)
            {
                //This is the case where there are no Memory Optimized tables, so we're running in pure SQL mode.
                UpdateResults("Baseline");
                //Calling UpdateTPSChart with a negative value causes it to clear the current chart and reset.
                UpdateTPSChart(-1);
            }
            else
            {
                UpdateResults("");
            }

            while (RunningThreads.Count > 0)
            {
                List<Thread> DeadThreads = new List<Thread>();
                foreach (Thread MyThread in RunningThreads)
                {
                    if (!MyThread.IsAlive)
                    {
                        DeadThreads.Add(MyThread);
                    }
                }
                foreach (Thread DThread in DeadThreads)
                {
                    RunningThreads.Remove(DThread);
                }
                DeadThreads.Clear();
                PerfCounterEnd = DateTime.Now;

                try
                {
                    ThisPerfCounterValue = (Int64)Perfcmd.ExecuteScalar();
                    ThisLatchCounter = (Int64)Latchcmd.ExecuteScalar();
                }
                catch (Exception ex)
                {
                    lock (this.ErrorLock)
                    {
                        this.AddText(ex.Message + " " + Thread.CurrentThread.ManagedThreadId.ToString());
                    }
                }

                if (LastLatchCounter == 0)
                {
                    LastLatchCounter = ThisLatchCounter;
                }

                if (LastPerfCounterValue != 0)
                {
                    CPU_Usage = (int)CPUCounter.NextValue();

                    TimeSpan PerfCounterInterval = PerfCounterEnd - PerfCounterStart;
                    if (PerfCounterInterval.Milliseconds > 0)
                    {
                        TPS = (Int64)((ThisPerfCounterValue - LastPerfCounterValue) / (float)(PerfCounterInterval.Seconds + (PerfCounterInterval.Milliseconds / 1000)));
                        LatchCounterValue = (Int64)((ThisLatchCounter - LastLatchCounter) / (float)(PerfCounterInterval.Seconds + (PerfCounterInterval.Milliseconds / 1000)));
                        UpdateCPUChart(CPU_Usage);
                        UpdateLatchChart(LatchCounterValue);
                        UpdateTPSChart(TPS);
                    }
                    if (mo_tables == 0)
                    {
                        TotalTPS += TPS;
                        TotalIterations += 1;
                        BaselineTPS = TotalTPS / TotalIterations;
                    }
                    else
                    {
                        string UpdateString = string.Format("{0}X", TPS / BaselineTPS);
                        UpdateResults(UpdateString);
                    }
                }

                PerfCounterStart = PerfCounterEnd;
                LastPerfCounterValue = ThisPerfCounterValue;
                LastLatchCounter = ThisLatchCounter;
                PerfCounterStart = PerfCounterEnd;
                this.UpdateCount(RunningThreads.Count.ToString());
                Thread.Sleep(1000);
                TimeSpan Elapsed = DateTime.Now - Start;
                UpdateElapsed(Elapsed.ToString(@"hh\:mm\:ss"));
            }

            TPS = 0;
            CPU_Usage = 0;
            LatchCounterValue = 0;
            UpdateLatchChart(LatchCounterValue);
            UpdateCPUChart(CPU_Usage);
            UpdateTPSChart(TPS);
        }

        /// <summary>
        /// Stop Button
        /// </summary>
        private void btnStop_Click(object sender, EventArgs e)
        {
            lock (StopLock)
            {
                Stopped = true;
            }
        }
        /// <summary>
        /// Application Exit
        /// </summary>
        private void exitToolStripMenuItem_Click(object sender, EventArgs e)
        {
            Application.Exit();
        }

        /// <summary>
        /// Configuratino Settings
        /// </summary>
        private void configurationToolStripMenuItem_Click(object sender, EventArgs e)
        {
            try
            {
                FrmConfig cf = new FrmConfig();
                cf.ShowDialog();
                uiControls.speedDial.MaxValue = Program.MAX_TPS;
            }
            catch (Exception ex) { ShowThreadExceptionDialog("configurationToolStripMenuItem_Click", ex); }
        }

        /// <summary>
        /// Show Diagnostics
        /// </summary>
        private void btnToggle_Click(object sender, EventArgs e)
        {
            try
            {
                splitContainer1.Panel2Collapsed = !splitContainer1.Panel2Collapsed;
                if (splitContainer1.Panel2Collapsed)
                {
                    this.Height = this.Height_1Panel;
                    btnToggle.Text = "Show diagnostics";
                }
                else
                {
                    this.Height = this.Height_2Panels;
                    btnToggle.Text = "Hide diagnostics";
                }
            }
            catch (Exception ex) { ShowThreadExceptionDialog("btnToggle_Click", ex); }
        }

        /// <summary>
        /// Frm Main Load
        /// </summary>
        private void FrmMain_Load(object sender, EventArgs e)
        {
            try {
                ElementHost host = new ElementHost();

                host.Dock = DockStyle.Fill;
                host.Child = uiControls.speedDial;
                speedDialPanel.Controls.Add(host);

                this.Height_1Panel = splitContainer1.Panel1.Height + 100;
                this.Height_2Panels = this.Height;
                splitContainer1.Panel2Collapsed = true;
                this.Height = Height_1Panel;
            }
            catch (Exception ex) { ShowThreadExceptionDialog("FrmMain_Load", ex);}
        }

        /// <summary>
        /// Frm Main Closing
        /// </summary>
        private void FrmMain_FormClosing(object sender, FormClosingEventArgs e)
        {
            lock (StopLock)
            {
                Stopped = true;
            }
            Thread.Sleep(1000);
            if (MonitorThread != null && MonitorThread.ThreadState == System.Threading.ThreadState.Running)
            {
                MonitorThread.Abort();
            }
        }

        /// <summary>
        /// Creates an error message and displays it.
        /// </summary>
        private static DialogResult ShowThreadExceptionDialog(string title, Exception e)
        {
            string errorMsg = "An application error occurred";
            errorMsg = errorMsg + e.Message + "\n\nStack Trace:\n" + e.StackTrace;
            return MessageBox.Show(errorMsg, title, MessageBoxButtons.AbortRetryIgnore,
                MessageBoxIcon.Stop);
        }

    }

    /// <summary>
    /// ThreadParams Class
    /// </summary>
    class ThreadParams
    {
        public int requestsPerThread;  // how many many separate client requests per thread
        public int serverTransactions; // how many separate transactions to run on the server per request
        public int rowsPerTransaction; // how many rows to inserts/read per transaction
        public int readsPerWrite;      // number of read requests per write request
        public string ReadCommandText; // command text for read request
        public string WriteCommandText; // command text for insert request

        public ThreadParams(int requestsPerThread, int serverTransactions, int rowsPerTransaction, int readsPerWrite,
            string ReadCommandText, string WriteCommandText)
        {
            this.requestsPerThread = requestsPerThread;
            this.serverTransactions = serverTransactions;
            this.rowsPerTransaction = rowsPerTransaction;
            this.readsPerWrite = readsPerWrite;
            this.ReadCommandText = ReadCommandText;
            this.WriteCommandText = WriteCommandText;
        }

    }

}
