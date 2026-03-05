using System;
using System.Collections.Generic;
using SensorModule.Models;

namespace SensorModule
{
  public static class Constants
  {
    public static class Sensors
    {
      public const string WindSpeedStdDev = "WindSpeedStdDev";
      public const string TurbineSpeedStdDev = "TurbineSpeedStdDev";
      public const string OverallWindDirection = "OverallWindDirection";
      public const string TurbineWindDirection = "TurbineWindDirection";
      public const string WindSpeedAverage = "WindSpeedAverage";
      public const string WindTempAverage = "WindTempAverage";
      public const string GearboxOilLevel = "GearboxOilLevel";
      public const string GearboxOilTemp = "GearboxOilTemp";
      public const string GeneratorActivePower = "GeneratorActivePower";
      public const string GeneratorSpeed = "GeneratorSpeed";
      public const string GeneratorTemp = "GeneratorTemp";
      public const string GeneratorTorque = "GeneratorTorque";
      public const string GridFrequency = "GridFrequency";
      public const string GridVoltage = "GridVoltage";
      public const string HydraulicOilPressure = "HydraulicOilPressure";
      public const string NacelleAngle = "NacelleAngle";
      public const string PitchAngle = "PitchAngle";
      public const string Vibration = "Vibration";
      public const string TurbineSpeedAverage = "TurbineSpeedAverage";
      public const string HatchSensor = "HatchSensor";
    }

    public static List<Sensor> SensorsList = new List<Sensor>{
      new Sensor {Id = Guid.NewGuid(), Type = Sensors.WindSpeedStdDev},
      new Sensor {Id = Guid.NewGuid(), Type = Sensors.TurbineSpeedStdDev},
      new Sensor {Id = Guid.NewGuid(), Type = Sensors.OverallWindDirection},
      new Sensor {Id = Guid.NewGuid(), Type = Sensors.TurbineWindDirection},
      new Sensor {Id = Guid.NewGuid(), Type = Sensors.WindSpeedAverage},
      new Sensor {Id = Guid.NewGuid(), Type = Sensors.WindTempAverage},
      new Sensor {Id = Guid.NewGuid(), Type = Sensors.GearboxOilLevel},
      new Sensor {Id = Guid.NewGuid(), Type = Sensors.GearboxOilTemp},
      new Sensor {Id = Guid.NewGuid(), Type = Sensors.GeneratorActivePower},
      new Sensor {Id = Guid.NewGuid(), Type = Sensors.GeneratorSpeed},
      new Sensor {Id = Guid.NewGuid(), Type = Sensors.GeneratorTemp},
      new Sensor {Id = Guid.NewGuid(), Type = Sensors.GeneratorTorque},
      new Sensor {Id = Guid.NewGuid(), Type = Sensors.GridFrequency},
      new Sensor {Id = Guid.NewGuid(), Type = Sensors.GridVoltage},
      new Sensor {Id = Guid.NewGuid(), Type = Sensors.HydraulicOilPressure},
      new Sensor {Id = Guid.NewGuid(), Type = Sensors.NacelleAngle},
      new Sensor {Id = Guid.NewGuid(), Type = Sensors.PitchAngle},
      new Sensor {Id = Guid.NewGuid(), Type = Sensors.Vibration},
      new Sensor {Id = Guid.NewGuid(), Type = Sensors.TurbineSpeedAverage},
      new Sensor {Id = Guid.NewGuid(), Type = Sensors.HatchSensor}
    };
  }
}