using ContosoHR.Models;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using System;
using System.Collections.Generic;
using Microsoft.Data.SqlClient;
using Microsoft.Data.SqlClient.AlwaysEncrypted.AzureKeyVaultProvider;
using Azure.Core;
using Azure.Identity;

namespace ContosoHR
{
    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
            InitializeAzureKeyVaultProvider();
        }

        public IConfiguration Configuration { get; }

        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {
            string s = Configuration.GetConnectionString("ContosoHRDatabase");
            services.AddDbContext<ContosoHRContext>(options =>
                options.UseSqlServer(Configuration.GetConnectionString("ContosoHRDatabase")));
            services.AddControllers();
            services.AddRazorPages();
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }
            else
            {
                app.UseExceptionHandler("/Error");
                // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
                app.UseHsts();
            }

            app.UseHttpsRedirection();
            app.UseStaticFiles();

            app.UseRouting();

            app.UseAuthorization();

            app.UseEndpoints(endpoints =>
            {
                endpoints.MapControllers();
                endpoints.MapRazorPages();
            });
        }

        // Initialize the Azure Key Vault provider for Always Encrypted. Required if column master keys are stored in Azure Key Vault.
        private void InitializeAzureKeyVaultProvider()
        {
            TokenCredential tokenCredential = null;
            SqlConnectionStringBuilder builder = new SqlConnectionStringBuilder(Configuration.GetConnectionString("ContosoHRDatabase"));
            if (builder.Authentication == SqlAuthenticationMethod.ActiveDirectoryManagedIdentity)
            {
                // If the application uses a managed identity to talk to Azure SQL Database, use the managed identity for Azure Key Vault too.
                tokenCredential = new ManagedIdentityCredential();
            }
            else {
                // Assume a managed identity is not available to the app. Instead, use a client id/secret to authenticate to Azure Key Vault.
                // Fetch client id, secret, tenant id from the configuration.
                // It is recommended you specify these parameters in secrets.json.
                // See https://docs.microsoft.com/aspnet/core/security/app-secrets?view=aspnetcore-5.0&tabs=windows on how store secrets in secrets.json.
                var clientId = Configuration["ClientId"];
                var secret = Configuration["Secret"];
                var tenantId = Configuration["TenantId"];
                tokenCredential = new ClientSecretCredential(tenantId, clientId, secret);
            }
            SqlColumnEncryptionAzureKeyVaultProvider sqlColumnEncryptionAzureKeyVaultProvider =
                new SqlColumnEncryptionAzureKeyVaultProvider(tokenCredential);
            SqlConnection.RegisterColumnEncryptionKeyStoreProviders(
                customProviders: new Dictionary<string, SqlColumnEncryptionKeyStoreProvider>(capacity: 1, comparer: StringComparer.OrdinalIgnoreCase)
                {
                    { SqlColumnEncryptionAzureKeyVaultProvider.ProviderName, sqlColumnEncryptionAzureKeyVaultProvider}
                }
            );
        }
    }
}
