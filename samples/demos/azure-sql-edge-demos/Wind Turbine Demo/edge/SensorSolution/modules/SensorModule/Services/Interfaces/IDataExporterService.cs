using SensorModule.Models;
using System.Collections.Generic;

namespace SensorModule.Services.Interfaces
{
  public interface IDataExporterService
  {
    void SaveParquet(IEnumerable<TrainingWindTurbineRecord> records, string outputFile);
  }
}
