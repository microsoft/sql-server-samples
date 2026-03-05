using System;
using Microsoft.Azure.Devices.Client;
using Newtonsoft.Json;
using SqlDbEdgeDemo.Web.Models;
using SqlDbEdgeDemo.Web.Options;
using SqlDbEdgeDemo.Web.Services.Interfaces;

namespace SqlDbEdgeDemo.Web.Services
{
  public class IoTHubModuleTwinService : IIoTHubModuleTwinService
  {
    private static IoTHubOptions _options;
    private static ModuleClient Client = null;

    public IoTHubModuleTwinService(IoTHubOptions options)
    {
      _options = options;
    }

    public DeviceModel GetTwinDeviceStatus()
    {
      Connect();
      var twinTask = Client.GetTwinAsync();
      twinTask.Wait();
      var twin = twinTask.Result;
      var properties = JsonConvert.DeserializeObject<IoTHubModuleTwinReportedProperty>(twin.Properties.Reported.ToJson());
      return new DeviceModel
      {
        Alert = string.Equals(properties.Alert, "start", StringComparison.OrdinalIgnoreCase)
      };
    }

    private void Connect()
    {
      if (Client == null)
      {
        try
        {
          Client = ModuleClient.CreateFromConnectionString(_options.ModuleConnectionString, TransportType.Amqp);
        }
        catch (Exception e)
        {
          Client = null; // Set to null for reconection
          throw e;
        }
      }
    }
  }
}
