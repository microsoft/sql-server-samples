namespace SensorModule.Models.Interfaces
{
  public interface IWindTurbineRecord
  {
    int TurbineId { get; set; }
    double WindSpeedStdDev { get; set; }
    double TurbineSpeedStdDev { get; set; }
    double OverallWindDirection { get; set; }
    double TurbineWindDirection { get; set; }
    double WindSpeedAverage { get; set; }
    double WindTempAverage { get; set; }
    bool Precipitation { get; set; }
    double GearboxOilLevel { get; set; }
    double GearboxOilTemp { get; set; }
    double GeneratorActivePower { get; set; }
    double GeneratorSpeed { get; set; }
    double GeneratorTemp { get; set; }
    double GeneratorTorque { get; set; }
    double GridFrequency { get; set; }
    double GridVoltage { get; set; }
    double HydraulicOilPressure { get; set; }
    double NacelleAngle { get; set; }
    double PitchAngle { get; set; }
    double Vibration { get; set; }
    double TurbineSpeedAverage { get; set; }
  }
}
