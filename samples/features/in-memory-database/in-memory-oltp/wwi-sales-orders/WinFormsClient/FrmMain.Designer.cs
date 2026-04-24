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
            this.lblRpsTitle = new System.Windows.Forms.ToolStripLabel();
            this.lblRpsValue = new System.Windows.Forms.ToolStripLabel();
            this.Start = new System.Windows.Forms.Button();
            this.Stop = new System.Windows.Forms.Button();
            this.RpsChart = new System.Windows.Forms.DataVisualization.Charting.Chart();
            this.rpsTimer = new System.Windows.Forms.Timer(this.components);
            this.mainTimer = new System.Windows.Forms.Timer(this.components);
            this.InMemoryRadioButton = new System.Windows.Forms.RadioButton();
            this.OnDiskRadioButton = new System.Windows.Forms.RadioButton();
            this.InMemoryWithCSIRadioButton = new System.Windows.Forms.RadioButton();
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
            this.lblRpsTitle,
            this.lblRpsValue});
            this.bottomToolStrip.Location = new System.Drawing.Point(0, 300);
            this.bottomToolStrip.Name = "bottomToolStrip";
            this.bottomToolStrip.Size = new System.Drawing.Size(851, 43);
            this.bottomToolStrip.TabIndex = 0;
            this.bottomToolStrip.Text = "toolStrip1";
            //
            // lblTasksTitle
            //
            this.lblTasksTitle.ForeColor = System.Drawing.Color.Gray;
            this.lblTasksTitle.Name = "lblTasksTitle";
            this.lblTasksTitle.Size = new System.Drawing.Size(52, 40);
            this.lblTasksTitle.Text = "Threads:";
            //
            // lblTasksValue
            //
            this.lblTasksValue.Name = "lblTasksValue";
            this.lblTasksValue.Size = new System.Drawing.Size(13, 40);
            this.lblTasksValue.Text = "0";
            //
            // tss_1
            //
            this.tss_1.Name = "tss_1";
            this.tss_1.Size = new System.Drawing.Size(6, 43);
            //
            // lblBatchSizeTitle
            //
            this.lblBatchSizeTitle.ForeColor = System.Drawing.Color.Gray;
            this.lblBatchSizeTitle.Name = "lblBatchSizeTitle";
            this.lblBatchSizeTitle.Size = new System.Drawing.Size(98, 40);
            this.lblBatchSizeTitle.Text = "Rows Per Thread:";
            //
            // lblBatchSizeValue
            //
            this.lblBatchSizeValue.Name = "lblBatchSizeValue";
            this.lblBatchSizeValue.Size = new System.Drawing.Size(13, 40);
            this.lblBatchSizeValue.Text = "0";
            //
            // tss_2
            //
            this.tss_2.Name = "tss_2";
            this.tss_2.Size = new System.Drawing.Size(6, 43);
            //
            // lblRpsTitle
            //
            this.lblRpsTitle.Font = new System.Drawing.Font("Segoe UI", 9F, System.Drawing.FontStyle.Bold);
            this.lblRpsTitle.ForeColor = System.Drawing.Color.DimGray;
            this.lblRpsTitle.Name = "lblRpsTitle";
            this.lblRpsTitle.Size = new System.Drawing.Size(112, 40);
            this.lblRpsTitle.Text = "Rows/sec inserted:";
            //
            // lblRpsValue
            //
            this.lblRpsValue.Font = new System.Drawing.Font("Segoe UI", 21.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblRpsValue.ForeColor = System.Drawing.Color.Red;
            this.lblRpsValue.Name = "lblRpsValue";
            this.lblRpsValue.Size = new System.Drawing.Size(33, 40);
            this.lblRpsValue.Text = "0";
            //
            // Start
            //
            this.Start.FlatAppearance.BorderColor = System.Drawing.Color.Silver;
            this.Start.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.Start.Location = new System.Drawing.Point(717, 291);
            this.Start.Name = "Start";
            this.Start.Size = new System.Drawing.Size(105, 40);
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
            this.Stop.Location = new System.Drawing.Point(606, 291);
            this.Stop.Name = "Stop";
            this.Stop.Size = new System.Drawing.Size(105, 40);
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
            chartArea1.AxisX.LineColor = System.Drawing.Color.DarkGray;
            chartArea1.AxisX.MajorGrid.Enabled = false;
            chartArea1.AxisX.MajorGrid.Interval = 0D;
            chartArea1.AxisX.MajorGrid.IntervalOffset = 0D;
            chartArea1.AxisX.MajorGrid.IntervalType = System.Windows.Forms.DataVisualization.Charting.DateTimeIntervalType.Auto;
            chartArea1.AxisX.MajorTickMark.Enabled = false;
            chartArea1.AxisX.Maximum = 100D;
            chartArea1.AxisX.Minimum = 0D;
            chartArea1.AxisY.LabelAutoFitMaxFontSize = 8;
            chartArea1.AxisY.LineColor = System.Drawing.Color.DarkGray;
            chartArea1.AxisY.MajorGrid.Enabled = false;
            chartArea1.AxisY.Minimum = 0D;
            chartArea1.BackColor = System.Drawing.Color.Transparent;
            chartArea1.Name = "Chart";
            this.RpsChart.ChartAreas.Add(chartArea1);
            legend1.BackColor = System.Drawing.Color.Transparent;
            legend1.Enabled = false;
            legend1.ForeColor = System.Drawing.Color.Maroon;
            legend1.Name = "Legend1";
            this.RpsChart.Legends.Add(legend1);
            this.RpsChart.Location = new System.Drawing.Point(0, 0);
            this.RpsChart.Name = "RpsChart";
            this.RpsChart.Palette = System.Windows.Forms.DataVisualization.Charting.ChartColorPalette.None;
            series1.ChartArea = "Chart";
            series1.ChartType = System.Windows.Forms.DataVisualization.Charting.SeriesChartType.SplineArea;
            series1.Color = System.Drawing.Color.DarkGray;
            series1.Font = new System.Drawing.Font("Microsoft Sans Serif", 6F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            series1.Legend = "Legend1";
            series1.LegendText = "sadsaDS";
            series1.MarkerBorderWidth = 3;
            series1.Name = "RPS";
            series1.Points.Add(dataPoint1);
            this.RpsChart.Series.Add(series1);
            this.RpsChart.Size = new System.Drawing.Size(847, 262);
            this.RpsChart.TabIndex = 102;
            this.RpsChart.Text = "Rows / Sec";
            //
            // rpsTimer
            //
            this.rpsTimer.Interval = 300;
            this.rpsTimer.Tick += new System.EventHandler(this.rpsTimer_Tick);
            //
            // InMemoryRadioButton
            //
            this.InMemoryRadioButton.AutoSize = true;
            this.InMemoryRadioButton.ForeColor = System.Drawing.Color.Black;
            this.InMemoryRadioButton.Location = new System.Drawing.Point(553, 258);
            this.InMemoryRadioButton.Name = "InMemoryRadioButton";
            this.InMemoryRadioButton.Size = new System.Drawing.Size(74, 17);
            this.InMemoryRadioButton.TabIndex = 105;
            this.InMemoryRadioButton.Text = "In Memory";
            this.InMemoryRadioButton.UseVisualStyleBackColor = true;
            //
            // OnDiskRadioButton
            //
            this.OnDiskRadioButton.AutoSize = true;
            this.OnDiskRadioButton.Checked = true;
            this.OnDiskRadioButton.Location = new System.Drawing.Point(484, 258);
            this.OnDiskRadioButton.Name = "OnDiskRadioButton";
            this.OnDiskRadioButton.Size = new System.Drawing.Size(63, 17);
            this.OnDiskRadioButton.TabIndex = 104;
            this.OnDiskRadioButton.TabStop = true;
            this.OnDiskRadioButton.Text = "On Disk";
            this.OnDiskRadioButton.UseVisualStyleBackColor = true;
            //
            // InMemoryWithCSIRadioButton
            //
            this.InMemoryWithCSIRadioButton.AutoSize = true;
            this.InMemoryWithCSIRadioButton.ForeColor = System.Drawing.Color.Black;
            this.InMemoryWithCSIRadioButton.Location = new System.Drawing.Point(633, 258);
            this.InMemoryWithCSIRadioButton.Name = "InMemoryWithCSIRadioButton";
            this.InMemoryWithCSIRadioButton.Size = new System.Drawing.Size(191, 17);
            this.InMemoryWithCSIRadioButton.TabIndex = 106;
            this.InMemoryWithCSIRadioButton.Text = "In Memory With ColumnStore Index";
            this.InMemoryWithCSIRadioButton.UseVisualStyleBackColor = true;
            //
            // FrmMain
            //
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.BackColor = System.Drawing.Color.White;
            this.ClientSize = new System.Drawing.Size(851, 343);
            this.Controls.Add(this.InMemoryWithCSIRadioButton);
            this.Controls.Add(this.InMemoryRadioButton);
            this.Controls.Add(this.OnDiskRadioButton);
            this.Controls.Add(this.RpsChart);
            this.Controls.Add(this.Stop);
            this.Controls.Add(this.Start);
            this.Controls.Add(this.bottomToolStrip);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedSingle;
            this.Name = "FrmMain";
            this.Text = "Data Generator Client";
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
        private System.Windows.Forms.ToolStripLabel lblRpsTitle;
        private System.Windows.Forms.ToolStripLabel lblRpsValue;
        private System.Windows.Forms.Timer rpsTimer;
        private System.Windows.Forms.Timer mainTimer;
        private System.Windows.Forms.RadioButton InMemoryRadioButton;
        private System.Windows.Forms.RadioButton OnDiskRadioButton;
        private System.Windows.Forms.RadioButton InMemoryWithCSIRadioButton;
    }
}

