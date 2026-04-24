package com.sqlsamples;

import java.sql.Connection;
import java.sql.Statement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.DriverManager;

import com.azure.identity.DefaultAzureCredentialBuilder;
import com.azure.security.keyvault.secrets.SecretClient;
import com.azure.security.keyvault.secrets.models.KeyVaultSecret;
import com.azure.security.keyvault.secrets.SecretClientBuilder;

public class App {

    public static void main(String[] args) {

        System.out.println("Connect to Azure SQL and demo Create, Read, Update and Delete operations.");

	// Get the key vault secret
	//
	System.out.println("Fetching Secret from Key Vault.");
	SecretClient secretClient = new SecretClientBuilder()
		 .vaultUrl("https://your_keyvault_name.vault.azure.net/")  // Update me
		 .credential(new DefaultAzureCredentialBuilder().build())
		 .buildClient();
	KeyVaultSecret secret = secretClient.getSecret("AppSecret");
	System.out.println("Secret Fetched.");

        // Update the connection information below
        String connectionUrl = "jdbc:sqlserver://your_server.database.windows.net;databaseName=your_db;user=your_user;password=" + secret.getValue();

        try {
            // Load Azure SQL JDBC driver and establish connection.
            System.out.print("Connecting to Azure SQL ... ");
            try (Connection connection = DriverManager.getConnection(connectionUrl)) {
                System.out.println("Done.");

		// Delete the Employees table if it exists
		try (Statement statement = connection.createStatement()) {
                    statement.executeUpdate("Drop table if exists Employees");
                    System.out.println("Done.");
		} catch (Exception e) {
	            System.out.println();
        	    e.printStackTrace();
		}

                // Create a Table and insert some sample data
                System.out.print("Creating sample table with data, press ENTER to continue...");
                System.in.read();
                String sql = new StringBuilder().append("CREATE TABLE Employees ( ")
                        .append(" Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY, ").append(" Name NVARCHAR(50), ")
                        .append(" Location NVARCHAR(50) ").append("); ")
                        .append("INSERT INTO Employees (Name, Location) VALUES ").append("(N'Jared', N'Australia'), ")
                        .append("(N'Nikita', N'India'), ").append("(N'Tom', N'Germany'); ").toString();
                try (Statement statement = connection.createStatement()) {
                    statement.executeUpdate(sql);
                    System.out.println("Done.");
                }

                // INSERT demo
                System.out.print("Inserting a new row into table, press ENTER to continue...");
                System.in.read();
                sql = new StringBuilder().append("INSERT Employees (Name, Location) ").append("VALUES (?, ?);")
                        .toString();
                try (PreparedStatement statement = connection.prepareStatement(sql)) {
                    statement.setString(1, "Jake");
                    statement.setString(2, "United States");
                    int rowsAffected = statement.executeUpdate();
                    System.out.println(rowsAffected + " row(s) inserted");
                }

                // UPDATE demo
                String userToUpdate = "Nikita";
                System.out.print("Updating 'Location' for user '" + userToUpdate + "', press ENTER to continue...");
                System.in.read();
                sql = "UPDATE Employees SET Location = N'United States' WHERE Name = ?";
                try (PreparedStatement statement = connection.prepareStatement(sql)) {
                    statement.setString(1, userToUpdate);
                    int rowsAffected = statement.executeUpdate();
                    System.out.println(rowsAffected + " row(s) updated");
                }

                // DELETE demo
                String userToDelete = "Jared";
                System.out.print("Deleting user '" + userToDelete + "', press ENTER to continue...");
                System.in.read();
                sql = "DELETE FROM Employees WHERE Name = ?;";
                try (PreparedStatement statement = connection.prepareStatement(sql)) {
                    statement.setString(1, userToDelete);
                    int rowsAffected = statement.executeUpdate();
                    System.out.println(rowsAffected + " row(s) deleted");
                }

                // READ demo
                System.out.print("Reading data from table, press ENTER to continue...");
                System.in.read();
                sql = "SELECT Id, Name, Location FROM Employees;";
                try (Statement statement = connection.createStatement();
                        ResultSet resultSet = statement.executeQuery(sql)) {
                    while (resultSet.next()) {
                        System.out.println(
                                resultSet.getInt(1) + " " + resultSet.getString(2) + " " + resultSet.getString(3));
                    }
                }
                connection.close();
                System.out.println("All done.");
            }
        } catch (Exception e) {
            System.out.println();
            e.printStackTrace();
	}
	finally {

		try (Connection connection = DriverManager.getConnection(connectionUrl)){
                // Delete the Employees table if it exists
		Statement statement = connection.createStatement();
                statement.executeUpdate("Drop table if exists Employees");
                System.out.println("Table cleaned up.");
		} catch (Exception e) {
	            System.out.println();
        	    e.printStackTrace();
		}
	}
    }
}