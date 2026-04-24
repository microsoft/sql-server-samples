namespace MultithreadedInMemoryTableInsert
{
    partial class MultithreadedOrderInsertMain
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
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(MultithreadedOrderInsertMain));
            this.DescriptionTextBox = new System.Windows.Forms.TextBox();
            this.label1 = new System.Windows.Forms.Label();
            this.ConnectionStringTextBox = new System.Windows.Forms.TextBox();
            this.InsertButton = new System.Windows.Forms.Button();
            this.label2 = new System.Windows.Forms.Label();
            this.NumberOfThreadsNumericUpDown = new System.Windows.Forms.NumericUpDown();
            this.label5 = new System.Windows.Forms.Label();
            this.AverageOrderInsertionTimeTextBox = new System.Windows.Forms.TextBox();
            this.DisplayUpdateTimer = new System.Windows.Forms.Timer(this.components);
            ((System.ComponentModel.ISupportInitialize)(this.NumberOfThreadsNumericUpDown)).BeginInit();
            this.SuspendLayout();
            //
            // DescriptionTextBox
            //
            this.DescriptionTextBox.BackColor = System.Drawing.SystemColors.Info;
            this.DescriptionTextBox.Location = new System.Drawing.Point(13, 13);
            this.DescriptionTextBox.Multiline = true;
            this.DescriptionTextBox.Name = "DescriptionTextBox";
            this.DescriptionTextBox.Size = new System.Drawing.Size(1065, 55);
            this.DescriptionTextBox.TabIndex = 0;
            this.DescriptionTextBox.TabStop = false;
            this.DescriptionTextBox.Text = resources.GetString("DescriptionTextBox.Text");
            //
            // label1
            //
            this.label1.AutoSize = true;
            this.label1.Location = new System.Drawing.Point(13, 91);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(172, 20);
            this.label1.TabIndex = 1;
            this.label1.Text = "Connection String:";
            //
            // ConnectionStringTextBox
            //
            this.ConnectionStringTextBox.Location = new System.Drawing.Point(13, 123);
            this.ConnectionStringTextBox.Name = "ConnectionStringTextBox";
            this.ConnectionStringTextBox.Size = new System.Drawing.Size(1065, 28);
            this.ConnectionStringTextBox.TabIndex = 0;
            //
            // InsertButton
            //
            this.InsertButton.Location = new System.Drawing.Point(431, 264);
            this.InsertButton.Name = "InsertButton";
            this.InsertButton.Size = new System.Drawing.Size(125, 37);
            this.InsertButton.TabIndex = 5;
            this.InsertButton.Text = "&Insert";
            this.InsertButton.UseVisualStyleBackColor = true;
            this.InsertButton.Click += new System.EventHandler(this.InsertButton_Click);
            //
            // label2
            //
            this.label2.AutoSize = true;
            this.label2.Location = new System.Drawing.Point(13, 178);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(182, 20);
            this.label2.TabIndex = 3;
            this.label2.Text = "Number of Threads:";
            //
            // NumberOfThreadsNumericUpDown
            //
            this.NumberOfThreadsNumericUpDown.Location = new System.Drawing.Point(187, 178);
            this.NumberOfThreadsNumericUpDown.Maximum = new decimal(new int[] {
            250,
            0,
            0,
            0});
            this.NumberOfThreadsNumericUpDown.Minimum = new decimal(new int[] {
            1,
            0,
            0,
            0});
            this.NumberOfThreadsNumericUpDown.Name = "NumberOfThreadsNumericUpDown";
            this.NumberOfThreadsNumericUpDown.Size = new System.Drawing.Size(120, 28);
            this.NumberOfThreadsNumericUpDown.TabIndex = 1;
            this.NumberOfThreadsNumericUpDown.Value = new decimal(new int[] {
            10,
            0,
            0,
            0});
            //
            // label5
            //
            this.label5.AutoSize = true;
            this.label5.Location = new System.Drawing.Point(715, 185);
            this.label5.Name = "label5";
            this.label5.Size = new System.Drawing.Size(398, 20);
            this.label5.TabIndex = 9;
            this.label5.Text = "Average Order Insertion Time (Milliseconds):";
            //
            // AverageOrderInsertionTimeTextBox
            //
            this.AverageOrderInsertionTimeTextBox.BackColor = System.Drawing.Color.PeachPuff;
            this.AverageOrderInsertionTimeTextBox.Font = new System.Drawing.Font("Verdana", 24F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.AverageOrderInsertionTimeTextBox.Location = new System.Drawing.Point(782, 221);
            this.AverageOrderInsertionTimeTextBox.Name = "AverageOrderInsertionTimeTextBox";
            this.AverageOrderInsertionTimeTextBox.Size = new System.Drawing.Size(220, 56);
            this.AverageOrderInsertionTimeTextBox.TabIndex = 10;
            this.AverageOrderInsertionTimeTextBox.TabStop = false;
            //
            // DisplayUpdateTimer
            //
            this.DisplayUpdateTimer.Interval = 1000;
            this.DisplayUpdateTimer.Tick += new System.EventHandler(this.DisplayUpdateTimer_Tick);
            //
            // MultithreadedOrderInsertMain
            //
            this.AutoScaleDimensions = new System.Drawing.SizeF(11F, 20F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(1107, 345);
            this.Controls.Add(this.AverageOrderInsertionTimeTextBox);
            this.Controls.Add(this.label5);
            this.Controls.Add(this.NumberOfThreadsNumericUpDown);
            this.Controls.Add(this.label2);
            this.Controls.Add(this.InsertButton);
            this.Controls.Add(this.ConnectionStringTextBox);
            this.Controls.Add(this.label1);
            this.Controls.Add(this.DescriptionTextBox);
            this.Font = new System.Drawing.Font("Verdana", 10F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedSingle;
            this.Margin = new System.Windows.Forms.Padding(3, 4, 3, 4);
            this.MaximizeBox = false;
            this.Name = "MultithreadedOrderInsertMain";
            this.SizeGripStyle = System.Windows.Forms.SizeGripStyle.Hide;
            this.Text = "Multithreaded Order Insert Main";
            this.FormClosing += new System.Windows.Forms.FormClosingEventHandler(this.MultithreadedOrderInsertMain_FormClosing);
            this.Load += new System.EventHandler(this.MultithreadedOrderInsertMain_Load);
            ((System.ComponentModel.ISupportInitialize)(this.NumberOfThreadsNumericUpDown)).EndInit();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.TextBox DescriptionTextBox;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.TextBox ConnectionStringTextBox;
        private System.Windows.Forms.Button InsertButton;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.NumericUpDown NumberOfThreadsNumericUpDown;
        private System.Windows.Forms.Label label5;
        private System.Windows.Forms.TextBox AverageOrderInsertionTimeTextBox;
        private System.Windows.Forms.Timer DisplayUpdateTimer;
    }
}

