using System.Collections.Generic;
using SensorModule.Models;

namespace SensorModule.Services.Interfaces
{
  public interface IDataStoreService
  {
    void WriteToDB(RealtimeWindTurbineRecord record);
    bool ModelResponse();
    void TruncateRealtimeWindTurbineRecordTable();
    void SetSqlConnectionString(string sqlConnectionString);
    void DropAndCreateModelTable();
    void InsertModelFromUrl(string url);
    int GetModelResult();
    void TruncateRealtimeSensorRecordTable();
    void WriteSensorRecordsToDB(List<RealtimeSensorRecord> records);
  }
}
