namespace PopulateAlwaysEncryptedData
{
    partial class PopulateAlwaysEncryptedDataMain
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
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(PopulateAlwaysEncryptedDataMain));
            this.DescriptionTextBox = new System.Windows.Forms.TextBox();
            this.ConnectionStringLabel = new System.Windows.Forms.Label();
            this.ConnectionStringTextBox = new System.Windows.Forms.TextBox();
            this.PopulateButton = new System.Windows.Forms.Button();
            this.SuspendLayout();
            //
            // DescriptionTextBox
            //
            this.DescriptionTextBox.BackColor = System.Drawing.SystemColors.Info;
            this.DescriptionTextBox.Location = new System.Drawing.Point(13, 13);
            this.DescriptionTextBox.Multiline = true;
            this.DescriptionTextBox.Name = "DescriptionTextBox";
            this.DescriptionTextBox.Size = new System.Drawing.Size(866, 49);
            this.DescriptionTextBox.TabIndex = 0;
            this.DescriptionTextBox.TabStop = false;
            this.DescriptionTextBox.Text = resources.GetString("DescriptionTextBox.Text");
            //
            // ConnectionStringLabel
            //
            this.ConnectionStringLabel.AutoSize = true;
            this.ConnectionStringLabel.Location = new System.Drawing.Point(10, 82);
            this.ConnectionStringLabel.Name = "ConnectionStringLabel";
            this.ConnectionStringLabel.Size = new System.Drawing.Size(141, 17);
            this.ConnectionStringLabel.TabIndex = 1;
            this.ConnectionStringLabel.Text = "Connection String:";
            //
            // ConnectionStringTextBox
            //
            this.ConnectionStringTextBox.Location = new System.Drawing.Point(13, 115);
            this.ConnectionStringTextBox.Name = "ConnectionStringTextBox";
            this.ConnectionStringTextBox.Size = new System.Drawing.Size(863, 24);
            this.ConnectionStringTextBox.TabIndex = 1;
            //
            // PopulateButton
            //
            this.PopulateButton.Location = new System.Drawing.Point(368, 167);
            this.PopulateButton.Name = "PopulateButton";
            this.PopulateButton.Size = new System.Drawing.Size(115, 39);
            this.PopulateButton.TabIndex = 0;
            this.PopulateButton.Text = "&Populate";
            this.PopulateButton.UseVisualStyleBackColor = true;
            this.PopulateButton.Click += new System.EventHandler(this.PopulateButton_Click);
            //
            // PopulateAlwaysEncryptedDataMain
            //
            this.AutoScaleDimensions = new System.Drawing.SizeF(8F, 16F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(891, 228);
            this.Controls.Add(this.PopulateButton);
            this.Controls.Add(this.ConnectionStringTextBox);
            this.Controls.Add(this.ConnectionStringLabel);
            this.Controls.Add(this.DescriptionTextBox);
            this.Font = new System.Drawing.Font("Verdana", 10F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedSingle;
            this.Margin = new System.Windows.Forms.Padding(3, 4, 3, 4);
            this.MaximizeBox = false;
            this.Name = "PopulateAlwaysEncryptedDataMain";
            this.SizeGripStyle = System.Windows.Forms.SizeGripStyle.Hide;
            this.Text = "Populate Always Encrypted Data";
            this.FormClosing += new System.Windows.Forms.FormClosingEventHandler(this.PopulateAlwaysEncryptedDataMain_FormClosing);
            this.Load += new System.EventHandler(this.PopulateAlwaysEncryptedDataMain_Load);
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.TextBox DescriptionTextBox;
        private System.Windows.Forms.Label ConnectionStringLabel;
        private System.Windows.Forms.TextBox ConnectionStringTextBox;
        private System.Windows.Forms.Button PopulateButton;
    }
}

