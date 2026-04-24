namespace Microsoft.SqlServer.SmoSamples
{
    using System;
    using System.Collections.Generic;
    using System.Diagnostics;
    using System.Text;
    using Microsoft.SqlServer.Management.Smo;
    using Microsoft.VisualStudio.TestTools.UnitTesting;
    using NUnit.Framework;
    using Assert = NUnit.Framework.Assert;

    [TestClass]
    public class CollectionSamples
    {
        public VisualStudio.TestTools.UnitTesting.TestContext TestContext { get; set; }

        /// <summary>
        /// SetDefaultInitFields tells the Server object which properties to include in the initial query
        /// to populate of a given object type when initialized a collection of that type.
        /// The test demonstrates the effect of using this call to enumerate Tables when accessing the FileGroup
        /// property of each Table object
        /// </summary>
        [TestMethod]
        public void Collection_iteration_is_faster_with_SetDefaultInitFields()
        {
            using (var connectionMetrics = ConnectionMetrics.SetupMeasuredConnection(TestContext, 50))
            {
                var server = new Management.Smo.Server(connectionMetrics.ServerConnection);
                var database = server.Databases[TestContext.GetTestDatabaseName()];
                connectionMetrics.Reset();
                foreach (Table table in database.Tables)
                {
                    // Accessing FileGroup triggers a query to fetch it
                    Trace.TraceInformation(
                        $"Unoptimized table Name: {table.Name}\tSchema:{table.Schema}\tFileGroup:{table.FileGroup}");
                }

                var unoptimizedMetrics = (QueryCount: connectionMetrics.QueryCount,
                    BytesSent: connectionMetrics.BytesSent, BytesRead: connectionMetrics.BytesRead,
                    ConnectionCount: connectionMetrics.ConnectionCount);
                Trace.TraceInformation(string.Join($"{Environment.NewLine}\t", new[]
                {
                    "Unoptimized metrics:",
                    $"QueryCount:{unoptimizedMetrics.QueryCount}", $"ConnectionCount:{unoptimizedMetrics.ConnectionCount}",
                    $"BytesSent:{unoptimizedMetrics.BytesSent}", $"BytesRead:{unoptimizedMetrics.BytesRead}"
                }));

                connectionMetrics.Reset();
                server.SetDefaultInitFields(typeof(Table), "Name", "Schema", "FileGroup");
                database.Tables.Refresh();
                foreach (Table table in database.Tables)
                {
                    // The FileGroup property is already populated, so no extra query is needed
                    Trace.TraceInformation(
                        $"Optimized table Name: {table.Name}\tSchema:{table.Schema}\tFileGroup:{table.FileGroup}");
                }

                var optimizedMetrics = (QueryCount: connectionMetrics.QueryCount,
                    BytesSent: connectionMetrics.BytesSent, BytesRead: connectionMetrics.BytesRead,
                    ConnectionCount: connectionMetrics.ConnectionCount);
                Trace.TraceInformation(string.Join($"{Environment.NewLine}\t", new[]
                {
                    "Optimized Metrics:",
                    $"QueryCount:{optimizedMetrics.QueryCount}", $"ConnectionCount:{optimizedMetrics.ConnectionCount}",
                    $"BytesSent:{optimizedMetrics.BytesSent}", $"BytesRead:{optimizedMetrics.BytesRead}"
                }));
                Assert.That(optimizedMetrics.BytesRead, Is.LessThan(unoptimizedMetrics.BytesRead), "BytesRead");
                Assert.That(optimizedMetrics.BytesSent, Is.LessThan(unoptimizedMetrics.BytesSent), "BytesSent");
                Assert.That(optimizedMetrics.ConnectionCount, Is.AtMost(unoptimizedMetrics.ConnectionCount), "ConnectionCount");
                Assert.That(optimizedMetrics.QueryCount, Is.LessThan(unoptimizedMetrics.QueryCount), "QueryCount");
            }
        }
    }
}
