using Belgrade.SqlClient;
using Belgrade.SqlClient.SqlDb;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using ProductCatalog.Models;
using Serilog;
using Serilog.Sinks.MSSqlServer;
using System;
using System.Data.SqlClient;
using System.Linq;

using NLog.Extensions.Logging;
using NLog.Web;

namespace ProductCatalog
{
    public class Startup
    {
        public Startup(IHostingEnvironment env)
        {
            // Deprecated way to initialize NLog form nlog.config, but works if you don't copy file to /bin.
            //env.ConfigureNLog("nlog.config");

            var builder = new ConfigurationBuilder()
                .SetBasePath(env.ContentRootPath)
                .AddJsonFile("appsettings.json", optional: true, reloadOnChange: true)
                .AddJsonFile($"appsettings.{env.EnvironmentName}.json", optional: true)
                .AddEnvironmentVariables();
            Configuration = builder.Build();

            // Enable this if you want to log into local folder as newline-delimited JSON
            //Log.Logger = new LoggerConfiguration()
            //    .WriteTo.RollingFile(new Serilog.Formatting.Json.JsonFormatter(), System.IO.Path.Combine(env.ContentRootPath, "logs\\log-{Date}.ndjson"))
            //    .CreateLogger();

            var columnOptions = new ColumnOptions();
            // Don't include the Properties XML column.
            columnOptions.Store.Remove(StandardColumn.Id);
            columnOptions.Store.Remove(StandardColumn.Properties);
            columnOptions.Store.Remove(StandardColumn.MessageTemplate);
            columnOptions.Store.Remove(StandardColumn.Exception);
            columnOptions.TimeStamp.ColumnName = "EventTime";
            // Do include the log event data as JSON.
            columnOptions.Store.Add(StandardColumn.LogEvent);

            Log.Logger = new LoggerConfiguration()
                .WriteTo.MSSqlServer(Configuration["ConnectionStrings:BelgradeDemo"], "Logs", columnOptions: columnOptions, autoCreateSqlTable: false)
                .CreateLogger();
        }

        public IConfigurationRoot Configuration { get; }

        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {
            string ConnString = Configuration["ConnectionStrings:BelgradeDemo"];

            services.AddDbContext<ProductCatalogContext>(options => options.UseSqlServer(new SqlConnection(ConnString)));

            // Adding data access services/components.
            services.AddTransient<IQueryPipe>(
                sp => new QueryPipe(new SqlConnection(ConnString))
                           //.AddRls("CompanyID",() => GetCompanyIdFromSession(sp))
                );

            services.AddTransient<ICommand>(
                sp => new Command(new SqlConnection(ConnString))
                           //.AddRls("CompanyID", () => GetCompanyIdFromSession(sp))
                );

            //// Add framework services.
            services.AddSingleton<IHttpContextAccessor, HttpContextAccessor>();

            services.AddLogging();
            services.AddSession();
            services.AddMvc();
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IHostingEnvironment env, ILoggerFactory loggerFactory)
        {
            loggerFactory.AddConsole(Configuration.GetSection("Logging"));
            loggerFactory.AddDebug();
            loggerFactory.AddSerilog();

            app.UseSession();
            app.UseStaticFiles();
            app.UseMvc(routes =>
            {
                routes.MapRoute(
                    name: "default",
                    template: "{controller=ProductCatalog}/{action=Index}");
            });

        }

        /// <summary>
        /// Utility method that takes CompanyID from HttpSession.
        /// You need to add: services.AddSingleton<IHttpContextAccessor, HttpContextAccessor>();
        /// </summary>
        /// <param name="serviceProvider">IServiceProvider interface.</param>
        /// <returns>Session value</returns>
        private static string GetCompanyIdFromSession(IServiceProvider serviceProvider)
        {
            var session = serviceProvider.GetServices<IHttpContextAccessor>().First().HttpContext.Session;
            return session.GetString("CompanyID") ?? "-1";
        }
    }
}
