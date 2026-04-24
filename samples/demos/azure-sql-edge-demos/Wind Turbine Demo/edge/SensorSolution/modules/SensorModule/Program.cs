namespace SensorModule
{
    using System;
    using System.IO;
    using System.Runtime.InteropServices;
    using System.Runtime.Loader;
    using System.Security.Cryptography.X509Certificates;
    using System.Text;
    using System.Threading;
    using System.Threading.Tasks;
    using Microsoft.Azure.Devices.Client;
    using Microsoft.Azure.Devices.Client.Transport.Mqtt;
    using Microsoft.Azure.Devices.Shared;
    using Newtonsoft.Json;
    using SensorModule.Services;
    using SensorModule.Services.Interfaces;

    class Program
    {
        private static IDataGeneratorService _datageneratorservice;
        private static IDataStoreService _datastoreservice;
        private static ModuleClient _ioTHubModuleClient;
        static int PushTimeInterval { get; set; } = 5000;
        static bool StopWake { get; set; } = false;
        static bool BlockedDataGeneration { get; set; } = false;

        static async Task Main(string[] args)
        {
            _datageneratorservice = new DataGeneratorService();
            _datastoreservice = new DataStoreService();

            await Init();

            try
            {
                Console.WriteLine("Truncating sensors table before start pushing data");
                _datastoreservice.TruncateRealtimeSensorRecordTable();
            }
            catch(Exception e)
            {
                Console.WriteLine("Error truncating table: " + e.Message);
            }

            Console.WriteLine($"Starting writing realtime records with {PushTimeInterval} millisecond interval to database...");

            while (true)
            {
                if (!BlockedDataGeneration)
                {
                  var records = _datageneratorservice.GenerateRealTimeSensorRecords(StopWake);
                  Console.WriteLine($"[{DateTime.Now}] Writing records to db.");
                  _datastoreservice.WriteSensorRecordsToDB(records);
                }
                await Task.Delay(PushTimeInterval);
            }
        }

        /// <summary>
        /// Handles cleanup operations when app is cancelled or unloads
        /// </summary>
        public static Task WhenCancelled(CancellationToken cancellationToken)
        {
            var tcs = new TaskCompletionSource<bool>();
            cancellationToken.Register(s => ((TaskCompletionSource<bool>)s).SetResult(true), tcs);
            return tcs.Task;
        }

        /// <summary>
        /// Initializes the ModuleClient and sets up the callback to receive
        /// messages containing temperature information
        /// </summary>
        static async Task Init()
        {
            _ioTHubModuleClient = await ModuleClient.CreateFromEnvironmentAsync();
            _ioTHubModuleClient.SetDesiredPropertyUpdateCallbackAsync(OnDesiredPropertyChanged, null).Wait();
            await SetAlertStatus("start");
            Console.WriteLine("IoT Hub module client initialized.");

            // Read from the module twin's desired properties
            var moduleTwin = await _ioTHubModuleClient.GetTwinAsync();
            await OnDesiredPropertyChanged(moduleTwin.Properties.Desired, _ioTHubModuleClient);
        }

        static async Task SetAlertStatus(string status)
        {
            Console.WriteLine($"Sending alert as reported property with value `{status}`.");
            TwinCollection reportedProperties = new TwinCollection
            {
              ["alert"] = status
            };

            await _ioTHubModuleClient.UpdateReportedPropertiesAsync(reportedProperties);
        }

        static async Task OnDesiredPropertyChanged(TwinCollection desiredProperties, object userContext)
        {
            try
            {
                Console.WriteLine("Desired property change:");
                Console.WriteLine(JsonConvert.SerializeObject(desiredProperties));

                if (desiredProperties["SqlConnnectionString"]!=null)
                {
                    var connectionString = desiredProperties["SqlConnnectionString"];
                    Console.WriteLine($"Updating SqlConnectionString: {connectionString}");
                    _datastoreservice.SetSqlConnectionString($"{connectionString}");
                }

                if (desiredProperties["PushTimeInterval"]!=null)
                {
                    var pushTimeInterval = desiredProperties["PushTimeInterval"];
                    Console.WriteLine($"Updating PushTimeInterval to: {pushTimeInterval}");
                    PushTimeInterval = desiredProperties["PushTimeInterval"];
                }

                if (desiredProperties["Alert"]!=null)
                {
                    var alertStatus = desiredProperties["Alert"];
                    Console.WriteLine($"Will update alert from property to: {alertStatus}");
                    await SetAlertStatus($"{alertStatus}");
                }

                if (desiredProperties["OnnxModelUrl"]!=null)
                {
                    var onnxModelUrl = $"{desiredProperties["OnnxModelUrl"]}";
                    if (!string.IsNullOrEmpty(onnxModelUrl))
                    {
                        // Blocking data generation while we run the model
                        BlockedDataGeneration = true;
                        Console.WriteLine($"Updating OnnxModelUrl: {onnxModelUrl}");
                        // Re-Create the Model Table in DB to keep only one record of the model
                        _datastoreservice.DropAndCreateModelTable();
                        // Insert the model into the created table
                        _datastoreservice.InsertModelFromUrl($"{onnxModelUrl}");
                        // Get model prediction of top rows
                        var modelResult = _datastoreservice.GetModelResult();
                        Console.WriteLine($"Model prediction got a value of: {modelResult}");
                        // Stabilize the data if result is > 0
                        StopWake = modelResult > 0;
                        if (StopWake)
                        {
                          Console.WriteLine($"Stabilizing the data.");
                          // Clear the buffer to accelarate stabilization of the data
                          ClearBuffer();
                        }
                        // If result is > 0 we need to stop the alert
                        var alertStatus = modelResult > 0 ? "stop":"start";
                        Console.WriteLine($"Setting Alert to: {alertStatus}");
                        // Update the twin module property to get new value in client
                        await SetAlertStatus(alertStatus);
                        // Unblock the data generation after running the model
                        BlockedDataGeneration = false;
                    }
                    else
                    {
                      BlockedDataGeneration = true;
                      StopWake = false;
                      Console.WriteLine($"Is data stabilized? {StopWake}");
                      _datastoreservice.TruncateRealtimeSensorRecordTable();
                      ClearBuffer();
                      BlockedDataGeneration = false;
                    }
                }
                else
                {
                  BlockedDataGeneration = true;
                  StopWake = false;
                  Console.WriteLine($"Is data stabilized? {StopWake}");
                  _datastoreservice.TruncateRealtimeSensorRecordTable();
                  ClearBuffer();
                  BlockedDataGeneration = false;
                }
            }
            catch (AggregateException ex)
            {
                foreach (Exception exception in ex.InnerExceptions)
                {
                    Console.WriteLine();
                    Console.WriteLine("Error when receiving desired property: {0}", exception);
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine();
                Console.WriteLine("Error when receiving desired property: {0}", ex);
            }
        }

        static void ClearBuffer()
        {
            _datageneratorservice.ClearBuffer();
            // Add new records as a reference for the next record generation
            _datageneratorservice.GenerateRealTimeSensorRecords(StopWake);
            _datageneratorservice.GenerateRealTimeSensorRecords(StopWake);
        }
    }
}
