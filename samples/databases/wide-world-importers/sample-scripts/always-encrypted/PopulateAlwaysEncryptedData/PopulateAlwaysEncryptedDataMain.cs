using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Data.SqlClient;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace PopulateAlwaysEncryptedData
{
    public partial class PopulateAlwaysEncryptedDataMain : Form
    {
        public PopulateAlwaysEncryptedDataMain()
        {
            InitializeComponent();
        }

        private void PopulateAlwaysEncryptedDataMain_Load(object sender, EventArgs e)
        {
            ConnectionStringTextBox.Text = Properties.Settings.Default.WWI_ConnectionString;
            if (ConnectionStringTextBox.Text.Length == 0)
            {
                ConnectionStringTextBox.Text = "Server=.;Database=WideWorldImporters;Integrated Security=true;Column Encryption Setting=enabled";
            }
        }

        private void PopulateAlwaysEncryptedDataMain_FormClosing(object sender, FormClosingEventArgs e)
        {
            Properties.Settings.Default.WWI_ConnectionString = ConnectionStringTextBox.Text;
            Properties.Settings.Default.Save();
        }

        private void PopulateButton_Click(object sender, EventArgs e)
        {
            int supplierID;

            try
            {
                using (SqlConnection con = new SqlConnection(ConnectionStringTextBox.Text))
                {
                    DataSet ds = new DataSet();

                    con.Open();

                    using (SqlCommand cmd = new SqlCommand())
                    {
                        cmd.Connection = con;
                        cmd.CommandText = "SELECT SupplierID FROM Purchasing.Suppliers ORDER BY SupplierID;";

                        SqlDataAdapter da = new SqlDataAdapter(cmd);
                        da.Fill(ds, "Suppliers");
                    }

                    using (SqlCommand cmd = new SqlCommand())
                    {
                        cmd.Connection = con;
                        cmd.CommandText = "TRUNCATE TABLE Purchasing.Supplier_PrivateDetails;";
                        cmd.ExecuteNonQuery();

                        cmd.CommandText = "INSERT Purchasing.Supplier_PrivateDetails "
                                        + "(SupplierID, NationalID, CreditCardNumber, ExpiryDate) "
                                        + "VALUES (@SupplierID, @NationalID, @CreditCardNumber, @ExpiryDate);";
                        cmd.Parameters.Add(new SqlParameter("@SupplierID", SqlDbType.Int));
                        cmd.Parameters.Add(new SqlParameter("@NationalID", SqlDbType.NVarChar, 30));
                        cmd.Parameters.Add(new SqlParameter("@CreditCardNumber", SqlDbType.NVarChar, 30));
                        cmd.Parameters.Add(new SqlParameter("@ExpiryDate", SqlDbType.NVarChar, 5));

                        DataTable suppliers = ds.Tables["Suppliers"];
                        for (int counter = 0;counter < suppliers.Rows.Count;counter++)
                        {
                            supplierID = (int) suppliers.Rows[counter]["SupplierID"];
                            cmd.Parameters["@SupplierID"].SqlValue = supplierID;
                            cmd.Parameters["@NationalID"].SqlValue = CreateNationalID();
                            cmd.Parameters["@CreditCardNumber"].SqlValue = CreateCreditCardNumber();
                            cmd.Parameters["@ExpiryDate"].SqlValue = CreateExpiryDate();
                            cmd.ExecuteNonQuery();
                        }
                    }

                    con.Close();

                    MessageBox.Show("Inserted " + ds.Tables["Suppliers"].Rows.Count.ToString() + " rows");
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Unable to populate the data. The returned error was:\n" + ex.ToString());
            }
        }

        private string CreateNationalID()
        {
            string nationalID = "";
            Random rnd = new Random();

            for (int counter = 0;counter < 8;counter++)
            {
                int digit = rnd.Next(0, 9);
                nationalID += digit.ToString();
            }

            return nationalID;
        }

        private string CreateCreditCardNumber()
        {
            string creditCardNumber = "";
            Random rnd = new Random();

            for (int counter = 0; counter < 16; counter++)
            {
                int digit = rnd.Next(0, 9);
                creditCardNumber += digit.ToString();
                if (counter == 3 || counter == 7 || counter == 11)
                {
                    creditCardNumber += "-";
                }
            }

            return creditCardNumber;
        }
        private string CreateExpiryDate()
        {
            string expiryDate = "";
            Random rnd = new Random();

            int month = rnd.Next(1, 12);
            string monthString = month.ToString();
            if (monthString.Length == 1) monthString = "0" + monthString;

            int currentYear = DateTime.Now.Year - 2000;
            int year = rnd.Next(currentYear, currentYear + 4);
            string yearString = year.ToString();
            if (yearString.Length == 1) yearString = "0" + yearString;

            expiryDate = monthString + "/" + yearString;

            return expiryDate;
        }
    }
}
