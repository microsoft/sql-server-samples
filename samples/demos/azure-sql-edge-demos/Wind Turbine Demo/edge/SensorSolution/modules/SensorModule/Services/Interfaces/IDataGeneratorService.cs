using System.Collections.Generic;
using SensorModule.Models;

namespace SensorModule.Services.Interfaces
{
  public interface IDataGeneratorService
  {
    IEnumerable<TrainingWindTurbineRecord> GenerateTrainingRecords(int amountOfRecords);

    RealtimeWindTurbineRecord GenerateRealTimeRecords(bool stopWake);
    List<RealtimeSensorRecord> GenerateRealTimeSensorRecords(bool stopWake);

    void ClearBuffer();
  }
}
