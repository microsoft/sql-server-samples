using System;
using System.Collections.Generic;
using System.Linq;
using SensorModule.DataStructures;
using SensorModule.Helpers;
using SensorModule.Models;
using SensorModule.Services.Interfaces;

namespace SensorModule.Services
{
  public class DataGeneratorService : IDataGeneratorService
  {
    private RingBuffer<RealtimeWindTurbineRecord> ringBuffer = new RingBuffer<RealtimeWindTurbineRecord>(100);
    private GeneratorHelper gen = new GeneratorHelper();
    private readonly Guid TurbineGuid = Guid.NewGuid();

    private RealtimeWindTurbineRecord GenerateFirstRealtimeRecord()
    {
      var windSpeed = gen.GetRandomNumber(15.0, 25.0);
      var generatorSpeed = gen.GetGeneratorSpeed(windSpeed);
      var activePower = gen.GetGeneratorActivePower(windSpeed);
      var windDirection = gen.GetRandomNumber(41.0, 44.0);
      var toReturn = new RealtimeWindTurbineRecord
      {
        RecordId = Guid.NewGuid(),
        TurbineId = 15443,
        TurbineGuid = TurbineGuid,
        GearboxOilLevel = gen.GetGearBoxOilLevel(),
        GearboxOilTemp = gen.GetGearBoxTemp(),
        GeneratorActivePower = gen.GetGeneratorActivePower(windSpeed),
        GeneratorSpeed = generatorSpeed,
        GeneratorTemp = gen.GetGeneratorStatorTemp(generatorSpeed),
        GeneratorTorque = gen.GetGeneratorTorque(generatorSpeed, activePower),
        GridFrequency = gen.GetGridFrequency(activePower),
        GridVoltage = gen.GetVoltage(activePower),
        HydraulicOilPressure = gen.GetHydraulicOilPressure(),
        NacelleAngle = gen.GetNacelleAngle(windDirection),
        PitchAngle = gen.GetPitchAngle(windSpeed),
        Vibration = gen.GetVibration(windSpeed),
        WindSpeedAverage = windSpeed,
        Precipitation = gen.GetRandomBool(20),
        WindTempAverage = gen.GetRandomNumber(-10.0, 30),
        OverallWindDirection = windDirection,
        TurbineWindDirection = windDirection * gen.GetRandomNumber(0.97, 1.03),
        TurbineSpeedAverage = windSpeed * gen.GetRandomNumber(0.97f, 1.03f),
        WindSpeedStdDev = 4.885422,
        TurbineSpeedStdDev = 4.978619,
        Timestamp = DateTime.Now
      };

      ringBuffer.PushFront(toReturn);
      return toReturn;
    }

    public void ClearBuffer()
    {
      ringBuffer = new RingBuffer<RealtimeWindTurbineRecord>(100);
    }

    private RealtimeWindTurbineRecord GenerateRegularRealtimeRecord(bool stopWake)
    {
      var currentRecords = ringBuffer.ToList();
      double windDirection = currentRecords.Select(x => x.OverallWindDirection).Average() * gen.GetRandomNumber(0.9, 1.1);
      var windSpeed = currentRecords.Select(x => x.WindSpeedAverage).Average() * gen.GetRandomNumber(0.9, 1.1);
      double turbineSpeed = windSpeed * gen.GetRandomNumber(0.25, 1.75);
      if (stopWake)
      {
        turbineSpeed = windSpeed * gen.GetRandomNumber(0.97, 1.03);
        windDirection = gen.GetRandomNumber(40.0, 45.0);
      }

      var generatorSpeed = gen.GetGeneratorSpeed(windSpeed);
      var activePower = gen.GetGeneratorActivePower(windSpeed);
      var toReturn = new RealtimeWindTurbineRecord
      {
        RecordId = Guid.NewGuid(),
        TurbineId = 15443,
        TurbineGuid = TurbineGuid,
        GearboxOilLevel = currentRecords.Select(x => x.GearboxOilLevel).Average() * gen.GetRandomNumber(0.95, 1.05),
        GearboxOilTemp = currentRecords.Select(x => x.GearboxOilTemp).Average() * gen.GetRandomNumber(0.95, 1.05),
        GeneratorActivePower = gen.GetGeneratorActivePower(windSpeed),
        GeneratorSpeed = generatorSpeed,
        GeneratorTemp = gen.GetGeneratorStatorTemp(generatorSpeed),
        GeneratorTorque = gen.GetGeneratorTorque(generatorSpeed, activePower),
        GridFrequency = gen.GetGridFrequency(activePower),
        GridVoltage = gen.GetVoltage(activePower),
        HydraulicOilPressure = gen.GetHydraulicOilPressure(),
        NacelleAngle = gen.GetNacelleAngle(windDirection),
        PitchAngle = gen.GetPitchAngle(windSpeed),
        Vibration = gen.GetVibration(windSpeed),
        WindSpeedAverage = windSpeed,
        Precipitation = gen.GetRandomBool(20),
        WindTempAverage = gen.GetRandomNumber(-10.0, 30),
        OverallWindDirection = windDirection,
        TurbineWindDirection = windDirection * gen.GetRandomNumber(0.97, 1.03),
        TurbineSpeedAverage = turbineSpeed,
        WindSpeedStdDev = gen.CalculateStandardDeviation(ringBuffer.ToList().Select(x => x.WindSpeedAverage).TakeLast(10)),
        TurbineSpeedStdDev = gen.CalculateStandardDeviation(ringBuffer.ToList().Select(x => x.TurbineSpeedAverage).TakeLast(10)),
        Timestamp = DateTime.Now
      };

      ringBuffer.PushFront(toReturn);
      return toReturn;
    }

    public RealtimeWindTurbineRecord GenerateRealTimeRecords(bool stopWake)
    {
      if (ringBuffer.IsEmpty)
      {
        return GenerateFirstRealtimeRecord();
      }
      else
      {
        return GenerateRegularRealtimeRecord(stopWake);
      }
    }

    public IEnumerable<TrainingWindTurbineRecord> GenerateTrainingRecords(int amountOfRecords)
    {
      var toReturn = new List<TrainingWindTurbineRecord>();

      for (var i = 0; i < amountOfRecords; i++)
      {
        var windDirection = gen.GetRandomNumber(0.0, 360.0);
        var windSpeed = gen.GetRandomNumber(10.0, 25.0);
        var turbineSpeed = windSpeed * gen.GetRandomNumber(0.97, 1.03);
        if (((double)i / amountOfRecords) >= 0.8)
        {
          turbineSpeed = windSpeed * gen.GetRandomNumber(0.25, 1.75);
          windDirection = gen.GetRandomNumber(40.0, 45.0);
        }

        var generatorSpeed = gen.GetGeneratorSpeed(windSpeed);
        var activePower = gen.GetGeneratorActivePower(windSpeed);
        toReturn.Add(new TrainingWindTurbineRecord
        {
          TurbineId = i,
          GearboxOilLevel = gen.GetGearBoxOilLevel(),
          GearboxOilTemp = gen.GetGearBoxTemp(),
          GeneratorActivePower = gen.GetGeneratorActivePower(windSpeed),
          GeneratorSpeed = generatorSpeed,
          GeneratorTemp = gen.GetGeneratorStatorTemp(generatorSpeed),
          GeneratorTorque = gen.GetGeneratorTorque(generatorSpeed, activePower),
          GridFrequency = gen.GetGridFrequency(activePower),
          GridVoltage = gen.GetVoltage(activePower),
          HydraulicOilPressure = gen.GetHydraulicOilPressure(),
          NacelleAngle = gen.GetNacelleAngle(windDirection),
          PitchAngle = gen.GetPitchAngle(windSpeed),
          Vibration = gen.GetVibration(windSpeed),
          WindSpeedAverage = windSpeed,
          Precipitation = gen.GetRandomBool(20),
          WindTempAverage = gen.GetRandomNumber(-10.0, 30),
          OverallWindDirection = windDirection,
          TurbineWindDirection = windDirection * gen.GetRandomNumber(0.97, 1.03),
          TurbineSpeedAverage = turbineSpeed,
          WindSpeedStdDev = gen.CalculateStandardDeviation(toReturn.Select(x => x.WindSpeedAverage).TakeLast(10)),
          TurbineSpeedStdDev = gen.CalculateStandardDeviation(toReturn.Select(x => x.TurbineSpeedAverage).TakeLast(10)),
          AlterBlades = (gen.CalculateStandardDeviation(toReturn.Select(x => x.TurbineSpeedAverage).TakeLast(10)) - gen.CalculateStandardDeviation(toReturn.Select(x => x.WindSpeedAverage).TakeLast(10))) > 1.0
        });
      }

      return toReturn.OrderBy(a => Guid.NewGuid()).ToList();
    }
  
    public List<RealtimeSensorRecord> GenerateRealTimeSensorRecords(bool stopWake)
    {
      RealtimeWindTurbineRecord windTurbineRecord;
      if (ringBuffer.IsEmpty)
      {
        windTurbineRecord = GenerateFirstRealtimeRecord();
      }
      else
      {
        windTurbineRecord = GenerateRegularRealtimeRecord(stopWake);
      }
      var records = Constants.SensorsList.Select(sensor =>
      {
        double sensorValue = sensor.Type switch
        {
          Constants.Sensors.WindSpeedStdDev => windTurbineRecord.WindSpeedStdDev,
          Constants.Sensors.TurbineSpeedStdDev => windTurbineRecord.TurbineSpeedStdDev,
          Constants.Sensors.OverallWindDirection => windTurbineRecord.OverallWindDirection,
          Constants.Sensors.TurbineWindDirection => windTurbineRecord.TurbineWindDirection,
          Constants.Sensors.WindSpeedAverage => windTurbineRecord.WindSpeedAverage,
          Constants.Sensors.WindTempAverage => windTurbineRecord.WindTempAverage,
          Constants.Sensors.GearboxOilLevel => windTurbineRecord.GearboxOilLevel,
          Constants.Sensors.GearboxOilTemp => windTurbineRecord.GearboxOilTemp,
          Constants.Sensors.GeneratorActivePower => windTurbineRecord.GeneratorActivePower,
          Constants.Sensors.GeneratorSpeed => windTurbineRecord.GeneratorSpeed,
          Constants.Sensors.GeneratorTemp => windTurbineRecord.GeneratorTemp,
          Constants.Sensors.GeneratorTorque => windTurbineRecord.GeneratorTorque,
          Constants.Sensors.GridFrequency => windTurbineRecord.GridFrequency,
          Constants.Sensors.GridVoltage => windTurbineRecord.GridVoltage,
          Constants.Sensors.HydraulicOilPressure => windTurbineRecord.HydraulicOilPressure,
          Constants.Sensors.NacelleAngle => windTurbineRecord.NacelleAngle,
          Constants.Sensors.PitchAngle => windTurbineRecord.PitchAngle,
          Constants.Sensors.Vibration => windTurbineRecord.Vibration,
          Constants.Sensors.TurbineSpeedAverage => windTurbineRecord.TurbineSpeedAverage,
          Constants.Sensors.HatchSensor => 0,
          _ => 0,
        };
        return new RealtimeSensorRecord
        {
          RecordId = Guid.NewGuid(),
          TurbineId = windTurbineRecord.TurbineGuid,
          SensorId = sensor.Id,
          SensorType = sensor.Type,
          SensorValue = sensorValue,
          Timestamp = windTurbineRecord.Timestamp
        };
      });
      return records.ToList();
    }
  }
}
