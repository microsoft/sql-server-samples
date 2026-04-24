using System;

namespace SensorModule.Models
{
  public class Sensor
  {
    public Guid Id { get; set; } = Guid.NewGuid();

    public string Type { get; set; }
  }
}