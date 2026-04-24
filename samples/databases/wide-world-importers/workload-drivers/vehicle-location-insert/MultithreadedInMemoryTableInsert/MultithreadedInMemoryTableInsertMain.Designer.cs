namespace MultithreadedInMemoryTableInsert
{
    partial class MultithreadedInMemoryTableInsertMain
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
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(MultithreadedInMemoryTableInsertMain));
            this.DescriptionTextBox = new System.Windows.Forms.TextBox();
            this.label1 = new System.Windows.Forms.Label();
            this.ConnectionStringTextBox = new System.Windows.Forms.TextBox();
            this.InsertButton = new System.Windows.Forms.Button();
            this.label2 = new System.Windows.Forms.Label();
            this.NumberOfThreadsNumericUpDown = new System.Windows.Forms.NumericUpDown();
            this.label3 = new System.Windows.Forms.Label();
            this.OnDiskRadioButton = new System.Windows.Forms.RadioButton();
            this.InMemoryRadioButton = new System.Windows.Forms.RadioButton();
            this.NumberOfRowsPerThreadNumericUpDown = new System.Windows.Forms.NumericUpDown();
            this.label4 = new System.Windows.Forms.Label();
            this.label5 = new System.Windows.Forms.Label();
            this.LastExecutionTimeTextBox = new System.Windows.Forms.TextBox();
            ((System.ComponentModel.ISupportInitialize)(this.NumberOfThreadsNumericUpDown)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.NumberOfRowsPerThreadNumericUpDown)).BeginInit();
            this.SuspendLayout();
            //
            // DescriptionTextBox
            //
            this.DescriptionTextBox.BackColor = System.Drawing.SystemColors.Info;
            this.DescriptionTextBox.Location = new System.Drawing.Point(13, 13);
            this.DescriptionTextBox.Multiline = true;
            this.DescriptionTextBox.Name = "DescriptionTextBox";
            this.DescriptionTextBox.Size = new System.Drawing.Size(1116, 55);
            this.DescriptionTextBox.TabIndex = 0;
            this.DescriptionTextBox.TabStop = false;
            this.DescriptionTextBox.Text = resources.GetString("DescriptionTextBox.Text");
            //
            // label1
            //
            this.label1.AutoSize = true;
            this.label1.Location = new System.Drawing.Point(13, 91);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(141, 17);
            this.label1.TabIndex = 1;
            this.label1.Text = "Connection String:";
            //
            // ConnectionStringTextBox
            //
            this.ConnectionStringTextBox.Location = new System.Drawing.Point(13, 123);
            this.ConnectionStringTextBox.Name = "ConnectionStringTextBox";
            this.ConnectionStringTextBox.Size = new System.Drawing.Size(1116, 24);
            this.ConnectionStringTextBox.TabIndex = 0;
            //
            // InsertButton
            //
            this.InsertButton.Location = new System.Drawing.Point(609, 251);
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
            this.label2.Size = new System.Drawing.Size(150, 17);
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
            this.NumberOfThreadsNumericUpDown.Size = new System.Drawing.Size(120, 24);
            this.NumberOfThreadsNumericUpDown.TabIndex = 1;
            this.NumberOfThreadsNumericUpDown.Value = new decimal(new int[] {
            120,
            0,
            0,
            0});
            //
            // label3
            //
            this.label3.AutoSize = true;
            this.label3.Location = new System.Drawing.Point(13, 251);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(155, 17);
            this.label3.TabIndex = 4;
            this.label3.Text = "Table Insertion Type:";
            //
            // OnDiskRadioButton
            //
            this.OnDiskRadioButton.AutoSize = true;
            this.OnDiskRadioButton.Checked = true;
            this.OnDiskRadioButton.Location = new System.Drawing.Point(187, 251);
            this.OnDiskRadioButton.Name = "OnDiskRadioButton";
            this.OnDiskRadioButton.Size = new System.Drawing.Size(81, 21);
            this.OnDiskRadioButton.TabIndex = 3;
            this.OnDiskRadioButton.TabStop = true;
            this.OnDiskRadioButton.Text = "On Disk";
            this.OnDiskRadioButton.UseVisualStyleBackColor = true;
            //
            // InMemoryRadioButton
            //
            this.InMemoryRadioButton.AutoSize = true;
            this.InMemoryRadioButton.Location = new System.Drawing.Point(187, 278);
            this.InMemoryRadioButton.Name = "InMemoryRadioButton";
            this.InMemoryRadioButton.Size = new System.Drawing.Size(100, 21);
            this.InMemoryRadioButton.TabIndex = 4;
            this.InMemoryRadioButton.Text = "In Memory";
            this.InMemoryRadioButton.UseVisualStyleBackColor = true;
            //
            // NumberOfRowsPerThreadNumericUpDown
            //
            this.NumberOfRowsPerThreadNumericUpDown.Location = new System.Drawing.Point(614, 180);
            this.NumberOfRowsPerThreadNumericUpDown.Maximum = new decimal(new int[] {
            1000000,
            0,
            0,
            0});
            this.NumberOfRowsPerThreadNumericUpDown.Minimum = new decimal(new int[] {
            100,
            0,
            0,
            0});
            this.NumberOfRowsPerThreadNumericUpDown.Name = "NumberOfRowsPerThreadNumericUpDown";
            this.NumberOfRowsPerThreadNumericUpDown.Size = new System.Drawing.Size(120, 24);
            this.NumberOfRowsPerThreadNumericUpDown.TabIndex = 2;
            this.NumberOfRowsPerThreadNumericUpDown.Value = new decimal(new int[] {
            1000,
            0,
            0,
            0});
            //
            // label4
            //
            this.label4.AutoSize = true;
            this.label4.Location = new System.Drawing.Point(378, 180);
            this.label4.Name = "label4";
            this.label4.Size = new System.Drawing.Size(213, 17);
            this.label4.TabIndex = 8;
            this.label4.Text = "Number of Rows per Thread:";
            //
            // label5
            //
            this.label5.AutoSize = true;
            this.label5.Location = new System.Drawing.Point(779, 180);
            this.label5.Name = "label5";
            this.label5.Size = new System.Drawing.Size(254, 17);
            this.label5.TabIndex = 9;
            this.label5.Text = "Last Execution Time (Milliseconds):";
            //
            // LastExecutionTimeTextBox
            //
            this.LastExecutionTimeTextBox.BackColor = System.Drawing.Color.PeachPuff;
            this.LastExecutionTimeTextBox.Font = new System.Drawing.Font("Verdana", 24F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.LastExecutionTimeTextBox.Location = new System.Drawing.Point(782, 221);
            this.LastExecutionTimeTextBox.Name = "LastExecutionTimeTextBox";
            this.LastExecutionTimeTextBox.Size = new System.Drawing.Size(220, 46);
            this.LastExecutionTimeTextBox.TabIndex = 10;
            this.LastExecutionTimeTextBox.TabStop = false;
            //
            // MultithreadedInMemoryTableInsertMain
            //
            this.AutoScaleDimensions = new System.Drawing.SizeF(8F, 16F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(1150, 345);
            this.Controls.Add(this.LastExecutionTimeTextBox);
            this.Controls.Add(this.label5);
            this.Controls.Add(this.NumberOfRowsPerThreadNumericUpDown);
            this.Controls.Add(this.label4);
            this.Controls.Add(this.InMemoryRadioButton);
            this.Controls.Add(this.OnDiskRadioButton);
            this.Controls.Add(this.label3);
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
            this.Name = "MultithreadedInMemoryTableInsertMain";
            this.SizeGripStyle = System.Windows.Forms.SizeGripStyle.Hide;
            this.Text = "Multithreaded In Memory Table Insert Main";
            this.FormClosing += new System.Windows.Forms.FormClosingEventHandler(this.MultithreadedInMemoryTableInsertMain_FormClosing);
            this.Load += new System.EventHandler(this.MultithreadedInMemoryTableInsertMain_Load);
            ((System.ComponentModel.ISupportInitialize)(this.NumberOfThreadsNumericUpDown)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.NumberOfRowsPerThreadNumericUpDown)).EndInit();
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
        private System.Windows.Forms.Label label3;
        private System.Windows.Forms.RadioButton OnDiskRadioButton;
        private System.Windows.Forms.RadioButton InMemoryRadioButton;
        private System.Windows.Forms.NumericUpDown NumberOfRowsPerThreadNumericUpDown;
        private System.Windows.Forms.Label label4;
        private System.Windows.Forms.Label label5;
        private System.Windows.Forms.TextBox LastExecutionTimeTextBox;
    }
}

