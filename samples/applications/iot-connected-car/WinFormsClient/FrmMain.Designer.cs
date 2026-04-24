namespace Client
{
    partial class FrmMain
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.components = new System.ComponentModel.Container();
            System.Windows.Forms.DataVisualization.Charting.ChartArea chartArea1 = new System.Windows.Forms.DataVisualization.Charting.ChartArea();
            System.Windows.Forms.DataVisualization.Charting.Legend legend1 = new System.Windows.Forms.DataVisualization.Charting.Legend();
            System.Windows.Forms.DataVisualization.Charting.Series series1 = new System.Windows.Forms.DataVisualization.Charting.Series();
            System.Windows.Forms.DataVisualization.Charting.DataPoint dataPoint1 = new System.Windows.Forms.DataVisualization.Charting.DataPoint(0D, 0D);
            this.bottomToolStrip = new System.Windows.Forms.ToolStrip();
            this.lblTasksTitle = new System.Windows.Forms.ToolStripLabel();
            this.lblTasksValue = new System.Windows.Forms.ToolStripLabel();
            this.tss_1 = new System.Windows.Forms.ToolStripSeparator();
            this.lblBatchSizeTitle = new System.Windows.Forms.ToolStripLabel();
            this.lblBatchSizeValue = new System.Windows.Forms.ToolStripLabel();
            this.tss_2 = new System.Windows.Forms.ToolStripSeparator();
            this.lblMetersTitle = new System.Windows.Forms.ToolStripLabel();
            this.lblMetersValue = new System.Windows.Forms.ToolStripLabel();
            this.Start = new System.Windows.Forms.Button();
            this.Stop = new System.Windows.Forms.Button();
            this.RpsChart = new System.Windows.Forms.DataVisualization.Charting.Chart();
            this.rpsTimer = new System.Windows.Forms.Timer(this.components);
            this.Reset = new System.Windows.Forms.Button();
            this.label1 = new System.Windows.Forms.Label();
            this.lblRpsValue = new System.Windows.Forms.Label();
            this.bottomToolStrip.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.RpsChart)).BeginInit();
            this.SuspendLayout();
            //
            // bottomToolStrip
            //
            this.bottomToolStrip.BackColor = System.Drawing.Color.White;
            this.bottomToolStrip.Dock = System.Windows.Forms.DockStyle.Bottom;
            this.bottomToolStrip.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.lblTasksTitle,
            this.lblTasksValue,
            this.tss_1,
            this.lblBatchSizeTitle,
            this.lblBatchSizeValue,
            this.tss_2,
            this.lblMetersTitle,
            this.lblMetersValue});
            this.bottomToolStrip.Location = new System.Drawing.Point(0, 535);
            this.bottomToolStrip.Name = "bottomToolStrip";
            this.bottomToolStrip.Size = new System.Drawing.Size(1209, 25);
            this.bottomToolStrip.TabIndex = 0;
            this.bottomToolStrip.Text = "toolStrip1";
            //
            // lblTasksTitle
            //
            this.lblTasksTitle.Font = new System.Drawing.Font("Segoe UI", 12F);
            this.lblTasksTitle.ForeColor = System.Drawing.Color.DimGray;
            this.lblTasksTitle.Name = "lblTasksTitle";
            this.lblTasksTitle.Size = new System.Drawing.Size(49, 22);
            this.lblTasksTitle.Text = "Tasks:";
            //
            // lblTasksValue
            //
            this.lblTasksValue.Font = new System.Drawing.Font("Segoe UI", 12F);
            this.lblTasksValue.Name = "lblTasksValue";
            this.lblTasksValue.Size = new System.Drawing.Size(19, 22);
            this.lblTasksValue.Text = "0";
            //
            // tss_1
            //
            this.tss_1.Name = "tss_1";
            this.tss_1.Size = new System.Drawing.Size(6, 25);
            //
            // lblBatchSizeTitle
            //
            this.lblBatchSizeTitle.Font = new System.Drawing.Font("Segoe UI", 12F);
            this.lblBatchSizeTitle.ForeColor = System.Drawing.Color.DimGray;
            this.lblBatchSizeTitle.Name = "lblBatchSizeTitle";
            this.lblBatchSizeTitle.Size = new System.Drawing.Size(83, 22);
            this.lblBatchSizeTitle.Text = "Batch Size:";
            //
            // lblBatchSizeValue
            //
            this.lblBatchSizeValue.Font = new System.Drawing.Font("Segoe UI", 12F);
            this.lblBatchSizeValue.Name = "lblBatchSizeValue";
            this.lblBatchSizeValue.Size = new System.Drawing.Size(19, 22);
            this.lblBatchSizeValue.Text = "0";
            //
            // tss_2
            //
            this.tss_2.Name = "tss_2";
            this.tss_2.Size = new System.Drawing.Size(6, 25);
            //
            // lblMetersTitle
            //
            this.lblMetersTitle.Font = new System.Drawing.Font("Segoe UI", 12F);
            this.lblMetersTitle.ForeColor = System.Drawing.Color.DimGray;
            this.lblMetersTitle.Name = "lblMetersTitle";
            this.lblMetersTitle.Size = new System.Drawing.Size(122, 22);
            this.lblMetersTitle.Text = "Connected Cars:";
            //
            // lblMetersValue
            //
            this.lblMetersValue.Font = new System.Drawing.Font("Segoe UI", 12F);
            this.lblMetersValue.Name = "lblMetersValue";
            this.lblMetersValue.Size = new System.Drawing.Size(19, 22);
            this.lblMetersValue.Text = "0";
            //
            // Start
            //
            this.Start.FlatAppearance.BorderColor = System.Drawing.Color.Silver;
            this.Start.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.Start.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.Start.Location = new System.Drawing.Point(956, 498);
            this.Start.Name = "Start";
            this.Start.Size = new System.Drawing.Size(112, 50);
            this.Start.TabIndex = 2;
            this.Start.Text = "Start";
            this.Start.UseVisualStyleBackColor = true;
            this.Start.Click += new System.EventHandler(this.Start_Click);
            //
            // Stop
            //
            this.Stop.Enabled = false;
            this.Stop.FlatAppearance.BorderColor = System.Drawing.Color.Silver;
            this.Stop.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.Stop.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.Stop.Location = new System.Drawing.Point(1074, 498);
            this.Stop.Name = "Stop";
            this.Stop.Size = new System.Drawing.Size(111, 50);
            this.Stop.TabIndex = 3;
            this.Stop.Text = "Stop";
            this.Stop.UseVisualStyleBackColor = true;
            this.Stop.Click += new System.EventHandler(this.Stop_Click);
            //
            // RpsChart
            //
            this.RpsChart.BackColor = System.Drawing.Color.Transparent;
            this.RpsChart.BorderlineColor = System.Drawing.Color.Black;
            chartArea1.AxisX.IntervalType = System.Windows.Forms.DataVisualization.Charting.DateTimeIntervalType.Seconds;
            chartArea1.AxisX.LabelAutoFitMaxFontSize = 8;
            chartArea1.AxisX.LineColor = System.Drawing.Color.DimGray;
            chartArea1.AxisX.MajorGrid.Enabled = false;
            chartArea1.AxisX.MajorGrid.Interval = 0D;
            chartArea1.AxisX.MajorGrid.IntervalOffset = 0D;
            chartArea1.AxisX.MajorGrid.IntervalType = System.Windows.Forms.DataVisualization.Charting.DateTimeIntervalType.Auto;
            chartArea1.AxisX.MajorTickMark.Enabled = false;
            chartArea1.AxisX.Maximum = 100D;
            chartArea1.AxisX.Minimum = 0D;
            chartArea1.AxisX.Title = "Seconds";
            chartArea1.AxisX.TitleFont = new System.Drawing.Font("Tahoma", 10F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            chartArea1.AxisY.LabelAutoFitMaxFontSize = 8;
            chartArea1.AxisY.LineColor = System.Drawing.Color.DimGray;
            chartArea1.AxisY.MajorGrid.Enabled = false;
            chartArea1.AxisY.Minimum = 0D;
            chartArea1.AxisY.Title = "Number Of Events";
            chartArea1.AxisY.TitleFont = new System.Drawing.Font("Tahoma", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            chartArea1.BackColor = System.Drawing.Color.Transparent;
            chartArea1.Name = "Chart";
            this.RpsChart.ChartAreas.Add(chartArea1);
            legend1.BackColor = System.Drawing.Color.Transparent;
            legend1.Enabled = false;
            legend1.ForeColor = System.Drawing.Color.Maroon;
            legend1.Name = "Legend1";
            this.RpsChart.Legends.Add(legend1);
            this.RpsChart.Location = new System.Drawing.Point(0, 53);
            this.RpsChart.Name = "RpsChart";
            this.RpsChart.Palette = System.Windows.Forms.DataVisualization.Charting.ChartColorPalette.None;
            series1.ChartArea = "Chart";
            series1.ChartType = System.Windows.Forms.DataVisualization.Charting.SeriesChartType.Area;
            series1.Color = System.Drawing.Color.Gray;
            series1.Font = new System.Drawing.Font("Microsoft Sans Serif", 6F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            series1.Legend = "Legend1";
            series1.LegendText = "sadsaDS";
            series1.MarkerBorderWidth = 3;
            series1.Name = "RPS";
            series1.Points.Add(dataPoint1);
            this.RpsChart.Series.Add(series1);
            this.RpsChart.Size = new System.Drawing.Size(1209, 419);
            this.RpsChart.TabIndex = 102;
            this.RpsChart.Text = "Rows / Sec";
            //
            // rpsTimer
            //
            this.rpsTimer.Interval = 300;
            this.rpsTimer.Tick += new System.EventHandler(this.rpsTimer_Tick);
            //
            // Reset
            //
            this.Reset.BackColor = System.Drawing.Color.White;
            this.Reset.FlatAppearance.BorderColor = System.Drawing.Color.Silver;
            this.Reset.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.Reset.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.Reset.Location = new System.Drawing.Point(764, 498);
            this.Reset.Name = "Reset";
            this.Reset.Size = new System.Drawing.Size(160, 50);
            this.Reset.TabIndex = 103;
            this.Reset.Text = "Setup/Reset DB";
            this.Reset.UseVisualStyleBackColor = false;
            this.Reset.Click += new System.EventHandler(this.Reset_Click);
            //
            // label1
            //
            this.label1.AutoSize = true;
            this.label1.Font = new System.Drawing.Font("Microsoft Sans Serif", 22F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label1.ForeColor = System.Drawing.Color.DimGray;
            this.label1.Location = new System.Drawing.Point(81, 14);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(168, 36);
            this.label1.TabIndex = 104;
            this.label1.Text = "Events/sec:";
            //
            // lblRpsValue
            //
            this.lblRpsValue.AutoSize = true;
            this.lblRpsValue.Font = new System.Drawing.Font("Microsoft Sans Serif", 21.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblRpsValue.ForeColor = System.Drawing.Color.Red;
            this.lblRpsValue.Location = new System.Drawing.Point(245, 17);
            this.lblRpsValue.Name = "lblRpsValue";
            this.lblRpsValue.Size = new System.Drawing.Size(31, 33);
            this.lblRpsValue.TabIndex = 105;
            this.lblRpsValue.Text = "0";
            //
            // FrmMain
            //
            this.AutoScaleDimensions = new System.Drawing.SizeF(96F, 96F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Dpi;
            this.BackColor = System.Drawing.Color.White;
            this.ClientSize = new System.Drawing.Size(1209, 560);
            this.Controls.Add(this.lblRpsValue);
            this.Controls.Add(this.label1);
            this.Controls.Add(this.Reset);
            this.Controls.Add(this.RpsChart);
            this.Controls.Add(this.Stop);
            this.Controls.Add(this.Start);
            this.Controls.Add(this.bottomToolStrip);
            this.Name = "FrmMain";
            this.Text = "IoT Connected Car - Event Generator";
            this.bottomToolStrip.ResumeLayout(false);
            this.bottomToolStrip.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)(this.RpsChart)).EndInit();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.ToolStrip bottomToolStrip;
        private System.Windows.Forms.ToolStripLabel lblTasksTitle;
        private System.Windows.Forms.ToolStripLabel lblTasksValue;
        private System.Windows.Forms.ToolStripSeparator tss_1;
        private System.Windows.Forms.ToolStripLabel lblBatchSizeTitle;
        private System.Windows.Forms.ToolStripLabel lblBatchSizeValue;
        private System.Windows.Forms.ToolStripSeparator tss_2;
        private System.Windows.Forms.Button Start;
        private System.Windows.Forms.Button Stop;
        private System.Windows.Forms.DataVisualization.Charting.Chart RpsChart;
        private System.Windows.Forms.Timer rpsTimer;
        private System.Windows.Forms.ToolStripLabel lblMetersTitle;
        private System.Windows.Forms.ToolStripLabel lblMetersValue;
        private System.Windows.Forms.Button Reset;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.Label lblRpsValue;
    }
}

