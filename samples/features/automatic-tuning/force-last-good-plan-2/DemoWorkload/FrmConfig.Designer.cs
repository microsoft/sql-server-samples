namespace DemoWorkload
{
    partial class FrmConfig
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
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA2204:Literals should be spelled correctly", MessageId = "PageRead")]
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Globalization", "CA1303:Do not pass literals as localized parameters", MessageId = "System.Windows.Forms.Control.set_Text(System.String)")]
        private void InitializeComponent()
        {
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(FrmConfig));
            this.LabelReadsPerWrite = new System.Windows.Forms.Label();
            this.ReadsPerWrite = new System.Windows.Forms.NumericUpDown();
            this.LabelRPT = new System.Windows.Forms.Label();
            this.RequestCount = new System.Windows.Forms.NumericUpDown();
            this.lblInstance = new System.Windows.Forms.Label();
            this.tbConnectionString = new System.Windows.Forms.TextBox();
            this.label3 = new System.Windows.Forms.Label();
            this.txtMaxTPS = new System.Windows.Forms.TextBox();
            this.lblRunningThread = new System.Windows.Forms.Label();
            this.txtMaxPageRead = new System.Windows.Forms.TextBox();
            this.lblServerTran = new System.Windows.Forms.Label();
            this.TransactionCount = new System.Windows.Forms.NumericUpDown();
            this.lblThreadCnt = new System.Windows.Forms.Label();
            this.ThreadCount = new System.Windows.Forms.NumericUpDown();
            this.btnSave = new System.Windows.Forms.Button();
            ((System.ComponentModel.ISupportInitialize)(this.ReadsPerWrite)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.RequestCount)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.TransactionCount)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.ThreadCount)).BeginInit();
            this.SuspendLayout();
            //
            // LabelReadsPerWrite
            //
            this.LabelReadsPerWrite.Location = new System.Drawing.Point(0, 0);
            this.LabelReadsPerWrite.Name = "LabelReadsPerWrite";
            this.LabelReadsPerWrite.Size = new System.Drawing.Size(100, 23);
            this.LabelReadsPerWrite.TabIndex = 50;
            //
            // ReadsPerWrite
            //
            this.ReadsPerWrite.Location = new System.Drawing.Point(0, 0);
            this.ReadsPerWrite.Name = "ReadsPerWrite";
            this.ReadsPerWrite.Size = new System.Drawing.Size(120, 20);
            this.ReadsPerWrite.TabIndex = 51;
            //
            // LabelRPT
            //
            this.LabelRPT.AutoSize = true;
            this.LabelRPT.BackColor = System.Drawing.Color.Transparent;
            this.LabelRPT.Location = new System.Drawing.Point(14, 101);
            this.LabelRPT.Name = "LabelRPT";
            this.LabelRPT.Size = new System.Drawing.Size(107, 13);
            this.LabelRPT.TabIndex = 44;
            this.LabelRPT.Text = "Requests per Thread";
            //
            // RequestCount
            //
            this.RequestCount.Location = new System.Drawing.Point(152, 99);
            this.RequestCount.Maximum = new decimal(new int[] {
            5000000,
            0,
            0,
            0});
            this.RequestCount.Minimum = new decimal(new int[] {
            1,
            0,
            0,
            0});
            this.RequestCount.Name = "RequestCount";
            this.RequestCount.Size = new System.Drawing.Size(99, 20);
            this.RequestCount.TabIndex = 43;
            this.RequestCount.Value = new decimal(new int[] {
            100000,
            0,
            0,
            0});
            //
            // lblInstance
            //
            this.lblInstance.AutoSize = true;
            this.lblInstance.BackColor = System.Drawing.Color.Transparent;
            this.lblInstance.Location = new System.Drawing.Point(14, 217);
            this.lblInstance.Name = "lblInstance";
            this.lblInstance.Size = new System.Drawing.Size(91, 13);
            this.lblInstance.TabIndex = 42;
            this.lblInstance.Text = "Connection String";
            //
            // tbConnectionString
            //
            this.tbConnectionString.Location = new System.Drawing.Point(16, 243);
            this.tbConnectionString.Name = "tbConnectionString";
            this.tbConnectionString.Size = new System.Drawing.Size(271, 20);
            this.tbConnectionString.TabIndex = 40;
            this.tbConnectionString.TextChanged += new System.EventHandler(this.tbInstance_TextChanged);
            //
            // label3
            //
            this.label3.AutoSize = true;
            this.label3.BackColor = System.Drawing.Color.Transparent;
            this.label3.Location = new System.Drawing.Point(14, 25);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(109, 13);
            this.label3.TabIndex = 38;
            this.label3.Text = "Max TPS (thousands)";
            //
            // txtMaxTPS
            //
            this.txtMaxTPS.Location = new System.Drawing.Point(152, 22);
            this.txtMaxTPS.Name = "txtMaxTPS";
            this.txtMaxTPS.Size = new System.Drawing.Size(99, 20);
            this.txtMaxTPS.TabIndex = 37;
            this.txtMaxTPS.TabStop = false;
            //
            // lblRunningThread
            //
            this.lblRunningThread.AutoSize = true;
            this.lblRunningThread.BackColor = System.Drawing.Color.Transparent;
            this.lblRunningThread.Location = new System.Drawing.Point(14, 50);
            this.lblRunningThread.Name = "lblRunningThread";
            this.lblRunningThread.Size = new System.Drawing.Size(107, 13);
            this.lblRunningThread.TabIndex = 36;
            this.lblRunningThread.Text = "Max PageRead Time";
            //
            // txtMaxPageRead
            //
            this.txtMaxPageRead.Location = new System.Drawing.Point(152, 47);
            this.txtMaxPageRead.Name = "txtMaxPageRead";
            this.txtMaxPageRead.Size = new System.Drawing.Size(99, 20);
            this.txtMaxPageRead.TabIndex = 35;
            this.txtMaxPageRead.TabStop = false;
            this.txtMaxPageRead.Text = "10000";
            //
            // lblServerTran
            //
            this.lblServerTran.AutoSize = true;
            this.lblServerTran.BackColor = System.Drawing.Color.Transparent;
            this.lblServerTran.Location = new System.Drawing.Point(14, 153);
            this.lblServerTran.Name = "lblServerTran";
            this.lblServerTran.Size = new System.Drawing.Size(102, 13);
            this.lblServerTran.TabIndex = 34;
            this.lblServerTran.Text = "Server Transactions";
            //
            // TransactionCount
            //
            this.TransactionCount.Location = new System.Drawing.Point(152, 151);
            this.TransactionCount.Maximum = new decimal(new int[] {
            5000000,
            0,
            0,
            0});
            this.TransactionCount.Minimum = new decimal(new int[] {
            1,
            0,
            0,
            0});
            this.TransactionCount.Name = "TransactionCount";
            this.TransactionCount.Size = new System.Drawing.Size(99, 20);
            this.TransactionCount.TabIndex = 29;
            this.TransactionCount.Value = new decimal(new int[] {
            1,
            0,
            0,
            0});
            //
            // lblThreadCnt
            //
            this.lblThreadCnt.AutoSize = true;
            this.lblThreadCnt.BackColor = System.Drawing.Color.Transparent;
            this.lblThreadCnt.Location = new System.Drawing.Point(14, 127);
            this.lblThreadCnt.Name = "lblThreadCnt";
            this.lblThreadCnt.Size = new System.Drawing.Size(46, 13);
            this.lblThreadCnt.TabIndex = 31;
            this.lblThreadCnt.Text = "Threads";
            //
            // ThreadCount
            //
            this.ThreadCount.Location = new System.Drawing.Point(152, 125);
            this.ThreadCount.Maximum = new decimal(new int[] {
            200,
            0,
            0,
            0});
            this.ThreadCount.Minimum = new decimal(new int[] {
            1,
            0,
            0,
            0});
            this.ThreadCount.Name = "ThreadCount";
            this.ThreadCount.Size = new System.Drawing.Size(99, 20);
            this.ThreadCount.TabIndex = 28;
            this.ThreadCount.Value = new decimal(new int[] {
            80,
            0,
            0,
            0});
            //
            // btnSave
            //
            this.btnSave.Location = new System.Drawing.Point(16, 293);
            this.btnSave.Name = "btnSave";
            this.btnSave.Size = new System.Drawing.Size(149, 23);
            this.btnSave.TabIndex = 49;
            this.btnSave.Text = "Save Configuration Values";
            this.btnSave.UseVisualStyleBackColor = true;
            this.btnSave.Click += new System.EventHandler(this.btnSave_Click);
            //
            // FrmConfig
            //
            this.AutoScaleDimensions = new System.Drawing.SizeF(96F, 96F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Dpi;
            this.ClientSize = new System.Drawing.Size(310, 332);
            this.Controls.Add(this.btnSave);
            this.Controls.Add(this.LabelReadsPerWrite);
            this.Controls.Add(this.ReadsPerWrite);
            this.Controls.Add(this.LabelRPT);
            this.Controls.Add(this.RequestCount);
            this.Controls.Add(this.lblInstance);
            this.Controls.Add(this.tbConnectionString);
            this.Controls.Add(this.label3);
            this.Controls.Add(this.txtMaxTPS);
            this.Controls.Add(this.lblRunningThread);
            this.Controls.Add(this.txtMaxPageRead);
            this.Controls.Add(this.lblServerTran);
            this.Controls.Add(this.TransactionCount);
            this.Controls.Add(this.lblThreadCnt);
            this.Controls.Add(this.ThreadCount);
            this.Icon = ((System.Drawing.Icon)(resources.GetObject("$this.Icon")));
            this.Name = "FrmConfig";
            this.Text = "Configuration Settings";
            this.Load += new System.EventHandler(this.ConfigForm_Load);
            ((System.ComponentModel.ISupportInitialize)(this.ReadsPerWrite)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.RequestCount)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.TransactionCount)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.ThreadCount)).EndInit();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Label LabelReadsPerWrite;
        private System.Windows.Forms.NumericUpDown ReadsPerWrite;
        private System.Windows.Forms.Label LabelRPT;
        private System.Windows.Forms.NumericUpDown RequestCount;
        private System.Windows.Forms.Label lblInstance;
        private System.Windows.Forms.TextBox tbConnectionString;
        private System.Windows.Forms.Label label3;
        private System.Windows.Forms.TextBox txtMaxTPS;
        private System.Windows.Forms.Label lblRunningThread;
        private System.Windows.Forms.TextBox txtMaxPageRead;
        private System.Windows.Forms.Label lblServerTran;
        private System.Windows.Forms.NumericUpDown TransactionCount;
        private System.Windows.Forms.Label lblThreadCnt;
        private System.Windows.Forms.NumericUpDown ThreadCount;
        private System.Windows.Forms.Button btnSave;
    }
}