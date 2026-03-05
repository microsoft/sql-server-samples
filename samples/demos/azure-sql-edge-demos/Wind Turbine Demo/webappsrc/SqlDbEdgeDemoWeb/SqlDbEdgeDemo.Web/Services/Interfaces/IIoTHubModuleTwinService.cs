using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using SqlDbEdgeDemo.Web.Models;

namespace SqlDbEdgeDemo.Web.Services.Interfaces
{
  public interface IIoTHubModuleTwinService
  {
    DeviceModel GetTwinDeviceStatus();
  }
}
