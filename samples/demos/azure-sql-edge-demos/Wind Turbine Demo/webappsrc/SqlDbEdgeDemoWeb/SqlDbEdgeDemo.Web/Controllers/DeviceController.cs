using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using SqlDbEdgeDemo.Web.Models;
using SqlDbEdgeDemo.Web.Services.Interfaces;

namespace SqlDbEdgeDemo.Web.Controllers
{
  [Route("api/[controller]")]
  public class DeviceController : Controller
  {
    private static IIoTHubModuleTwinService _ioTHubModuleTwinService;

    public DeviceController(IIoTHubModuleTwinService ioTHubModuleTwinService)
    {
      _ioTHubModuleTwinService = ioTHubModuleTwinService;
    }

    [HttpGet]
    public ActionResult<DeviceModel> GetStatus()
    {
      return Ok(_ioTHubModuleTwinService.GetTwinDeviceStatus());
    }
  }
}
