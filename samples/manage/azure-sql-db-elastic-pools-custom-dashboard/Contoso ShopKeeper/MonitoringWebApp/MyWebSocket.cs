using System;
using System.Text;
using Owin.WebSocket;
using System.Threading.Tasks;
using System.Net.WebSockets;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Diagnostics;
using System.Collections;
using System.Collections.Generic;

namespace MonitoringWebApp
{

    public class MyWebSocket : WebSocketConnection
    {
        string _poolConnectionString = ConfigurationManager.ConnectionStrings["AdventureWorksCycles"].ConnectionString;
        string[] _selectedDatabaseNames = ConfigurationManager.AppSettings["SelectedDatabaseNames"].Split(',');
        string _poolName = ConfigurationManager.AppSettings["PoolName"];

        System.Timers.Timer t = new System.Timers.Timer(5000);

        void Init()
        {
            t.AutoReset = false;
            t.Elapsed += TimerElapsed;
            RefreshTelemetry();
            t.Start();
        }

        private void TimerElapsed(object sender, System.Timers.ElapsedEventArgs e)
        {
            RefreshTelemetry();
            t.Start();
        }

        private void RefreshTelemetry()
        {
            SendPerDatabaseSamples();

            SendAllDatabasesSamples();

            SendAllPoolSamples(_poolName);
        }

        private void SendPerDatabaseSamples()
        {
            Dictionary<string, EDtuMetric> samples = new Dictionary<string, EDtuMetric>();
            foreach (string databaseName in _selectedDatabaseNames)
            {
                samples.Add(databaseName, GetDbStats(databaseName));
            }

            var payload = new
            {
                type = "dm_db_resource_stats",
                telemetry = samples
            };

            string json = JsonConvert.SerializeObject(payload);
            SendText(Encoding.UTF8.GetBytes(json), true);
        }

        private void SendAllDatabasesSamples()
        {
            var samples = GetAllDbStats(_poolName);

            var payload = new
            {
                type = "resource_stats",
                telemetry = samples
            };

            string json = JsonConvert.SerializeObject(payload);
            SendText(Encoding.UTF8.GetBytes(json), true);
        }

        private void SendAllPoolSamples(string poolName)
        {
            var samples = GetPoolStats(poolName);

            var payload = new
            {
                type = "elastic_pool_resource_stats",
                telemetry = samples
            };

            string json = JsonConvert.SerializeObject(payload);
            SendText(Encoding.UTF8.GetBytes(json), true);
        }


        private EDtuMetric GetDbStats(string databaseName)
        {
            EDtuMetric result = null;

            SqlConnectionStringBuilder sqlConnBuilder = new SqlConnectionStringBuilder(_poolConnectionString);
            sqlConnBuilder.InitialCatalog = databaseName;
            string connectionString = sqlConnBuilder.ToString();

            try
            {
                using (SqlConnection conn = new SqlConnection(connectionString))
                {
                    conn.Open();

                    string commandText = @"SELECT Top(1)
                                        end_time,
                                        (SELECT Max(v) FROM(VALUES(avg_cpu_percent), (avg_data_io_percent), (avg_log_write_percent)) AS value(v)) AS [avg_DTU_percent],
                                        dtu_limit
                                    FROM sys.dm_db_resource_stats";

                    using (SqlCommand cmd = new SqlCommand(commandText, conn))
                    {
                        cmd.CommandType = System.Data.CommandType.Text;
                        SqlDataReader reader = cmd.ExecuteReader();
                        if (reader.Read())
                        {

                            result = new EDtuMetric()
                            {
                                EndTime = reader.GetDateTime(0),
                                EDTUPercent = reader.GetDecimal(1),
                                EDTULimit = reader.GetInt32(2)
                            };

                        }

                    }
                }
            }
            catch (Exception ex)
            {
                SendError(ex.Message);
            }

            return result;
        }

        private Dictionary<string, EDtuMetric> GetAllDbStats(string poolName)
        {
            Dictionary<string, EDtuMetric> samples = new Dictionary<string, EDtuMetric>();

            SqlConnectionStringBuilder sqlConnBuilder = new SqlConnectionStringBuilder(_poolConnectionString);
            sqlConnBuilder.InitialCatalog = "master";
            string connectionString = sqlConnBuilder.ToString();

            try
            {
                using (SqlConnection conn = new SqlConnection(connectionString))
                {
                    conn.Open();

                    string commandText = @"SELECT r1.database_name, r1.end_time,
                                            (SELECT Max(v)
                                            FROM (VALUES (avg_cpu_percent), (avg_data_io_percent), (avg_log_write_percent)) AS
                                            value(v)) AS [avg_DTU_percent],
                                            dtu_limit
                                        FROM sys.resource_stats r1
                                        JOIN (SELECT max(end_time) end_time, database_name
						                                        FROM sys.resource_stats
						                                        WHERE database_name in (
												                                        SELECT d.name
												                                        FROM sys.databases d
												                                        JOIN sys.database_service_objectives slo
												                                        ON d.database_id = slo.database_id
												                                        WHERE elastic_pool_name = @PoolName
												                                        )
						                                        GROUP BY database_name) r2
                                        ON r1.database_name = r2.database_name AND r1.end_time = r2.end_time
                                        ORDER BY end_time desc
                                        ;  ";

                    using (SqlCommand cmd = new SqlCommand(commandText, conn))
                    {
                        cmd.CommandType = System.Data.CommandType.Text;
                        cmd.Parameters.Add(new SqlParameter("@PoolName", poolName));
                        SqlDataReader reader = cmd.ExecuteReader();
                        while (reader.Read())
                        {

                            var result = new EDtuMetric()
                            {
                                EndTime = reader.GetDateTime(1),
                                EDTUPercent = reader.GetDecimal(2),
                                EDTULimit = reader.GetInt32(3)
                            };

                            samples.Add(reader.GetString(0), result);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                SendError(ex.Message);
            }

            return samples;
        }



        private List<EDtuMetric> GetPoolStats(string poolName)
        {
            List<EDtuMetric> results = new List<EDtuMetric>();

            SqlConnectionStringBuilder sqlConnBuilder = new SqlConnectionStringBuilder(_poolConnectionString);
            sqlConnBuilder.InitialCatalog = "master";
            string connectionString = sqlConnBuilder.ToString();

            try
            {
                using (SqlConnection conn = new SqlConnection(connectionString))
                {
                    conn.Open();

                    string commandText = @"SELECT end_time,
	                                          (SELECT Max(v)
	                                           FROM (VALUES (avg_cpu_percent), (avg_data_io_percent), (avg_log_write_percent)) AS
	                                           value(v)) AS [avg_DTU_percent],
	                                           elastic_pool_dtu_limit
                                        FROM sys.elastic_pool_resource_stats
                                        WHERE elastic_pool_name = @PoolName
                                        ORDER BY end_time; ";

                    using (SqlCommand cmd = new SqlCommand(commandText, conn))
                    {
                        cmd.CommandType = System.Data.CommandType.Text;
                        cmd.Parameters.Add(new SqlParameter("@PoolName", poolName));

                        SqlDataReader reader = cmd.ExecuteReader();
                        while (reader.Read())
                        {
                            var result = new EDtuMetric()
                            {
                                EndTime = reader.GetDateTime(0),
                                EDTUPercent = reader.GetDecimal(1),
                                EDTULimit = reader.GetInt32(2)
                            };

                            results.Add(result);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                SendError(ex.Message);
            }

            return results;
        }

        private void SendError(string message)
        {
            var payload = new
            {
                type = "error",
                error = message
            };
            SendText(Encoding.UTF8.GetBytes(JsonConvert.SerializeObject(payload)), true);
        }

        private class EDtuMetric
        {
            public DateTime EndTime;
            public decimal EDTUPercent;
            public int EDTULimit;
        }

        public override void OnOpen()
        {
            Init();
        }

        public override void OnClose(WebSocketCloseStatus? closeStatus, string closeStatusDescription)
        {

        }

    }
}