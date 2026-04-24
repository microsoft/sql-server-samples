using System;
using System.Data.SqlClient;
using Microsoft.Azure.KeyVault;
using Microsoft.Azure.KeyVault.Models;
using Microsoft.Azure.Services.AppAuthentication;
using System.Threading.Tasks;
using System.Collections.Generic;
using System.Linq;

namespace AzureSqlEFSample
{
    class Program
    {
        static void Main(string[] args)
        {
            System.Threading.Tasks.Task task = Program.DoWork(args);
            // Becuase this program takes user input, have a long wait.
            var result = task.Wait(TimeSpan.FromMinutes(30));
        }

        static async System.Threading.Tasks.Task DoWork(string[] args)
        {
            Console.WriteLine("** C# CRUD sample with Entity Framework and Azure SQL DB**\n");

            // Build connection string
            SqlConnectionStringBuilder builder = new SqlConnectionStringBuilder();
            builder.DataSource = "your_server_name.database.windows.net";   // update me
            builder.UserID = "your_user";              // update me
            builder.Password = await GetPasswordFromKeyVault();      // taken from Key Vault
            builder.InitialCatalog = "your_db_name"; // Update me

            using (EFSampleContext context = new EFSampleContext(builder.ConnectionString))
            {
                try
                {
                    context.Database.EnsureDeleted();
                    context.Database.EnsureCreated();
                    Console.WriteLine("Created database schema from C# classes.");

                    // Create demo: Create a Task instance and save it to the database
                    Task newTask = new Task() { Title = "Ship Helsinki", IsComplete = false, DueDate = DateTime.Parse("04-01-2017") };
                    context.Tasks.Add(newTask);
                    context.SaveChanges();
                    Console.WriteLine("\nCreated Task: " + newTask.ToString());

                    // Association demo: Assign task to user

                    // Read demo: find incomplete tasks assigned to user 'Anna'
                    Console.WriteLine("\nIncomplete tasks assigned to 'Anna':");
                    var query = from t in context.Tasks
                                where t.IsComplete == false &&
                                t.AssignedTo.FirstName.Equals("Anna")
                                select t;
                    foreach (var t in query)
                    {
                        Console.WriteLine(t.ToString());
                    }

                    // Update demo: change the 'dueDate' of a task
                    Task taskToUpdate = context.Tasks.First(); // get the first task
                    Console.WriteLine("\nUpdating task: " + taskToUpdate.ToString());
                    taskToUpdate.DueDate = DateTime.Parse("06-30-2016");
                    context.SaveChanges();
                    Console.WriteLine("dueDate changed: " + taskToUpdate.ToString());

                    // Delete demo: delete all tasks with a dueDate in 2016
                    Console.WriteLine("\nDeleting all tasks with a dueDate in 2016");
                    DateTime dueDate2016 = DateTime.Parse("12-31-2016");
                    List<Task> queryResults = context.Tasks.Where(t => t.DueDate < dueDate2016).ToList();
                    foreach (Task t in queryResults)
                    {
                        Console.WriteLine("Deleting task: " + t.ToString());
                        context.Tasks.Remove(t);
                    }
                    context.SaveChanges();

                    // Show tasks after the 'Delete' operation - there should be 0 tasks
                    Console.WriteLine("\nTasks after delete:");
                    List<Task> tasksAfterDelete = (from t in context.Tasks select t).ToList<Task>();
                    if (tasksAfterDelete.Count == 0)
                    {
                        Console.WriteLine("[None]");
                    }
                    else
                    {
                        foreach (Task t in query)
                        {
                            Console.WriteLine(t.ToString());
                        }
                    }
                }
                catch (SqlException e)
                {
                    Console.WriteLine(e.ToString());
                }
            }

            Console.WriteLine("All done. Press any key to finish...");
            Console.ReadKey(true);
        }

        private static async Task<string> GetPasswordFromKeyVault()
        {
            Console.WriteLine("Trying to get Password from Key Vault.  Press a key to continue...");
            Console.ReadKey(true);
            /* The next four lines of code show you how to use AppAuthentication library to fetch secrets from your key vault */
            AzureServiceTokenProvider azureServiceTokenProvider = new AzureServiceTokenProvider();
            KeyVaultClient keyVaultClient = new KeyVaultClient(new KeyVaultClient.AuthenticationCallback(azureServiceTokenProvider.KeyVaultTokenCallback));
            SecretBundle secret = await keyVaultClient.GetSecretAsync("https://your_keyvault_name.vault.azure.net/secrets/AppSecret"); // update me
            return secret.Value;
        }
    }
}