namespace MultithreadedInMemoryTableInsert
{
    partial class ErrorDetailsForm
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
            this.MainMessageTextBox = new System.Windows.Forms.TextBox();
            this.DetailedErrorMessageTextBox = new System.Windows.Forms.TextBox();
            this.label2 = new System.Windows.Forms.Label();
            this.OKButton = new System.Windows.Forms.Button();
            this.SuspendLayout();
            //
            // MainMessageTextBox
            //
            this.MainMessageTextBox.BackColor = System.Drawing.SystemColors.Info;
            this.MainMessageTextBox.Location = new System.Drawing.Point(29, 12);
            this.MainMessageTextBox.Multiline = true;
            this.MainMessageTextBox.Name = "MainMessageTextBox";
            this.MainMessageTextBox.Size = new System.Drawing.Size(942, 55);
            this.MainMessageTextBox.TabIndex = 1;
            this.MainMessageTextBox.TabStop = false;
            this.MainMessageTextBox.Text = "This program is meant to be used to provide an intense order entry insert workloa" +
    "d for the WideWorldImporters database. Please check that you are connected to a " +
    "valid copy of that database.";
            //
            // DetailedErrorMessageTextBox
            //
            this.DetailedErrorMessageTextBox.BackColor = System.Drawing.Color.LightCyan;
            this.DetailedErrorMessageTextBox.Location = new System.Drawing.Point(29, 105);
            this.DetailedErrorMessageTextBox.Multiline = true;
            this.DetailedErrorMessageTextBox.Name = "DetailedErrorMessageTextBox";
            this.DetailedErrorMessageTextBox.ScrollBars = System.Windows.Forms.ScrollBars.Both;
            this.DetailedErrorMessageTextBox.Size = new System.Drawing.Size(942, 294);
            this.DetailedErrorMessageTextBox.TabIndex = 2;
            this.DetailedErrorMessageTextBox.TabStop = false;
            //
            // label2
            //
            this.label2.AutoSize = true;
            this.label2.Location = new System.Drawing.Point(26, 86);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(165, 16);
            this.label2.TabIndex = 4;
            this.label2.Text = "Detailed error message:";
            //
            // OKButton
            //
            this.OKButton.Location = new System.Drawing.Point(446, 417);
            this.OKButton.Name = "OKButton";
            this.OKButton.Size = new System.Drawing.Size(125, 37);
            this.OKButton.TabIndex = 6;
            this.OKButton.Text = "&OK";
            this.OKButton.UseVisualStyleBackColor = true;
            this.OKButton.Click += new System.EventHandler(this.OKButton_Click);
            //
            // ErrorDetailsForm
            //
            this.AutoScaleDimensions = new System.Drawing.SizeF(8F, 16F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(1017, 466);
            this.Controls.Add(this.OKButton);
            this.Controls.Add(this.label2);
            this.Controls.Add(this.DetailedErrorMessageTextBox);
            this.Controls.Add(this.MainMessageTextBox);
            this.Font = new System.Drawing.Font("Verdana", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedSingle;
            this.Margin = new System.Windows.Forms.Padding(4);
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.Name = "ErrorDetailsForm";
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "Error Details";
            this.TopMost = true;
            this.Load += new System.EventHandler(this.ErrorDetailsForm_Load);
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.TextBox MainMessageTextBox;
        private System.Windows.Forms.TextBox DetailedErrorMessageTextBox;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.Button OKButton;
    }
}