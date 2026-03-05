using SensorModule.DataStore;
using SensorModule.Models;
using SensorModule.Services.Interfaces;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using System;
using System.Data;
using System.Net;
using System.Collections.Generic;

namespace SensorModule.Services
{
  public class DataStoreService : IDataStoreService
  {
    private const string STOREDPROCNAME = "ModelResponse";
    private const string RUNMODELSTOREDPROCNAME = "RunModel";
    private const string MODELTABLENAME = "models";
    private const string TRUNCATETABLESTOREDPROCNAME = "TruncateRealtimeWindTurbineRecord";
    private const string TRUNCATEREALTIMESENSORTABLESTOREDPROCNAME = "TruncateRealtimeSensorRecords";
    private string _sqlConnectionString;

    public DataStoreService()
    {
    }

    public void SetSqlConnectionString(string sqlConnectionString)
    {
      _sqlConnectionString = sqlConnectionString;
    }

    public bool ModelResponse()
    {
      SqlParameter[] @params =
      {
         new SqlParameter("@returnVal", SqlDbType.Bit) {Direction = ParameterDirection.Output}
       };

      using (var dbContext = new DatabaseContext(_sqlConnectionString))
      {
        dbContext.Database.ExecuteSqlRaw($"exec @returnVal=" + STOREDPROCNAME, @params);
      }

      return (bool)@params[0].Value;
    }

    public void TruncateRealtimeWindTurbineRecordTable()
    {
      using (var dbContext = new DatabaseContext(_sqlConnectionString))
      {
        dbContext.Database.ExecuteSqlRaw($"exec " + TRUNCATETABLESTOREDPROCNAME);
      }
    }

    public void WriteToDB(RealtimeWindTurbineRecord record)
    {
      using (var db = new DatabaseContext(_sqlConnectionString))
      {
        record.Timestamp = DateTime.Now;
        db.Add(record);
        db.SaveChanges();
      }
    }

    public void DropAndCreateModelTable()
    {
      using var dbContext = new DatabaseContext(_sqlConnectionString);
      dbContext.Database.ExecuteSqlRaw($"drop table if exists {MODELTABLENAME}");
      dbContext.Database.ExecuteSqlRaw($"create table {MODELTABLENAME} ([id] [int] IDENTITY(1,1) NOT NULL, [data] [varbinary](max) NULL, [description] varchar(1000))");
    }

    public void InsertModelFromUrl(string url)
    {
      using var webClient = new WebClient();
      byte[] modelBytes = webClient.DownloadData(url);
      using var dbContext = new DatabaseContext(_sqlConnectionString);
      var query = $"insert into {MODELTABLENAME} ([description], [data]) values ('Onnx Model',?)";
      var model = new OnnxModel { Description = "Onnx Model", Data = modelBytes };
      dbContext.Add<OnnxModel>(model);
      dbContext.SaveChanges();
    }

    public int GetModelResult()
    {
      SqlParameter[] @params =
      {
        new SqlParameter("@Result", SqlDbType.Int) {Direction = ParameterDirection.Output}
      };

      using (var dbContext = new DatabaseContext(_sqlConnectionString))
      {
        dbContext.Database.ExecuteSqlRaw($"EXEC " + RUNMODELSTOREDPROCNAME + " @Result OUTPUT", @params);
      }

      return (int)@params[0].Value;
    }

    public void TruncateRealtimeSensorRecordTable()
    {
      using (var dbContext = new DatabaseContext(_sqlConnectionString))
      {
        dbContext.Database.ExecuteSqlRaw($"exec " + TRUNCATEREALTIMESENSORTABLESTOREDPROCNAME);
      }
    }

    public void WriteSensorRecordsToDB(List<RealtimeSensorRecord> records)
    {
      using (var dbContext = new DatabaseContext(_sqlConnectionString))
      {
        records.ForEach(record =>
        {
          dbContext.Add(record);
        });
        dbContext.SaveChanges();
      }
    }
  }
}
