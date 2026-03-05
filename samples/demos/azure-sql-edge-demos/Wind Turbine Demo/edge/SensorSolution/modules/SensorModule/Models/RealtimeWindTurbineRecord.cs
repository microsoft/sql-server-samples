using SensorModule.Models.Interfaces;
using System;
using System.ComponentModel.DataAnnotations;

namespace SensorModule.Models
{
  public class RealtimeWindTurbineRecord : IWindTurbineRecord
  {
    [Key]
    public Guid RecordId { get; set; }
    public int TurbineId { get; set; }
    public Guid TurbineGuid { get; set; }
    public double WindSpeedStdDev { get; set; }
    public double TurbineSpeedStdDev { get; set; }
    public double OverallWindDirection { get; set; }
    public double TurbineWindDirection { get; set; }
    public double WindSpeedAverage { get; set; }
    public double WindTempAverage { get; set; }
    public bool Precipitation { get; set; }
    public double GearboxOilLevel { get; set; }
    public double GearboxOilTemp { get; set; }
    public double GeneratorActivePower { get; set; }
    public double GeneratorSpeed { get; set; }
    public double GeneratorTemp { get; set; }
    public double GeneratorTorque { get; set; }
    public double GridFrequency { get; set; }
    public double GridVoltage { get; set; }
    public double HydraulicOilPressure { get; set; }
    public double NacelleAngle { get; set; }
    public double PitchAngle { get; set; }
    public double Vibration { get; set; }
    public double TurbineSpeedAverage { get; set; }
    public DateTime Timestamp { get; set; }
  }
}
